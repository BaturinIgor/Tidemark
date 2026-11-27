import CoreData
import Testing
import TidemarkCore
@testable import Tidemark

/// Data safety scenarios that need the real Core Data model (D1, D5, D7).
@MainActor
@Suite("Repository")
struct RepositoryTests {
    let day = DayKey(year: 2026, month: 11, day: 18)

    private func makeRepository() -> Repository {
        Repository(context: PersistenceController(mode: .inMemory).container.viewContext)
    }

    @Test("D1: every save is readable straight away")
    func saveAndRead() {
        let repo = makeRepository()
        repo.save(checkIn: CheckIn(day: day, ratings: ["fatigue": .moderate], bleeding: .spotting, factors: [.stress], note: "Long day"))
        let read = repo.checkIn(for: day)
        #expect(read?.ratings["fatigue"] == .moderate)
        #expect(read?.bleeding == .spotting)
        #expect(read?.factors == [.stress])
        #expect(read?.note == "Long day")
    }

    @Test("Editing a day updates it instead of adding a second one")
    func editInPlace() {
        let repo = makeRepository()
        repo.save(checkIn: CheckIn(day: day, ratings: ["fatigue": .mild]))
        repo.save(checkIn: CheckIn(day: day, ratings: ["fatigue": .severe, "brain_fog": .mild]))
        #expect(repo.allCheckIns().count == 1)
        #expect(repo.checkIn(for: day)?.ratings == ["fatigue": .severe, "brain_fog": .mild])
    }

    @Test("D7: a deleted day can be restored")
    func deleteAndRestore() {
        let repo = makeRepository()
        repo.save(checkIn: CheckIn(day: day, ratings: ["fatigue": .mild]))
        repo.delete(day: day)
        #expect(repo.checkIn(for: day) == nil)
        #expect(repo.recentlyDeletedDays().first?.daysLeft == 30)
        repo.restore(day: day)
        #expect(repo.checkIn(for: day)?.ratings["fatigue"] == .mild)
    }

    @Test("D5: export from one store and import into an empty one gives the same data")
    func exportImport() throws {
        let source = makeRepository()
        source.save(profile: Profile(region: .unitedStates, age: 48, trackedSymptomIDs: ["fatigue"]))
        source.save(checkIn: CheckIn(day: day, ratings: ["fatigue": .moderate], impact: .aLittle))
        source.save(medication: Medication(name: "Vitamin D", kind: .supplement, howTaken: "Daily", started: day))
        let file = try #require(source.exportFile(appVersion: "test"))
        let data = try ExportCodec.encode(file)

        let target = makeRepository()
        target.importFile(try ExportCodec.decode(data))
        #expect(target.allCheckIns() == source.allCheckIns())
        #expect(target.medications() == source.medications())
        #expect(target.profile() == source.profile())
    }

    @Test("D7: delete all is a soft delete that can be undone")
    func deleteAllAndRestore() {
        let repo = makeRepository()
        repo.save(profile: Profile(region: .unitedKingdom, age: 49, trackedSymptomIDs: ["fatigue"]))
        repo.save(checkIn: CheckIn(day: day, ratings: ["fatigue": .mild]))
        repo.save(checkIn: CheckIn(day: day.adding(days: -1), ratings: ["fatigue": .severe]))
        repo.delete(day: day.adding(days: -1))
        repo.save(question: DoctorQuestion(text: "Is HRT an option for me?", rank: 0))
        repo.save(visit: Visit(day: day.adding(days: 10), clinician: "Dr Shah"))
        repo.logEpisode(.hotFlush, intensity: .moderate)

        let stamp = repo.deleteAll()
        #expect(repo.allCheckIns().isEmpty)
        #expect(repo.questions().isEmpty)
        #expect(repo.visits().isEmpty)
        #expect(repo.episodes().isEmpty)
        #expect(repo.profile() != nil)

        repo.restoreAll(deletedAt: stamp)
        #expect(repo.allCheckIns().map(\.day) == [day])
        #expect(repo.questions().count == 1)
        #expect(repo.visits().first?.clinician == "Dr Shah")
        #expect(repo.episodes().count == 1)
        // The day deleted on its own before stays in Recently deleted.
        #expect(repo.recentlyDeletedDays().map(\.day) == [day.adding(days: -1)])
    }

    @Test("Visit fields survive a save and read")
    func visitRoundTrip() {
        let repo = makeRepository()
        let visit = Visit(day: day, clinician: "Dr Shah", reason: "Sleep", takenSeriously: .partly,
                          decisions: [.bloodTests, .comeBackLater], outcome: "Bloods next week", followUp: day.adding(days: 28))
        repo.save(visit: visit)
        #expect(repo.visits() == [visit])
    }

    @Test("Own symptoms survive a save and read, and a rated own symptom keeps its name")
    func customSymptomsRoundTrip() {
        let repo = makeRepository()
        let own = CustomSymptom(name: "Tingling hands")
        repo.save(profile: Profile(region: .unitedKingdom, age: 50, trackedSymptomIDs: ["fatigue", own.id], customSymptoms: [own]))
        repo.save(checkIn: CheckIn(day: day, ratings: [own.id: .mild]))
        #expect(repo.profile()?.customSymptoms == [own])
        #expect(repo.checkIn(for: day)?.ratings[own.id] == .mild)
    }

    @Test("D6: a store made by the 1.0 model (version 1) opens with the current model and keeps its rows")
    func lightweightMigrationFromVersion1() throws {
        let bundle = Bundle(for: PersistenceController.self)
        let momd = try #require(bundle.url(forResource: "Tidemark", withExtension: "momd"))
        let v1 = try #require(NSManagedObjectModel(contentsOf: momd.appendingPathComponent("Tidemark.mom")))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("migration-\(UUID().uuidString).sqlite")
        defer { for s in ["", "-wal", "-shm"] { try? FileManager.default.removeItem(atPath: url.path + s) } }

        // Write a day with the old model.
        let old = NSPersistentContainer(name: "Tidemark", managedObjectModel: v1)
        old.persistentStoreDescriptions = [NSPersistentStoreDescription(url: url)]
        old.loadPersistentStores { _, error in #expect(error == nil) }
        let row = NSEntityDescription.insertNewObject(forEntityName: "CDDay", into: old.viewContext)
        row.setValue(day.description, forKey: "day")
        row.setValue("Before the update", forKey: "note")
        row.setValue(UUID(), forKey: "id")
        try old.viewContext.save()
        for store in old.persistentStoreCoordinator.persistentStores { try old.persistentStoreCoordinator.remove(store) }

        // Open it with the current model, the way the app does.
        let new = NSPersistentContainer(name: "Tidemark", managedObjectModel: PersistenceController.model)
        let description = NSPersistentStoreDescription(url: url)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        new.persistentStoreDescriptions = [description]
        var loadError: Error?
        new.loadPersistentStores { _, error in loadError = error }
        #expect(loadError == nil)
        let rows = try new.viewContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "CDDay"))
        #expect(rows.count == 1)
        #expect(rows.first?.value(forKey: "note") as? String == "Before the update")
    }
}
