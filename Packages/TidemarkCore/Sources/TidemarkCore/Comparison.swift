import Foundation

/// Compares today's rating with the user's own recent days. Words only describe, never judge.
public enum Trend: String, Sendable, Equatable {
    case higherThanUsual = "higher than usual"
    case aboutTheSame = "about the same"
    case lowerThanUsual = "lower than usual"
}

public enum Comparison {
    /// Compares `today` with the mean of the previous `windowDays` check-ins that rated the symptom.
    /// Returns nil when there are fewer than `minimumDays` earlier ratings, so we never compare against noise.
    public static func trend(
        symptomID: String,
        today: CheckIn,
        history: [CheckIn],
        windowDays: Int = 14,
        minimumDays: Int = 5,
        threshold: Double = 0.75
    ) -> Trend? {
        guard let current = today.ratings[symptomID] else { return nil }
        let start = today.day.adding(days: -windowDays)
        let earlier = history
            .filter { $0.day < today.day && $0.day >= start }
            .compactMap { $0.ratings[symptomID]?.rawValue }
        guard earlier.count >= minimumDays else { return nil }
        let mean = Double(earlier.reduce(0, +)) / Double(earlier.count)
        let delta = Double(current.rawValue) - mean
        if delta >= threshold { return .higherThanUsual }
        if delta <= -threshold { return .lowerThanUsual }
        return .aboutTheSame
    }
}
