import Foundation

/// Describes how often a symptom was moderate or worse on days with and without a factor.
///
/// This is a count, not a claim of cause. The UI must show it as
/// "on 6 of 8 days with alcohol, night sweats were moderate or worse; on other days, 9 of 40".
public struct Pattern: Hashable, Sendable {
    public let factor: Factor
    public let symptomID: String
    /// `nextDay` means the factor was logged the day before the symptom (alcohol in the evening, sweats that night).
    public let nextDay: Bool
    public let withFactorHits: Int
    public let withFactorDays: Int
    public let withoutFactorHits: Int
    public let withoutFactorDays: Int

    public var withRate: Double { withFactorDays == 0 ? 0 : Double(withFactorHits) / Double(withFactorDays) }
    public var withoutRate: Double { withoutFactorDays == 0 ? 0 : Double(withoutFactorHits) / Double(withoutFactorDays) }
    public var difference: Double { withRate - withoutRate }
}

public enum PatternFinder {
    /// Days with the factor needed before a pattern is shown.
    public static let minimumFactorDays = 5
    /// Smallest gap between the two rates worth showing.
    public static let minimumDifference = 0.25

    public static func patterns(in checkIns: [CheckIn], symptomIDs: [String]) -> [Pattern] {
        let byDay = Dictionary(checkIns.map { ($0.day, $0) }, uniquingKeysWith: { _, last in last })
        var found: [Pattern] = []
        for factor in Factor.allCases {
            for symptomID in symptomIDs {
                for nextDay in [false, true] {
                    var withHits = 0, withDays = 0, withoutHits = 0, withoutDays = 0
                    for checkIn in checkIns {
                        guard let rating = checkIn.ratings[symptomID] else { continue }
                        let sourceDay = nextDay ? checkIn.day.adding(days: -1) : checkIn.day
                        guard let source = byDay[sourceDay] else { continue }
                        let hit = rating >= .moderate
                        if source.factors.contains(factor) {
                            withDays += 1
                            if hit { withHits += 1 }
                        } else {
                            withoutDays += 1
                            if hit { withoutHits += 1 }
                        }
                    }
                    let pattern = Pattern(
                        factor: factor, symptomID: symptomID, nextDay: nextDay,
                        withFactorHits: withHits, withFactorDays: withDays,
                        withoutFactorHits: withoutHits, withoutFactorDays: withoutDays
                    )
                    if withDays >= minimumFactorDays, withoutDays >= minimumFactorDays,
                       abs(pattern.difference) >= minimumDifference {
                        found.append(pattern)
                    }
                }
            }
        }
        // Keep the strongest of same-day and next-day for each pair, strongest first.
        let best = Dictionary(grouping: found, by: { "\($0.factor.rawValue)|\($0.symptomID)" })
            .compactMap { $0.value.max(by: { abs($0.difference) < abs($1.difference) }) }
        return best.sorted { abs($0.difference) > abs($1.difference) }
    }
}
