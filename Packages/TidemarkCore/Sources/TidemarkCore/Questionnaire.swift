import Foundation

/// The 11 items of the fortnightly questionnaire, as shown on screen.
///
/// Wording follows the Menopause Rating Scale. The licence for commercial use is still open;
/// if it is refused, only `title`, `hint` and `Questionnaire.scaleName` change.
public struct QuestionnaireItem: Sendable, Identifiable, Equatable {
    public enum Domain: String, Sendable { case somatic, psychological, urogenital }

    public let id: Int
    public let title: String
    public let hint: String
    public let domain: Domain
}

extension Questionnaire {
    public static let scaleName = "Menopause Rating Scale (MRS)"
    public static let intervalDays = 14
    public static let answerLabels = ["None", "Mild", "Moderate", "Severe", "Very severe"]

    public static let items: [QuestionnaireItem] = [
        .init(id: 0, title: "Hot flushes or sweating", hint: "Episodes of feeling hot, sweating", domain: .somatic),
        .init(id: 1, title: "Heart discomfort", hint: "Unusual awareness of heartbeat, racing, tightness", domain: .somatic),
        .init(id: 2, title: "Sleep problems", hint: "Trouble falling asleep, waking at night or too early", domain: .somatic),
        .init(id: 3, title: "Low mood", hint: "Feeling down, sad, close to tears, lack of drive", domain: .psychological),
        .init(id: 4, title: "Irritability", hint: "Feeling nervous, tense, aggressive", domain: .psychological),
        .init(id: 5, title: "Anxiety", hint: "Inner restlessness, feeling panicky", domain: .psychological),
        .init(id: 6, title: "Physical and mental exhaustion", hint: "Lower performance, poor memory and concentration", domain: .psychological),
        .init(id: 7, title: "Sexual problems", hint: "Change in desire, activity or satisfaction", domain: .urogenital),
        .init(id: 8, title: "Bladder problems", hint: "Needing to pee often, urgency, leaking", domain: .urogenital),
        .init(id: 9, title: "Vaginal dryness", hint: "Dryness or burning, difficulty with intercourse", domain: .urogenital),
        .init(id: 10, title: "Joint and muscle discomfort", hint: "Aches in joints, rheumatic-like complaints", domain: .somatic),
    ]

    /// Score and maximum for one domain, or nil until the questionnaire is complete.
    public func subscore(_ domain: QuestionnaireItem.Domain) -> (score: Int, max: Int)? {
        guard total != nil else { return nil }
        let ids = Self.items.filter { $0.domain == domain }.map(\.id)
        return (ids.map { answers[$0] }.reduce(0, +), ids.count * 4)
    }

    /// The questionnaire is due 14 days after the last complete one, or right away if there is none.
    public static func nextDue(after history: [Questionnaire]) -> DayKey? {
        history.filter { $0.total != nil }.map(\.day).max()?.adding(days: intervalDays)
    }

    public static func isDue(today: DayKey, history: [Questionnaire]) -> Bool {
        guard let due = nextDue(after: history) else { return true }
        return today >= due
    }
}

/// Days without a check-in that can still be filled in. Older days stay empty so the report stays honest.
public enum MissedDays {
    public static let maxDaysBack = 3

    public static func fillable(today: DayKey, logged: Set<DayKey>, trackingStarted: DayKey) -> [DayKey] {
        (1...maxDaysBack)
            .map { today.adding(days: -$0) }
            .filter { $0 >= trackingStarted && !logged.contains($0) }
            .sorted()
    }
}
