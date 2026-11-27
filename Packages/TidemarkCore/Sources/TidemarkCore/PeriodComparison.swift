import Foundation

/// "Since your last visit" (Pro): the user's own numbers in two equal periods either side of a date she
/// picks, usually her last appointment. It only describes what she logged. It never says better or worse,
/// and never links a change to a cause.
public struct PeriodComparison: Equatable, Sendable {
    public struct Side: Equatable, Sendable {
        public let from: DayKey
        public let to: DayKey
        public let daysLogged: Int
        public let hardImpactDays: Int
        public let quickLogs: Int
        public let bleedingDays: Int
        /// Latest complete questionnaire total in the period.
        public let questionnaire: Int?
    }

    public struct Row: Equatable, Sendable {
        public let symptomID: String
        /// Mean rating 0–3 on the days it was rated; nil when never rated in the period.
        public let before: Double?
        public let after: Double?
        /// Days rated mild or worse.
        public let daysPresentBefore: Int
        public let daysPresentAfter: Int
    }

    public static let maximumDays = 84
    /// Each side needs this many check-ins before the page is offered, so a few days are never compared.
    public static let minimumCheckInsPerSide = 7

    public let split: DayKey
    public let before: Side
    public let after: Side
    public let rows: [Row]

    public var isReady: Bool {
        before.daysLogged >= Self.minimumCheckInsPerSide && after.daysLogged >= Self.minimumCheckInsPerSide
    }

    /// The "after" period runs from `split` to `today` (at most `maximumDays`); "before" is the same
    /// number of days just before `split`. Nil when `split` is after `today`.
    public static func build(
        split: DayKey,
        today: DayKey,
        symptomIDs: [String],
        checkIns: [CheckIn],
        episodes: [Episode],
        questionnaires: [Questionnaire],
        timeZone: TimeZone = .current
    ) -> PeriodComparison? {
        guard split <= today else { return nil }
        let length = min(split.days(until: today) + 1, maximumDays)
        let afterRange = split...split.adding(days: length - 1)
        let beforeRange = split.adding(days: -length)...split.adding(days: -1)

        func side(_ range: ClosedRange<DayKey>) -> Side {
            let days = checkIns.filter { range.contains($0.day) }
            return Side(
                from: range.lowerBound, to: range.upperBound,
                daysLogged: days.count,
                hardImpactDays: days.filter { ($0.impact?.rawValue ?? 0) >= DailyImpact.quiteABit.rawValue }.count,
                quickLogs: episodes.filter { range.contains(DayKey($0.at, in: timeZone)) }.count,
                bleedingDays: days.filter { $0.bleeding != .none }.count,
                questionnaire: questionnaires.filter { range.contains($0.day) && $0.total != nil }
                    .max(by: { $0.day < $1.day })?.total
            )
        }

        func stats(_ range: ClosedRange<DayKey>, _ id: String) -> (Double?, Int) {
            let values = checkIns.filter { range.contains($0.day) }.compactMap { $0.ratings[id]?.rawValue }
            guard !values.isEmpty else { return (nil, 0) }
            return (Double(values.reduce(0, +)) / Double(values.count), values.filter { $0 > 0 }.count)
        }

        let rows = symptomIDs.map { id -> Row in
            let (b, bd) = stats(beforeRange, id)
            let (a, ad) = stats(afterRange, id)
            return Row(symptomID: id, before: b, after: a, daysPresentBefore: bd, daysPresentAfter: ad)
        }
        return PeriodComparison(split: split, before: side(beforeRange), after: side(afterRange), rows: rows)
    }

    /// The default split: the latest appointment before today, otherwise four weeks ago.
    public static func defaultSplit(visits: [Visit], today: DayKey) -> DayKey {
        visits.map(\.day).filter { $0 < today }.max() ?? today.adding(days: -28)
    }
}
