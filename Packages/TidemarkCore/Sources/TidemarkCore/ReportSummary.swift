import Foundation

/// The numbers on the one-page visit report. Everything here describes what the user logged.
public struct ReportSummary: Equatable, Sendable {
    public struct SymptomRow: Equatable, Sendable {
        public let symptomID: String
        /// Days rated mild or worse.
        public let days: Int
        /// Mean rating on days it was rated, 0–3.
        public let average: Double
        /// Last 4 weeks compared with the 4 weeks before.
        public let trend: Trend?
    }

    public let from: DayKey
    public let to: DayKey
    public let daysInRange: Int
    public let daysLogged: Int
    public let symptoms: [SymptomRow]
    public let hardImpactDays: Int
    public let episodes: Int
    public let questionnaires: [Questionnaire]
    public let cycle: CycleSummary
    public let heavyBleedingDays: Int

    public static func build(
        from: DayKey,
        to: DayKey,
        trackedSymptomIDs: [String],
        checkIns: [CheckIn],
        episodes: [Episode],
        questionnaires: [Questionnaire],
        timeZone: TimeZone = .current
    ) -> ReportSummary {
        let inRange = checkIns.filter { $0.day >= from && $0.day <= to }
        let split = to.adding(days: -27)
        let rows = trackedSymptomIDs.map { id -> SymptomRow in
            let rated = inRange.compactMap { c in c.ratings[id].map { (c.day, $0.rawValue) } }
            let present = rated.filter { $0.1 > 0 }
            let average = rated.isEmpty ? 0 : Double(rated.map(\.1).reduce(0, +)) / Double(rated.count)
            let recent = rated.filter { $0.0 >= split }.map(\.1)
            let earlier = rated.filter { $0.0 < split && $0.0 >= split.adding(days: -28) }.map(\.1)
            var trend: Trend?
            if recent.count >= 7, earlier.count >= 7 {
                let delta = Double(recent.reduce(0, +)) / Double(recent.count) - Double(earlier.reduce(0, +)) / Double(earlier.count)
                trend = delta >= 0.3 ? .higherThanUsual : delta <= -0.3 ? .lowerThanUsual : .aboutTheSame
            }
            return SymptomRow(symptomID: id, days: present.count, average: average, trend: trend)
        }
        .sorted { ($0.days, $0.average) > ($1.days, $1.average) }

        let bleeding = Dictionary(checkIns.map { ($0.day, $0.bleeding) }, uniquingKeysWith: { _, last in last })
        return ReportSummary(
            from: from,
            to: to,
            daysInRange: from.days(until: to) + 1,
            daysLogged: inRange.count,
            symptoms: rows,
            hardImpactDays: inRange.filter { ($0.impact?.rawValue ?? 0) >= DailyImpact.quiteABit.rawValue }.count,
            episodes: episodes.filter { let d = DayKey($0.at, in: timeZone); return d >= from && d <= to }.count,
            questionnaires: questionnaires.filter { $0.day >= from && $0.day <= to && $0.total != nil }.sorted { $0.day < $1.day },
            cycle: CycleStats.summary(of: bleeding),
            heavyBleedingDays: inRange.filter { $0.bleeding == .heavy }.count
        )
    }
}
