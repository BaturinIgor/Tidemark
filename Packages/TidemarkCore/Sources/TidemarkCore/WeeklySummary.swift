import Foundation

public struct WeeklySummary: Equatable, Sendable {
    public let weekEnding: DayKey
    public let checkInCount: Int
    public let episodeCount: Int
    public let previousEpisodeCount: Int
    public let averageBurden: Double?
    public let previousAverageBurden: Double?
    public let hardestDay: DayKey?
    public let easiestDay: DayKey?
}

public enum WeeklySummaryBuilder {
    public static func build(
        weekEnding: DayKey,
        checkIns: [CheckIn],
        episodes: [Episode],
        timeZone: TimeZone = .current
    ) -> WeeklySummary {
        let thisWeek = weekEnding.adding(days: -6)...weekEnding
        let lastWeek = weekEnding.adding(days: -13)...weekEnding.adding(days: -7)

        let current = checkIns.filter { thisWeek.contains($0.day) }
        let previous = checkIns.filter { lastWeek.contains($0.day) }

        func average(_ items: [CheckIn]) -> Double? {
            items.isEmpty ? nil : Double(items.map(\.burden).reduce(0, +)) / Double(items.count)
        }
        func count(_ range: ClosedRange<DayKey>) -> Int {
            episodes.filter { range.contains(DayKey($0.at, in: timeZone)) }.count
        }

        return WeeklySummary(
            weekEnding: weekEnding,
            checkInCount: current.count,
            episodeCount: count(thisWeek),
            previousEpisodeCount: count(lastWeek),
            averageBurden: average(current),
            previousAverageBurden: average(previous),
            hardestDay: current.max(by: { $0.burden < $1.burden })?.day,
            easiestDay: current.min(by: { $0.burden < $1.burden })?.day
        )
    }
}
