import Foundation
import Testing
@testable import TidemarkCore

@Suite("Pro features")
struct ProFeatureTests {
    private let today = DayKey(year: 2026, month: 11, day: 27)

    private func file(custom: [CustomSymptom] = []) -> ExportFile {
        ExportFile(
            exportedAt: Date(timeIntervalSince1970: 1_795_000_000), appVersion: "1.0",
            profile: Profile(region: .unitedKingdom, age: 50, trackedSymptomIDs: ["night_sweats", "fatigue"] + custom.map(\.id),
                             customSymptoms: custom),
            checkIns: [
                CheckIn(day: today, ratings: ["fatigue": .moderate, "night_sweats": .severe], impact: .quiteABit,
                        bleeding: .spotting, factors: [.stress, .alcohol], note: "Woke at 3, \"soaked\"\nagain"),
                CheckIn(day: today.adding(days: -1), ratings: ["fatigue": .mild, "brain_fog": .mild]),
            ],
            episodes: [Episode(kind: .hotFlush, at: Date(timeIntervalSince1970: 1_795_000_000), intensity: .severe)],
            medications: [Medication(name: "=HYPERLINK(\"x\")", kind: .supplement, howTaken: "Daily, with food",
                                     started: DayKey(year: 2026, month: 1, day: 2))]
        )
    }

    // MARK: CSV

    @Test("CSV: one row per day, ISO dates, tracked symptoms first, then others rated")
    func csvDays() {
        let csv = CSVExport.days(file())
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        #expect(lines[0] == "Date,Night sweats,Fatigue,Brain fog,Impact on the day (0–3),Bleeding,Factors,Note")
        #expect(lines[1] == "2026-11-26,,1,1,,,,")
        #expect(lines[2].hasPrefix("2026-11-27,3,2,,2,Spotting,\"Alcohol; Stress\","))
        #expect(csv.hasSuffix("\n"))
    }

    @Test("CSV: quotes, commas, newlines and formula-like text are escaped")
    func csvEscaping() {
        #expect(CSVExport.escape("plain") == "plain")
        #expect(CSVExport.escape("a, b") == "\"a, b\"")
        #expect(CSVExport.escape("say \"hi\"") == "\"say \"\"hi\"\"\"")
        #expect(CSVExport.escape("line\nbreak") == "\"line\nbreak\"")
        #expect(CSVExport.escape("=1+1") == "'=1+1")
        #expect(CSVExport.escape("-5") == "'-5")
        let days = CSVExport.days(file())
        #expect(days.contains("\"Woke at 3, \"\"soaked\"\"\nagain\""))
        let meds = CSVExport.medicines(file())
        #expect(meds.contains("\"'=HYPERLINK(\"\"x\"\")\",Supplement,\"Daily, with food\",2026-01-02,"))
    }

    @Test("CSV: custom symptoms use the user's own name as the column title")
    func csvCustomSymptom() {
        let custom = CustomSymptom(id: "custom_a", name: "Tingling hands")
        var f = file(custom: [custom])
        f.checkIns[0].ratings[custom.id] = .mild
        let header = CSVExport.days(f).split(separator: "\n").first.map(String.init) ?? ""
        #expect(header.hasPrefix("Date,Night sweats,Fatigue,Tingling hands,Brain fog,"))
    }

    @Test("CSV: quick logs carry date, time and type, in the given time zone")
    func csvQuickLogs() {
        let csv = CSVExport.quickLogs(file(), timeZone: TimeZone(identifier: "UTC")!)
        #expect(csv.hasPrefix("Date,Time,Type,Intensity (1–3)\n"))
        // 1_795_000_000 = 2026-11-18 11:06:40 UTC
        #expect(csv.contains("2026-11-18,11:06,Hot flush,3"))
    }

    // MARK: Custom symptoms

    @Test("Custom symptom names are cleaned and labels resolve through the registry")
    func customSymptomNames() {
        #expect(CustomSymptom.cleanName("  \n ") == nil)
        #expect(CustomSymptom.cleanName("  Tingling\nhands ") == "Tingling hands")
        #expect(CustomSymptom.cleanName(String(repeating: "x", count: 80))?.count == CustomSymptom.maxNameLength)
        let s = CustomSymptom(name: "Dizzy spells")
        #expect(CustomSymptom.isCustom(s.id))
        CustomSymptomNames.shared.update([s])
        #expect(Symptom.label(for: s.id) == "Dizzy spells")
        #expect(Symptom.label(for: "fatigue") == "Fatigue")
        CustomSymptomNames.shared.update([])
    }

    @Test("Free tracks 8 symptoms; Pro has no limit")
    func trackingLimit() {
        #expect(Symptom.trackingLimit(isPro: false) == 8)
        #expect(Symptom.trackingLimit(isPro: true) == nil)
    }

    // MARK: Ranges

    @Test("6 and 12 months need Pro; a lapsed choice falls back to 12 weeks")
    func ranges() {
        #expect(HistoryRange.allCases.filter(\.needsPro) == [.months6, .months12])
        #expect(HistoryRange.allowed(52, isPro: false) == .weeks12)
        #expect(HistoryRange.allowed(52, isPro: true) == .months12)
        #expect(HistoryRange.allowed(4, isPro: false) == .weeks4)
        #expect(HistoryRange.allowed(5, isPro: false) == .weeks8)
        #expect(HistoryRange.months12.start(endingOn: today) == today.adding(days: -363))
    }

    // MARK: Since your last visit

    @Test("Comparison: equal periods either side of the split, averages of the user's own ratings")
    func comparison() throws {
        let split = today.adding(days: -9)
        var checkIns: [CheckIn] = []
        for offset in -19...0 {
            let day = today.adding(days: offset)
            let level: Severity = day < split ? .severe : .mild
            checkIns.append(CheckIn(day: day, ratings: ["fatigue": level], impact: day < split ? .aLot : .notAtAll,
                                    bleeding: offset == -15 ? .light : .none))
        }
        let result = try #require(PeriodComparison.build(
            split: split, today: today, symptomIDs: ["fatigue", "brain_fog"], checkIns: checkIns, episodes: [],
            questionnaires: [Questionnaire(day: today.adding(days: -12), answers: Array(repeating: 3, count: 11))]))
        #expect(result.after.from == split && result.after.to == today)
        #expect(result.before.from == split.adding(days: -10) && result.before.to == split.adding(days: -1))
        #expect(result.before.daysLogged == 10 && result.after.daysLogged == 10)
        #expect(result.rows[0].before == 3 && result.rows[0].after == 1)
        #expect(result.rows[0].daysPresentBefore == 10)
        #expect(result.rows[1].before == nil && result.rows[1].after == nil)
        #expect(result.before.hardImpactDays == 10 && result.after.hardImpactDays == 0)
        #expect(result.before.bleedingDays == 1)
        #expect(result.before.questionnaire == 33 && result.after.questionnaire == nil)
        #expect(result.isReady)
    }

    @Test("Comparison: not ready with too few days; no comparison for a future split; capped at 12 weeks")
    func comparisonLimits() {
        let few = [CheckIn(day: today, ratings: ["fatigue": .mild])]
        #expect(PeriodComparison.build(split: today.adding(days: -3), today: today, symptomIDs: ["fatigue"],
                                       checkIns: few, episodes: [], questionnaires: [])?.isReady == false)
        #expect(PeriodComparison.build(split: today.adding(days: 1), today: today, symptomIDs: [],
                                       checkIns: [], episodes: [], questionnaires: []) == nil)
        let long = PeriodComparison.build(split: today.adding(days: -200), today: today, symptomIDs: [],
                                          checkIns: [], episodes: [], questionnaires: [])
        #expect(long?.after.from.days(until: long!.after.to) == PeriodComparison.maximumDays - 1)
    }

    @Test("Default split is the last appointment before today, else 4 weeks ago")
    func defaultSplit() {
        let visits = [Visit(day: today.adding(days: -40)), Visit(day: today.adding(days: -10)), Visit(day: today.adding(days: 5))]
        #expect(PeriodComparison.defaultSplit(visits: visits, today: today) == today.adding(days: -10))
        #expect(PeriodComparison.defaultSplit(visits: [], today: today) == today.adding(days: -28))
    }
}
