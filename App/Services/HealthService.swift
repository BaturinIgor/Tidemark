import Foundation
import HealthKit
import TidemarkCore

/// Apple Health: read sleep and cycle, write symptoms. Each side is a separate permission the user can refuse.
@MainActor
final class HealthService {
    private let store = HKHealthStore()

    static let symptomTypes: [String: HKCategoryTypeIdentifier] = [
        "hot_flushes": .hotFlashes,
        "night_sweats": .nightSweats,
        "trouble_falling_asleep": .sleepChanges,
        "waking_at_night": .sleepChanges,
        "fatigue": .fatigue,
        "low_mood": .moodChanges,
        "irritability": .moodChanges,
        "anxiety": .moodChanges,
        "brain_fog": .memoryLapse,
        "forgetting_words": .memoryLapse,
        "headaches": .headache,
        "palpitations": .rapidPoundingOrFlutteringHeartbeat,
        "joint_aches": .generalizedBodyAche,
        "dry_skin": .drySkin,
        "vaginal_dryness": .vaginalDryness,
    ]

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAccess(write: Bool) async -> Bool {
        guard isAvailable else { return false }
        let read: Set<HKObjectType> = [
            HKCategoryType(.sleepAnalysis),
            HKCategoryType(.menstrualFlow),
        ]
        let share: Set<HKSampleType> = write ? Set(Self.symptomTypes.values.map { HKCategoryType($0) }) : []
        do {
            try await store.requestAuthorization(toShare: share, read: read)
            return true
        } catch {
            return false
        }
    }

    /// Writes one day's ratings. Health uses its own severity scale; "none" is written as notPresent.
    func write(_ checkIn: CheckIn) async {
        let start = checkIn.day.referenceDate.addingTimeInterval(-12 * 3_600)
        let end = start.addingTimeInterval(86_399)
        // Several of our symptoms map to one Health type (for example two sleep symptoms); write the worst.
        var worst: [HKCategoryTypeIdentifier: Severity] = [:]
        for (id, severity) in checkIn.ratings {
            guard let identifier = Self.symptomTypes[id] else { continue }
            worst[identifier] = max(worst[identifier] ?? Severity.none, severity)
        }
        let samples: [HKCategorySample] = worst.map { identifier, severity in
            let value: HKCategoryValueSeverity = switch severity {
            case .none: .notPresent
            case .mild: .mild
            case .moderate: .moderate
            case .severe: .severe
            }
            return HKCategorySample(type: HKCategoryType(identifier), value: value.rawValue, start: start, end: end)
        }
        guard !samples.isEmpty else { return }
        // Editing a day replaces what this app wrote for it, so Health does not show the day twice.
        let ours = HKQuery.predicateForObjects(from: .default())
        let sameDay = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [ours, sameDay])
        for identifier in worst.keys {
            _ = try? await store.deleteObjects(of: HKCategoryType(identifier), predicate: predicate)
        }
        try? await store.save(samples)
    }
}
