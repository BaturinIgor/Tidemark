import Foundation
import Testing
@testable import TidemarkCore

/// Made-up export file for App Review: 8 weeks of check-ins, so the reviewer can import it
/// (Settings › Import) and see the report without logging for 7 days.
///
///   REVIEW_SAMPLE_OUT=build/Tidemark-review-sample.json swift test --filter ReviewSample
///
/// Make it on the day you submit: the report counts the last weeks before today.
@Suite("Review sample")
struct ReviewSampleTests {
    static func make(today: DayKey = DayKey(Date()), now: Date = Date(timeIntervalSince1970: Date().timeIntervalSince1970.rounded(.down))) -> ExportFile {
        let symptoms = ["trouble_falling_asleep", "waking_at_night", "fatigue", "night_sweats",
                        "hot_flushes", "brain_fog", "anxiety", "joint_aches"]
        let first = -55
        var checkIns: [CheckIn] = []
        for offset in first...(-1) where offset != -20 && offset != -33 {
            var ratings: [String: Severity] = [:]
            for (i, id) in symptoms.enumerated() {
                let raw = (abs(offset) * (i + 3) + i * 5) % 7
                var level = raw < 2 ? 0 : raw < 4 ? 1 : raw < 6 ? 2 : 3
                if offset > -28 && level > 0 && (offset + i) % 2 == 0 { level -= 1 }
                ratings[id] = Severity(rawValue: level) ?? .none
            }
            let bleeding: Bleeding = switch offset {
            case -50, -49: .medium
            case -48, -47, -46: .light
            case -22, -21: .medium
            case -19, -18: .light
            case -9: .spotting
            default: .none
            }
            var factors: Set<Factor> = []
            if offset % 5 == 0 { factors.insert(.poorSleep) }
            if offset % 7 == 0 { factors.formUnion([.caffeine, .stress]) }
            checkIns.append(CheckIn(day: today.adding(days: offset), ratings: ratings,
                                    impact: DailyImpact(rawValue: (abs(offset) + 1) % 4),
                                    bleeding: bleeding, factors: factors,
                                    note: offset == -1 ? "Woke at 3am twice. Slow start at work." : ""))
        }
        let questionnaires = [(-56, [3, 3, 2, 2, 3, 3, 2, 2, 1, 2, 3]), (-42, [3, 2, 2, 2, 3, 2, 2, 2, 1, 2, 3]),
                              (-28, [2, 2, 2, 2, 2, 2, 2, 1, 1, 2, 2]), (-14, [2, 1, 1, 1, 2, 1, 1, 1, 0, 1, 2])]
            .map { Questionnaire(day: today.adding(days: $0.0), answers: $0.1) }
        var episodes: [Episode] = []
        for day in 1...14 {
            for (n, hours) in [7.0, 13.5, 22.0].enumerated() where (day + n) % 3 != 0 {
                let at = now.addingTimeInterval(-Double(day) * 86_400 + (hours - 12) * 3_600)
                episodes.append(Episode(kind: hours > 21 ? .nightSweat : .hotFlush, at: at,
                                        intensity: Severity(rawValue: 1 + (day + n) % 3) ?? .mild))
            }
        }
        return ExportFile(
            exportedAt: now, appVersion: "1.0",
            profile: Profile(region: .unitedStates, age: 49, trackedSymptomIDs: symptoms),
            checkIns: checkIns, episodes: episodes, questionnaires: questionnaires,
            medications: [Medication(name: "Vitamin D", kind: .supplement, howTaken: "Daily", started: today.adding(days: first)),
                          Medication(name: "Hormone patch", kind: .prescribed, howTaken: "As prescribed", started: today.adding(days: -28))],
            questions: ["Could my sleep problems be linked to perimenopause?",
                        "What are my options if the patches irritate my skin?",
                        "Should we check my iron after the heavy periods?"]
                .enumerated().map { DoctorQuestion(text: $0.element, rank: $0.offset) },
            visits: [Visit(day: today.adding(days: -30), clinician: "Dr. Patel", reason: "Sleep and hot flashes since spring",
                           takenSeriously: .partly, decisions: [.startedTreatment, .bloodTests],
                           outcome: "Talked through options. Blood tests next week.", followUp: today.adding(days: 7)),
                     Visit(day: today.adding(days: 7), clinician: "Dr. Patel", reason: "Follow-up after six weeks")])
    }

    @Test("The sample unlocks the report and survives an export round trip")
    func sample() throws {
        let file = Self.make()
        #expect(file.checkIns.count >= ReportReadiness.minimumCheckIns)
        let data = try ExportCodec.encode(file)
        #expect(try ExportCodec.decode(data) == file)
        if let out = ProcessInfo.processInfo.environment["REVIEW_SAMPLE_OUT"], !out.isEmpty {
            try data.write(to: URL(fileURLWithPath: out))
        }
    }
}
