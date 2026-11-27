import Foundation
import Testing
@testable import TidemarkCore

/// Automated parts of the data safety scenarios D4, D5, D7 and D8.
@Suite("Data safety")
struct DataSafetyTests {
    private let day = DayKey(year: 2026, month: 11, day: 18)

    private func sampleFile() -> ExportFile {
        ExportFile(
            exportedAt: Date(timeIntervalSince1970: 1_795_000_000),
            appVersion: "1.0 (1)",
            profile: Profile(region: .unitedKingdom, age: 46, trackedSymptomIDs: ["fatigue", "night_sweats"]),
            checkIns: [
                CheckIn(day: day, ratings: ["fatigue": .moderate, "night_sweats": .severe], impact: .quiteABit,
                        bleeding: .spotting, factors: [.alcohol, .stress], note: "Woke at 3, \"soaked\", couldn't sleep"),
                CheckIn(day: day.adding(days: -1), ratings: ["fatigue": .mild]),
            ],
            episodes: [Episode(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, kind: .hotFlush,
                               at: Date(timeIntervalSince1970: 1_794_990_000), intensity: .severe, source: .lockScreen)],
            questionnaires: [Questionnaire(day: day, answers: Array(repeating: 2, count: 11))],
            medications: [Medication(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Vitamin D",
                                     kind: .supplement, howTaken: "1 tablet daily", started: DayKey(year: 2024, month: 1, day: 1))],
            questions: [DoctorQuestion(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, text: "Could this be perimenopause?", rank: 1)],
            visits: [Visit(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, day: day.adding(days: 12))]
        )
    }

    @Test("D5: export, wipe, import gives identical data")
    func exportImportRoundTrip() throws {
        let original = sampleFile()
        let data = try ExportCodec.encode(original)
        let restored = try ExportCodec.decode(data)
        #expect(restored == original)
        // Byte for byte: encoding the restored copy gives the same file.
        #expect(try ExportCodec.encode(restored) == data)
    }

    @Test("D5: a file from a future app version is refused, not half-imported")
    func refusesFutureVersion() throws {
        var json = String(decoding: try ExportCodec.encode(sampleFile()), as: UTF8.self)
        json = json.replacingOccurrences(of: "\"formatVersion\" : 1", with: "\"formatVersion\" : 99")
        #expect(throws: ExportError.unsupportedVersion(99)) {
            try ExportCodec.decode(Data(json.utf8))
        }
    }

    @Test("D5: an export without custom symptoms is byte for byte the old format")
    func profileWithoutCustomSymptomsKeepsOldFormat() throws {
        let json = String(decoding: try ExportCodec.encode(sampleFile()), as: UTF8.self)
        #expect(!json.contains("customSymptoms"))
        // A file written before custom symptoms existed still decodes.
        let old = #"{"region":"UK","age":46,"trackedSymptomIDs":["fatigue"]}"#
        let profile = try JSONDecoder().decode(Profile.self, from: Data(old.utf8))
        #expect(profile.customSymptoms.isEmpty)
    }

    @Test("D5: custom symptoms and their ratings survive export and import")
    func customSymptomsRoundTrip() throws {
        var file = sampleFile()
        let custom = CustomSymptom(id: "custom_test", name: "Tingling, \"pins\" in hands")
        file.profile.customSymptoms = [custom]
        file.profile.trackedSymptomIDs.append(custom.id)
        file.checkIns[0].ratings[custom.id] = .mild
        let data = try ExportCodec.encode(file)
        let restored = try ExportCodec.decode(data)
        #expect(restored == file)
        #expect(try ExportCodec.encode(restored) == data)
    }

    @Test("D8: two devices editing different fields offline keep both edits")
    func perFieldMerge() {
        let t0 = Date(timeIntervalSince1970: 1_000)
        // iPhone changes fatigue, iPad changes night sweats; each field is its own row.
        let rows: [(key: String, value: Stamped<Int>)] = [
            ("2026-11-18|fatigue", Stamped(1, updatedAt: t0, deviceID: "ipad")),
            ("2026-11-18|fatigue", Stamped(3, updatedAt: t0.addingTimeInterval(60), deviceID: "iphone")),
            ("2026-11-18|night_sweats", Stamped(2, updatedAt: t0.addingTimeInterval(30), deviceID: "ipad")),
        ]
        let result = FieldMerge.deduplicate(rows)
        #expect(result.keep["2026-11-18|fatigue"]?.value == 3)
        #expect(result.keep["2026-11-18|night_sweats"]?.value == 2)
        #expect(result.discard.count == 1)
    }

    @Test("D8: ties resolve the same way on every device")
    func deterministicTieBreak() {
        let t = Date(timeIntervalSince1970: 5)
        let a = Stamped("a", updatedAt: t, deviceID: "A")
        let b = Stamped("b", updatedAt: t, deviceID: "B")
        #expect(FieldMerge.winner([a, b]) == b)
        #expect(FieldMerge.winner([b, a]) == b)
    }

    @Test("D7: deleted items are kept for 30 days")
    func recentlyDeleted() {
        let deleted = Date(timeIntervalSince1970: 0)
        #expect(RecentlyDeleted.daysLeft(deletedAt: deleted, now: deleted.addingTimeInterval(86_400 * 3)) == 27)
        #expect(!RecentlyDeleted.isExpired(deletedAt: deleted, now: deleted.addingTimeInterval(86_400 * 29)))
        #expect(RecentlyDeleted.isExpired(deletedAt: deleted, now: deleted.addingTimeInterval(86_400 * 31)))
    }

    @Test("D4: backup warning after 24 hours or when iCloud is unavailable")
    func backupWarning() {
        let now = Date(timeIntervalSince1970: 100_000)
        #expect(BackupHealth.evaluate(signedIn: false, quotaExceeded: false, lastSuccess: now, now: now) == .warning(.iCloudSignedOut))
        #expect(BackupHealth.evaluate(signedIn: true, quotaExceeded: true, lastSuccess: now, now: now) == .warning(.iCloudFull))
        #expect(BackupHealth.evaluate(signedIn: true, quotaExceeded: false, lastSuccess: now.addingTimeInterval(-3_600), now: now) == .ok(lastBackup: now.addingTimeInterval(-3_600)))
        #expect(BackupHealth.evaluate(signedIn: true, quotaExceeded: false, lastSuccess: now.addingTimeInterval(-90_000), now: now) == .warning(.noBackupFor(hours: 25)))
    }
}
