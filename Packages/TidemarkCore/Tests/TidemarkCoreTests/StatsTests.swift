import Foundation
import Testing
@testable import TidemarkCore

private let start = DayKey(year: 2026, month: 9, day: 21)

private func days(_ count: Int, _ make: (Int, DayKey) -> CheckIn) -> [CheckIn] {
    (0..<count).map { make($0, start.adding(days: $0)) }
}

@Suite("Comparison with recent days")
struct ComparisonTests {
    @Test func needsEnoughHistory() {
        let history = days(3) { _, d in CheckIn(day: d, ratings: ["fatigue": .mild]) }
        let today = CheckIn(day: start.adding(days: 3), ratings: ["fatigue": .severe])
        #expect(Comparison.trend(symptomID: "fatigue", today: today, history: history) == nil)
    }

    @Test func describesHigherSameLower() {
        let history = days(14) { _, d in CheckIn(day: d, ratings: ["fatigue": .mild]) }
        let day = start.adding(days: 14)
        #expect(Comparison.trend(symptomID: "fatigue", today: CheckIn(day: day, ratings: ["fatigue": .severe]), history: history) == .higherThanUsual)
        #expect(Comparison.trend(symptomID: "fatigue", today: CheckIn(day: day, ratings: ["fatigue": .mild]), history: history) == .aboutTheSame)
        #expect(Comparison.trend(symptomID: "fatigue", today: CheckIn(day: day, ratings: ["fatigue": .none]), history: history) == .lowerThanUsual)
    }
}

@Suite("Patterns")
struct PatternTests {
    @Test func findsNextDayAlcoholPattern() throws {
        // Alcohol every 4th day; night sweats are moderate the day after alcohol, mild otherwise.
        let checkIns = days(48) { i, d in
            let drank = i % 4 == 0
            let afterDrink = i % 4 == 1
            return CheckIn(day: d, ratings: ["night_sweats": afterDrink ? .moderate : .mild], factors: drank ? [.alcohol] : [])
        }
        let found = PatternFinder.patterns(in: checkIns, symptomIDs: ["night_sweats"])
        let alcohol = try #require(found.first { $0.factor == .alcohol })
        #expect(alcohol.nextDay)
        #expect(alcohol.withFactorHits == alcohol.withFactorDays)
        #expect(alcohol.withoutFactorHits == 0)
    }

    @Test func staysQuietWithTooFewDays() {
        let checkIns = days(8) { i, d in
            CheckIn(day: d, ratings: ["fatigue": i < 2 ? .severe : .none], factors: i < 2 ? [.stress] : [])
        }
        #expect(PatternFinder.patterns(in: checkIns, symptomIDs: ["fatigue"]).isEmpty)
    }
}

@Suite("Cycle")
struct CycleTests {
    @Test func groupsFlowIntoPeriodsAndIgnoresSpotting() {
        var bleeding: [DayKey: Bleeding] = [:]
        for i in 0..<4 { bleeding[start.adding(days: i)] = .medium }
        bleeding[start.adding(days: 15)] = .spotting
        for i in 35..<41 { bleeding[start.adding(days: i)] = .light }
        bleeding[start.adding(days: 37)] = nil // one dry day inside still one period

        let summary = CycleStats.summary(of: bleeding)
        #expect(summary.periods.count == 2)
        #expect(summary.cycleLengths == [35])
        #expect(summary.spottingDays == 1)
        #expect(summary.periods[1].lengthInDays == 6)
    }

    @Test func flagsHeavyBleedingAndBleedingAfterAYear() {
        let old = CycleStats.summary(of: [DayKey(year: 2025, month: 9, day: 1): .medium])
        let today = CheckIn(day: DayKey(year: 2026, month: 11, day: 18), bleeding: .spotting)
        #expect(RedFlags.check(today: today, cycle: old) == [.bleedingAfterTwelveMonths])

        let heavy = CheckIn(day: DayKey(year: 2026, month: 11, day: 18), bleeding: .heavy)
        #expect(RedFlags.check(today: heavy, cycle: CycleSummary(periods: [], cycleLengths: [], spottingDays: 0)) == [.heavyBleeding])
    }

    @Test("The bleeding prompts use the region's term and match the option the user tapped")
    func flagWordingFollowsRegion() {
        for flag in [RedFlag.heavyBleeding, .bleedingAfterTwelveMonths] {
            #expect(flag.message(region: .unitedKingdom).contains("GP"))
            #expect(!flag.message(region: .unitedKingdom).contains("doctor"))
            #expect(flag.message(region: .unitedStates).contains("doctor"))
        }
        // The option is "Heavy", so the prompt must not say "very heavy".
        #expect(!RedFlag.heavyBleeding.message(region: .unitedStates).localizedCaseInsensitiveContains("very"))
    }
}

@Suite("Treatment check")
struct TreatmentCheckTests {
    @Test func comparesFourWeeksBeforeAndAfter() {
        let med = Medication(name: "Estradiol gel", kind: .prescribed, howTaken: "As prescribed", started: start.adding(days: 28))
        let checkIns = days(56) { i, d in CheckIn(day: d, ratings: ["hot_flushes": i < 28 ? .severe : .mild]) }
        let result = TreatmentCheck.compare(medication: med, checkIns: checkIns, questionnaires: [], symptomIDs: ["hot_flushes"])
        #expect(result.isReady)
        #expect(result.symptoms.first?.before == 3)
        #expect(result.symptoms.first?.after == 1)
    }

    @Test func notReadyRightAfterStarting() {
        let med = Medication(name: "Magnesium", kind: .supplement, howTaken: "As on label", started: start.adding(days: 30))
        let checkIns = days(33) { _, d in CheckIn(day: d, ratings: ["fatigue": .moderate]) }
        #expect(!TreatmentCheck.compare(medication: med, checkIns: checkIns, questionnaires: [], symptomIDs: ["fatigue"]).isReady)
    }
}

@Suite("Weekly summary and report")
struct WeeklyTests {
    @Test func comparesWithPreviousWeek() {
        let utc = TimeZone(identifier: "UTC")!
        let checkIns = days(14) { i, d in CheckIn(day: d, ratings: ["fatigue": i < 7 ? .severe : .mild]) }
        let episodes = (0..<10).map { i in
            Episode(kind: .hotFlush, at: start.adding(days: i < 6 ? 2 : 9).referenceDate)
        }
        let summary = WeeklySummaryBuilder.build(weekEnding: start.adding(days: 13), checkIns: checkIns, episodes: episodes, timeZone: utc)
        #expect(summary.checkInCount == 7)
        #expect(summary.averageBurden == 1)
        #expect(summary.previousAverageBurden == 3)
        #expect(summary.episodeCount == 4)
        #expect(summary.previousEpisodeCount == 6)
    }

    @Test func reportUnlocksAfterSevenCheckIns() {
        #expect(ReportReadiness.evaluate(checkIns: 6, questionnaires: 0) == .locked(checkInsSoFar: 6, needed: 7))
        #expect(ReportReadiness.evaluate(checkIns: 7, questionnaires: 1) == .ready(checkIns: 7, questionnaires: 1))
        #expect(Region.unitedStates.paper == .letter)
        #expect(Region.unitedKingdom.paper == .a4)
    }

    @Test func questionnaireNeedsAllAnswers() {
        #expect(Questionnaire(day: start, answers: Array(repeating: 2, count: 11)).total == 22)
        #expect(Questionnaire(day: start, answers: Array(repeating: 2, count: 10)).total == nil)
        #expect(Questionnaire(day: start, answers: Array(repeating: 5, count: 11)).total == nil)
    }
}
