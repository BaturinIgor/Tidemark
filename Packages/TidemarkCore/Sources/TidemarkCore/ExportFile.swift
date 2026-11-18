import Foundation

/// Everything the user has, in one versioned file (requirement D5).
///
/// Rules that keep old exports importable forever:
/// - `formatVersion` only goes up; the importer accepts every version it has ever written.
/// - Fields are only added, never renamed or removed. New fields must be optional.
public struct ExportFile: Codable, Equatable, Sendable {
    public static let currentFormatVersion = 1

    public var formatVersion: Int
    public var exportedAt: Date
    public var appVersion: String
    public var profile: Profile
    public var checkIns: [CheckIn]
    public var episodes: [Episode]
    public var questionnaires: [Questionnaire]
    public var medications: [Medication]
    public var questions: [DoctorQuestion]
    public var visits: [Visit]

    public init(
        exportedAt: Date,
        appVersion: String,
        profile: Profile,
        checkIns: [CheckIn],
        episodes: [Episode] = [],
        questionnaires: [Questionnaire] = [],
        medications: [Medication] = [],
        questions: [DoctorQuestion] = [],
        visits: [Visit] = []
    ) {
        self.formatVersion = Self.currentFormatVersion
        self.exportedAt = exportedAt
        self.appVersion = appVersion
        self.profile = profile
        self.checkIns = checkIns.sorted { $0.day < $1.day }
        self.episodes = episodes.sorted { $0.at < $1.at }
        self.questionnaires = questionnaires.sorted { $0.day < $1.day }
        self.medications = medications
        self.questions = questions
        self.visits = visits
    }
}

public struct Profile: Codable, Equatable, Sendable {
    public var region: Region
    public var age: Int?
    public var trackedSymptomIDs: [String]

    public init(region: Region, age: Int?, trackedSymptomIDs: [String]) {
        self.region = region
        self.age = age
        self.trackedSymptomIDs = trackedSymptomIDs
    }
}

public struct DoctorQuestion: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var text: String
    public var rank: Int
    public var asked: Bool

    public init(id: UUID = UUID(), text: String, rank: Int, asked: Bool = false) {
        self.id = id
        self.text = text
        self.rank = rank
        self.asked = asked
    }
}

public struct Visit: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var day: DayKey
    public var takenSeriously: Bool?
    public var outcome: String
    public var followUp: DayKey?

    public init(id: UUID = UUID(), day: DayKey, takenSeriously: Bool? = nil, outcome: String = "", followUp: DayKey? = nil) {
        self.id = id
        self.day = day
        self.takenSeriously = takenSeriously
        self.outcome = outcome
        self.followUp = followUp
    }
}

public enum ExportError: Error, Equatable {
    case unsupportedVersion(Int)
}

public enum ExportCodec {
    public static func encode(_ file: ExportFile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(file)
    }

    public static func decode(_ data: Data) throws -> ExportFile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        struct VersionProbe: Decodable { let formatVersion: Int }
        let version = try decoder.decode(VersionProbe.self, from: data).formatVersion
        guard (1...ExportFile.currentFormatVersion).contains(version) else {
            throw ExportError.unsupportedVersion(version)
        }
        return try decoder.decode(ExportFile.self, from: data)
    }

    /// One row per day per symptom, easy to open in a spreadsheet.
    public static func csv(_ file: ExportFile) -> String {
        let labels = Dictionary(Symptom.catalog.map { ($0.id, $0.label) }, uniquingKeysWith: { a, _ in a })
        var lines = ["date,symptom,severity,impact,bleeding,factors,note"]
        for checkIn in file.checkIns {
            let factors = checkIn.factors.map(\.rawValue).sorted().joined(separator: ";")
            let impact = checkIn.impact.map { String($0.rawValue) } ?? ""
            for (id, severity) in checkIn.ratings.sorted(by: { $0.key < $1.key }) {
                let fields = [
                    checkIn.day.description,
                    labels[id] ?? id,
                    String(severity.rawValue),
                    impact,
                    String(checkIn.bleeding.rawValue),
                    factors,
                    checkIn.note,
                ]
                lines.append(fields.map(escape).joined(separator: ","))
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
