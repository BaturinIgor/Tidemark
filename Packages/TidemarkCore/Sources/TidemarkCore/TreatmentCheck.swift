import Foundation

/// Average rating per symptom for a window before and after a medicine was started.
public struct TreatmentWindow: Equatable, Sendable {
    public let symptomID: String
    public let before: Double?
    public let after: Double?
    public let beforeDays: Int
    public let afterDays: Int
}

public struct TreatmentCheckResult: Equatable, Sendable {
    public let medication: Medication
    public let windowDays: Int
    public let symptoms: [TreatmentWindow]
    public let questionnaireBefore: Int?
    public let questionnaireAfter: Int?
    /// False until the user has logged enough days after the start date. The screen shows a countdown instead.
    public let isReady: Bool
}

public enum TreatmentCheck {
    public static let defaultWindowDays = 28
    public static let minimumDaysPerSide = 10

    public static func compare(
        medication: Medication,
        checkIns: [CheckIn],
        questionnaires: [Questionnaire],
        symptomIDs: [String],
        windowDays: Int = defaultWindowDays
    ) -> TreatmentCheckResult {
        let start = medication.started
        let beforeRange = start.adding(days: -windowDays)..<start
        let afterRange = start..<start.adding(days: windowDays)
        let before = checkIns.filter { beforeRange.contains($0.day) }
        let after = checkIns.filter { afterRange.contains($0.day) }

        func mean(_ items: [CheckIn], _ id: String) -> (Double?, Int) {
            let values = items.compactMap { $0.ratings[id]?.rawValue }
            guard !values.isEmpty else { return (nil, 0) }
            return (Double(values.reduce(0, +)) / Double(values.count), values.count)
        }

        let windows = symptomIDs.map { id -> TreatmentWindow in
            let (b, bc) = mean(before, id)
            let (a, ac) = mean(after, id)
            return TreatmentWindow(symptomID: id, before: b, after: a, beforeDays: bc, afterDays: ac)
        }

        let qBefore = questionnaires.filter { beforeRange.contains($0.day) }.max(by: { $0.day < $1.day })?.total
        let qAfter = questionnaires.filter { afterRange.contains($0.day) }.max(by: { $0.day < $1.day })?.total
        let ready = before.count >= minimumDaysPerSide && after.count >= minimumDaysPerSide

        return TreatmentCheckResult(
            medication: medication, windowDays: windowDays, symptoms: windows,
            questionnaireBefore: qBefore, questionnaireAfter: qAfter, isReady: ready
        )
    }
}
