import Foundation
import Testing
@testable import TidemarkCore

private let start = DayKey(year: 2026, month: 9, day: 21)

@Suite("Questionnaire schedule and subscores")
struct QuestionnaireScheduleTests {
    @Test func dueRightAwayThenEveryTwoWeeks() {
        #expect(Questionnaire.isDue(today: start, history: []))
        let first = Questionnaire(day: start, answers: Array(repeating: 1, count: 11))
        #expect(Questionnaire.nextDue(after: [first]) == start.adding(days: 14))
        #expect(!Questionnaire.isDue(today: start.adding(days: 13), history: [first]))
        #expect(Questionnaire.isDue(today: start.adding(days: 14), history: [first]))
    }

    @Test func incompleteQuestionnaireDoesNotCount() {
        let partial = Questionnaire(day: start, answers: [1, 2])
        #expect(Questionnaire.isDue(today: start.adding(days: 1), history: [partial]))
    }

    @Test func subscoresAddUpToTotal() throws {
        let q = Questionnaire(day: start, answers: [3, 1, 4, 2, 2, 1, 3, 1, 0, 1, 2])
        let somatic = try #require(q.subscore(.somatic))
        let psych = try #require(q.subscore(.psychological))
        let uro = try #require(q.subscore(.urogenital))
        #expect(somatic.max == 16 && psych.max == 16 && uro.max == 12)
        #expect(somatic.score + psych.score + uro.score == q.total)
        #expect(Questionnaire.items.count == Questionnaire.itemCount)
    }
}

@Suite("Missed days")
struct MissedDaysTests {
    @Test func offersUpToThreeDaysBackAfterStart() {
        let today = start.adding(days: 10)
        let logged: Set<DayKey> = [today.adding(days: -3)]
        #expect(MissedDays.fillable(today: today, logged: logged, trackingStarted: start) == [today.adding(days: -2), today.adding(days: -1)])
        #expect(MissedDays.fillable(today: start.adding(days: 1), logged: [], trackingStarted: start) == [start])
    }
}

@Suite("Report summary")
struct ReportSummaryTests {
    @Test func countsDaysAveragesAndTrend() {
        let checkIns = (0..<56).map { i in
            CheckIn(day: start.adding(days: i),
                    ratings: ["waking_at_night": i < 28 ? .mild : .severe, "fatigue": i % 2 == 0 ? .none : .moderate],
                    impact: i % 4 == 0 ? .aLot : .aLittle,
                    bleeding: i == 3 ? .heavy : .none)
        }
        let summary = ReportSummary.build(
            from: start, to: start.adding(days: 55), trackedSymptomIDs: ["fatigue", "waking_at_night"],
            checkIns: checkIns, episodes: [], questionnaires: []
        )
        #expect(summary.daysInRange == 56)
        #expect(summary.daysLogged == 56)
        #expect(summary.symptoms.first?.symptomID == "waking_at_night")
        #expect(summary.symptoms.first?.days == 56)
        #expect(summary.symptoms.first?.average == 2)
        #expect(summary.symptoms.first?.trend == .higherThanUsual)
        #expect(summary.symptoms.last?.days == 28)
        #expect(summary.symptoms.last?.trend == .aboutTheSame)
        #expect(summary.hardImpactDays == 14)
        #expect(summary.heavyBleedingDays == 1)
    }
}

@Suite("Visits in exports")
struct VisitExportTests {
    @Test func visitRoundTripsWithDecisions() throws {
        let visit = Visit(day: start, clinician: "GP", reason: "Not myself since spring",
                          takenSeriously: .partly, decisions: [.bloodTests, .startedTreatment], outcome: "Bloods next week")
        let data = try JSONEncoder().encode(visit)
        #expect(try JSONDecoder().decode(Visit.self, from: data) == visit)
        #expect(DoctorQuestion.suggestions(for: .unitedKingdom)[1].contains("HRT"))
        #expect(DoctorQuestion.suggestions(for: .unitedStates)[1].contains("hormone therapy"))
    }
}
