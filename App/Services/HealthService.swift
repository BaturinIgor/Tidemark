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
        "waking_at_night": .sleepChanges,
        "fatigue": .fatigue,
        "low_mood": .moodChanges,
        "headaches": .headache,
        "palpitations": .rapidPoundingOrFlutteringHeartbeat,
        "vaginal_dryness": .vaginalDryness,
        "breast_tenderness": .breastPain,
        "dry_skin": .drySkin,
        "hair_thinning": .hairLoss,
        "dizziness": .dizziness,
        "joint_aches": .generalizedBodyAche,
        "brain_fog": .memoryLapse,
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
        let samples: [HKCategorySample] = checkIn.ratings.compactMap { id, severity in
            guard let identifier = Self.symptomTypes[id] else { return nil }
            let value: HKCategoryValueSeverity = switch severity {
            case .none: .notPresent
            case .mild: .mild
            case .moderate: .moderate
            case .severe: .severe
            }
            return HKCategorySample(type: HKCategoryType(identifier), value: value.rawValue, start: start, end: end)
        }
        guard !samples.isEmpty else { return }
        try? await store.save(samples)
    }
}
