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
    public enum Feeling: String, Codable, Sendable, CaseIterable { case yes, partly, no }
    public enum Decision: String, Codable, Sendable, CaseIterable {
        case startedTreatment, bloodTests, referral, comeBackLater, nothingYet

        public var label: String {
            switch self {
            case .startedTreatment: L10n.text("Started treatment")
            case .bloodTests: L10n.text("Blood tests")
            case .referral: L10n.text("Referral")
            case .comeBackLater: L10n.text("Come back later")
            case .nothingYet: L10n.text("Nothing yet")
            }
        }
    }

    public var id: UUID
    public var day: DayKey
    /// Free text: "GP", "gynaecologist", "menopause clinic".
    public var clinician: String
    /// In the user's words, shown at the top of the report.
    public var reason: String
    public var takenSeriously: Feeling?
    public var decisions: Set<Decision>
    public var outcome: String
    public var followUp: DayKey?

    public init(
        id: UUID = UUID(), day: DayKey, clinician: String = "", reason: String = "",
        takenSeriously: Feeling? = nil, decisions: Set<Decision> = [], outcome: String = "", followUp: DayKey? = nil
    ) {
        self.id = id
        self.day = day
        self.clinician = clinician
        self.reason = reason
        self.takenSeriously = takenSeriously
        self.decisions = decisions
        self.outcome = outcome
        self.followUp = followUp
    }

    private enum CodingKeys: String, CodingKey { case id, day, clinician, reason, takenSeriously, decisions, outcome, followUp }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        day = try c.decode(DayKey.self, forKey: .day)
        clinician = try c.decodeIfPresent(String.self, forKey: .clinician) ?? ""
        reason = try c.decodeIfPresent(String.self, forKey: .reason) ?? ""
        takenSeriously = try c.decodeIfPresent(Feeling.self, forKey: .takenSeriously)
        decisions = Set(try c.decodeIfPresent([Decision].self, forKey: .decisions) ?? [])
        outcome = try c.decodeIfPresent(String.self, forKey: .outcome) ?? ""
        followUp = try c.decodeIfPresent(DayKey.self, forKey: .followUp)
    }

    /// Decisions are written sorted so the same data always gives the same file.
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(day, forKey: .day)
        try c.encode(clinician, forKey: .clinician)
        try c.encode(reason, forKey: .reason)
        try c.encodeIfPresent(takenSeriously, forKey: .takenSeriously)
        try c.encode(decisions.map(\.rawValue).sorted().compactMap(Decision.init(rawValue:)), forKey: .decisions)
        try c.encode(outcome, forKey: .outcome)
        try c.encodeIfPresent(followUp, forKey: .followUp)
    }
}

extension DoctorQuestion {
    /// Prompts other women often bring. They are questions to ask, not answers.
    public static func suggestions(for region: Region) -> [String] {
        [
            L10n.text("Could these symptoms be perimenopause, given my age and cycle changes?"),
            L10n.format("What are my treatment options, including %@, and what are the risks for me?", region.hormoneTherapyTerm),
            L10n.text("Is there anything else we should rule out, such as thyroid or iron levels?"),
            L10n.text("Do I need a blood test, or can we decide based on my symptoms?"),
            L10n.text("What can help with my sleep right now?"),
            L10n.text("Who should I see if this does not improve?"),
            L10n.text("When should we review how things are going?"),
        ]
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
