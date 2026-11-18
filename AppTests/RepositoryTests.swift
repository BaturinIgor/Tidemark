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
}
