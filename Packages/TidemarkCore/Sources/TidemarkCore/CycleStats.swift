import Foundation

/// A run of consecutive days with real flow. Spotting alone never starts a period.
public struct Period: Equatable, Sendable {
    public let start: DayKey
    public let end: DayKey
    public var lengthInDays: Int { start.days(until: end) + 1 }
}

public struct CycleSummary: Equatable, Sendable {
    public let periods: [Period]
    /// Days from one period start to the next.
    public let cycleLengths: [Int]
    public let spottingDays: Int

    public var shortestCycle: Int? { cycleLengths.min() }
    public var longestCycle: Int? { cycleLengths.max() }
    /// Longest minus shortest. Doctors read a spread of 7+ days as a change worth discussing; we only show the number.
    public var spread: Int? {
        guard let low = shortestCycle, let high = longestCycle else { return nil }
        return high - low
    }
    public var lastPeriodStart: DayKey? { periods.last?.start }
}

public enum CycleStats {
    /// Gap of dry days that still counts as the same period (light day, dry day, light day).
    public static let allowedGapDays = 1

    public static func summary(of bleeding: [DayKey: Bleeding]) -> CycleSummary {
        let flowDays = bleeding.filter { $0.value.countsAsPeriod }.keys.sorted()
        var periods: [Period] = []
        var start: DayKey?
        var last: DayKey?
        for day in flowDays {
            if let previous = last, previous.days(until: day) <= allowedGapDays + 1 {
                last = day
                continue
            }
            if let s = start, let e = last { periods.append(Period(start: s, end: e)) }
            start = day
            last = day
        }
        if let s = start, let e = last { periods.append(Period(start: s, end: e)) }

        let lengths = zip(periods, periods.dropFirst()).map { $0.start.days(until: $1.start) }
        let spotting = bleeding.values.filter { $0 == .spotting }.count
        return CycleSummary(periods: periods, cycleLengths: lengths, spottingDays: spotting)
    }

    /// Days since the last period started. Used for the "12 months without a period" bleeding warning.
    public static func daysSinceLastPeriod(_ summary: CycleSummary, today: DayKey) -> Int? {
        summary.lastPeriodStart.map { $0.days(until: today) }
    }
}
