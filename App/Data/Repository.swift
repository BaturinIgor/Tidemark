import CoreData
import Foundation
import TidemarkCore
#if canImport(UIKit)
import UIKit
#endif

/// Reads and writes domain values. Views never touch managed objects directly.
///
/// Every field of a day is its own row or attribute, stamped with `updatedAt` and the device,
/// so offline edits from two devices merge per field (D8).
@MainActor
final class Repository {
    private let context: NSManagedObjectContext
    private let deviceID: String

    init(context: NSManagedObjectContext) {
        self.context = context
        #if canImport(UIKit)
        deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        #else
        deviceID = "unknown"
        #endif
    }

    // MARK: Profile

    func profile() -> Profile? {
        let request = CDProfile.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        guard let row = try? context.fetch(request).first,
              let region = row.region.flatMap(Region.init(rawValue:)) else { return nil }
        return Profile(
            region: region,
            age: row.age > 0 ? Int(row.age) : nil,
            trackedSymptomIDs: (row.trackedSymptoms ?? "").split(separator: ",").map(String.init)
        )
    }

    func save(profile: Profile) {
        let request = CDProfile.fetchRequest()
        let row = (try? context.fetch(request).first) ?? CDProfile(context: context)
        if row.id == nil { row.id = UUID() }
        row.region = profile.region.rawValue
        row.age = Int16(profile.age ?? 0)
        row.trackedSymptoms = profile.trackedSymptomIDs.joined(separator: ",")
        row.updatedAt = Date()
        commit()
    }

    // MARK: Check-ins

    func checkIn(for day: DayKey) -> CheckIn? {
        allCheckIns(from: day, to: day).first
    }

    func allCheckIns(from: DayKey? = nil, to: DayKey? = nil) -> [CheckIn] {
        let dayRequest = CDDay.fetchRequest()
        dayRequest.predicate = NSPredicate(format: "deletedAt == nil")
        let ratingRequest = CDRating.fetchRequest()
        ratingRequest.predicate = NSPredicate(format: "deletedAt == nil")

        let days = (try? context.fetch(dayRequest)) ?? []
        let ratings = (try? context.fetch(ratingRequest)) ?? []
        let ratingsByDay = Dictionary(grouping: ratings, by: { $0.day ?? "" })

        return days.compactMap { row -> CheckIn? in
            guard let raw = row.day, let key = DayKey(string: raw) else { return nil }
            if let from, key < from { return nil }
            if let to, key > to { return nil }
            var values: [String: Severity] = [:]
            // Duplicate rows from two devices: newest wins, the same rule as FieldMerge.
            let grouped = Dictionary(grouping: ratingsByDay[raw] ?? [], by: { $0.symptomID ?? "" })
            for (symptom, rows) in grouped {
                let stamped = rows.map { Stamped(Int($0.level), updatedAt: $0.updatedAt ?? .distantPast, deviceID: $0.deviceID ?? "") }
                if let best = FieldMerge.winner(stamped), let severity = Severity(rawValue: best.value) {
                    values[symptom] = severity
                }
            }
            return CheckIn(
                day: key,
                ratings: values,
                impact: row.impact >= 0 ? DailyImpact(rawValue: Int(row.impact)) : nil,
                bleeding: Bleeding(rawValue: Int(row.bleeding)) ?? .none,
                factors: Set((row.factors ?? "").split(separator: ",").compactMap { Factor(rawValue: String($0)) }),
                note: row.note ?? ""
            )
        }
        .sorted { $0.day < $1.day }
    }

    /// D1: called on every tap, so a half-finished check-in survives the app being killed.
    func save(checkIn: CheckIn) {
        let raw = checkIn.day.description
        let now = Date()

        let dayRequest = CDDay.fetchRequest()
        dayRequest.predicate = NSPredicate(format: "day == %@", raw)
        let day = (try? context.fetch(dayRequest).first) ?? CDDay(context: context)
        if day.id == nil { day.id = UUID(); day.day = raw }
        let impact = Int16(checkIn.impact?.rawValue ?? -1)
        let factors = checkIn.factors.map(\.rawValue).sorted().joined(separator: ",")
        if day.impact != impact || day.bleeding != Int16(checkIn.bleeding.rawValue) || day.factors != factors || day.note != checkIn.note || day.deletedAt != nil {
            day.impact = impact
            day.bleeding = Int16(checkIn.bleeding.rawValue)
            day.factors = factors
            day.note = checkIn.note
            day.deletedAt = nil
            day.updatedAt = now
            day.deviceID = deviceID
        }

        let ratingRequest = CDRating.fetchRequest()
        ratingRequest.predicate = NSPredicate(format: "day == %@", raw)
        let existing = Dictionary(grouping: (try? context.fetch(ratingRequest)) ?? [], by: { $0.symptomID ?? "" })
        for (symptom, severity) in checkIn.ratings {
            let row = existing[symptom]?.first ?? {
                let created = CDRating(context: context)
                created.id = UUID()
                created.day = raw
                created.symptomID = symptom
                return created
            }()
            if row.level != Int16(severity.rawValue) || row.updatedAt == nil || row.deletedAt != nil {
                row.level = Int16(severity.rawValue)
                row.deletedAt = nil
                row.updatedAt = now
                row.deviceID = deviceID
            }
        }
        commit()
    }

    /// D7: soft delete. The day stays in Recently deleted for 30 days.
    func delete(day: DayKey) {
        let now = Date()
        let raw = day.description
        for request in ["CDDay", "CDRating"].map({ NSFetchRequest<NSManagedObject>(entityName: $0) }) {
            request.predicate = NSPredicate(format: "day == %@", raw)
            for row in (try? context.fetch(request)) ?? [] {
                row.setValue(now, forKey: "deletedAt")
                row.setValue(now, forKey: "updatedAt")
            }
        }
        commit()
    }

    func restore(day: DayKey) {
        let raw = day.description
        for request in ["CDDay", "CDRating"].map({ NSFetchRequest<NSManagedObject>(entityName: $0) }) {
            request.predicate = NSPredicate(format: "day == %@", raw)
            for row in (try? context.fetch(request)) ?? [] {
                row.setValue(nil, forKey: "deletedAt")
                row.setValue(Date(), forKey: "updatedAt")
            }
        }
        commit()
    }

    func recentlyDeletedDays(now: Date = Date()) -> [(day: DayKey, daysLeft: Int)] {
        let request = CDDay.fetchRequest()
        request.predicate = NSPredicate(format: "deletedAt != nil")
        return ((try? context.fetch(request)) ?? []).compactMap { row -> (day: DayKey, daysLeft: Int)? in
            guard let raw = row.day, let key = DayKey(string: raw), let deleted = row.deletedAt,
                  !RecentlyDeleted.isExpired(deletedAt: deleted, now: now) else { return nil }
            return (day: key, daysLeft: RecentlyDeleted.daysLeft(deletedAt: deleted, now: now))
        }
        .sorted { $0.day > $1.day }
    }

    // MARK: Episodes, medicines, questionnaires

    func episodes() -> [Episode] {
        let request = CDEpisode.fetchRequest()
        request.predicate = NSPredicate(format: "deletedAt == nil")
        return ((try? context.fetch(request)) ?? []).compactMap { row in
            guard let id = row.id, let kind = row.kind.flatMap(Episode.Kind.init(rawValue:)), let at = row.at else { return nil }
            return Episode(id: id, kind: kind, at: at,
                           intensity: Severity(rawValue: Int(row.intensity)) ?? .moderate,
                           source: row.source.flatMap(Episode.Source.init(rawValue:)) ?? .app)
        }
    }

    func logEpisode(_ kind: Episode.Kind, intensity: Severity) {
        try? EpisodeLogger.log(kind, intensity: intensity, source: .app, in: context)
    }

    func medications() -> [Medication] {
        let request = CDMedication.fetchRequest()
        request.predicate = NSPredicate(format: "deletedAt == nil")
        return ((try? context.fetch(request)) ?? []).compactMap { row in
            guard let id = row.id, let name = row.name,
                  let started = row.started.flatMap(DayKey.init(string:)) else { return nil }
            return Medication(id: id, name: name,
                              kind: row.kind.flatMap(Medication.Kind.init(rawValue:)) ?? .prescribed,
                              howTaken: row.howTaken ?? "", started: started,
                              stopped: row.stopped.flatMap(DayKey.init(string:)))
        }
    }

    func save(medication: Medication) {
        let request = CDMedication.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", medication.id as CVarArg)
        let row = (try? context.fetch(request).first) ?? CDMedication(context: context)
        row.id = medication.id
        row.name = medication.name
        row.kind = medication.kind.rawValue
        row.howTaken = medication.howTaken
        row.started = medication.started.description
        row.stopped = medication.stopped?.description
        row.updatedAt = Date()
        commit()
    }

    func questionnaires() -> [Questionnaire] {
        let request = CDQuestionnaire.fetchRequest()
        request.predicate = NSPredicate(format: "deletedAt == nil")
        return ((try? context.fetch(request)) ?? []).compactMap { row in
            guard let day = row.day.flatMap(DayKey.init(string:)) else { return nil }
            let answers = (row.answers ?? "").split(separator: ",").compactMap { Int($0) }
            return Questionnaire(day: day, answers: answers)
        }
        .sorted { $0.day < $1.day }
    }

    func save(questionnaire: Questionnaire) {
        let row = CDQuestionnaire(context: context)
        row.id = UUID()
        row.day = questionnaire.day.description
        row.answers = questionnaire.answers.map(String.init).joined(separator: ",")
        row.updatedAt = Date()
        commit()
    }

    // MARK: Export and import (D5)

    func exportFile(appVersion: String) -> ExportFile? {
        guard let profile = profile() else { return nil }
        return ExportFile(
            exportedAt: Date(), appVersion: appVersion, profile: profile,
            checkIns: allCheckIns(), episodes: episodes(),
            questionnaires: questionnaires(), medications: medications()
        )
    }

    /// Adds what is missing and never overwrites a newer local value.
    func importFile(_ file: ExportFile) {
        if profile() == nil { save(profile: file.profile) }
        for checkIn in file.checkIns where self.checkIn(for: checkIn.day) == nil {
            save(checkIn: checkIn)
        }
        let known = Set(medications().map(\.id))
        for medication in file.medications where !known.contains(medication.id) {
            save(medication: medication)
        }
        let knownDays = Set(questionnaires().map(\.day))
        for questionnaire in file.questionnaires where !knownDays.contains(questionnaire.day) {
            save(questionnaire: questionnaire)
        }
        let knownEpisodes = Set(episodes().map(\.id))
        for episode in file.episodes where !knownEpisodes.contains(episode.id) {
            let row = CDEpisode(context: context)
            row.id = episode.id
            row.kind = episode.kind.rawValue
            row.at = episode.at
            row.intensity = Int16(episode.intensity.rawValue)
            row.source = episode.source.rawValue
            row.updatedAt = Date()
        }
        commit()
    }

    private func commit() {
        guard context.hasChanges else { return }
        do { try context.save() } catch {
            // Keep the unsaved changes in memory; the next tap retries. Never roll back user input.
            assertionFailure("Save failed: \(error)")
        }
    }
}
