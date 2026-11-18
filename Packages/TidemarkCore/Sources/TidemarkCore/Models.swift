import Foundation

/// Severity on the daily 0–3 scale shown in the check-in.
public enum Severity: Int, Codable, CaseIterable, Comparable, Sendable {
    case none = 0, mild = 1, moderate = 2, severe = 3

    public static func < (lhs: Severity, rhs: Severity) -> Bool { lhs.rawValue < rhs.rawValue }

    public var label: String {
        switch self {
        case .none: "None"
        case .mild: "Mild"
        case .moderate: "Moderate"
        case .severe: "Severe"
        }
    }
}

/// How much symptoms got in the way of the day.
public enum DailyImpact: Int, Codable, CaseIterable, Sendable {
    case notAtAll = 0, aLittle = 1, quiteABit = 2, aLot = 3
}

/// Bleeding recorded for a day. Feeds the cycle calendar and the report.
public enum Bleeding: Int, Codable, CaseIterable, Sendable {
    case none = 0, spotting = 1, light = 2, medium = 3, heavy = 4

    /// Spotting does not start a new cycle; any real flow does.
    public var countsAsPeriod: Bool { rawValue >= Bleeding.light.rawValue }
}

/// Optional tags on a check-in. Used only to describe co-occurrence, never to give advice.
public enum Factor: String, Codable, CaseIterable, Sendable {
    case alcohol, caffeine, stress, spicyFood, hotWeather, exercise, poorSleep

    public var label: String {
        switch self {
        case .alcohol: "Alcohol"
        case .caffeine: "Caffeine"
        case .stress: "Stress"
        case .spicyFood: "Spicy food"
        case .hotWeather: "Hot weather"
        case .exercise: "Exercise"
        case .poorSleep: "Poor sleep"
        }
    }
}

/// A symptom the user can track. Built-in ids are stable strings, so renaming a label never breaks stored data.
public struct Symptom: Hashable, Codable, Sendable, Identifiable {
    public let id: String
    public let label: String

    public init(id: String, label: String) {
        self.id = id
        self.label = label
    }

    public static let catalog: [Symptom] = [
        .init(id: "hot_flushes", label: "Hot flushes"),
        .init(id: "night_sweats", label: "Night sweats"),
        .init(id: "waking_at_night", label: "Waking at night"),
        .init(id: "fatigue", label: "Fatigue"),
        .init(id: "brain_fog", label: "Brain fog"),
        .init(id: "irritability", label: "Irritability"),
        .init(id: "low_mood", label: "Low mood"),
        .init(id: "anxiety", label: "Anxiety"),
        .init(id: "joint_aches", label: "Joint aches"),
        .init(id: "headaches", label: "Headaches"),
        .init(id: "palpitations", label: "Heart palpitations"),
        .init(id: "irregular_periods", label: "Irregular periods"),
        .init(id: "heavy_periods", label: "Heavy periods"),
        .init(id: "breast_tenderness", label: "Breast tenderness"),
        .init(id: "vaginal_dryness", label: "Vaginal dryness"),
        .init(id: "low_libido", label: "Low libido"),
        .init(id: "bladder_urgency", label: "Bladder urgency"),
        .init(id: "dry_skin", label: "Dry or itchy skin"),
        .init(id: "hair_thinning", label: "Hair thinning"),
        .init(id: "weight_change", label: "Weight change"),
        .init(id: "dizziness", label: "Dizziness"),
        .init(id: "tinnitus", label: "Tinnitus"),
    ]

    /// The daily check-in shows at most this many symptoms so it stays at about 30 seconds.
    public static let dailyLimit = 8
}

/// One day of the daily check-in.
public struct CheckIn: Codable, Equatable, Sendable {
    public var day: DayKey
    public var ratings: [String: Severity]
    public var impact: DailyImpact?
    public var bleeding: Bleeding
    public var factors: Set<Factor>
    public var note: String

    public init(
        day: DayKey,
        ratings: [String: Severity] = [:],
        impact: DailyImpact? = nil,
        bleeding: Bleeding = .none,
        factors: Set<Factor> = [],
        note: String = ""
    ) {
        self.day = day
        self.ratings = ratings
        self.impact = impact
        self.bleeding = bleeding
        self.factors = factors
        self.note = note
    }

    private enum CodingKeys: String, CodingKey { case day, ratings, impact, bleeding, factors, note }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        day = try c.decode(DayKey.self, forKey: .day)
        ratings = try c.decodeIfPresent([String: Severity].self, forKey: .ratings) ?? [:]
        impact = try c.decodeIfPresent(DailyImpact.self, forKey: .impact)
        bleeding = try c.decodeIfPresent(Bleeding.self, forKey: .bleeding) ?? .none
        factors = Set(try c.decodeIfPresent([Factor].self, forKey: .factors) ?? [])
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
    }

    /// Factors are written sorted so the same data always produces the same file (D5, byte for byte).
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(day, forKey: .day)
        try c.encode(ratings, forKey: .ratings)
        try c.encodeIfPresent(impact, forKey: .impact)
        try c.encode(bleeding, forKey: .bleeding)
        try c.encode(factors.map(\.rawValue).sorted().compactMap(Factor.init(rawValue:)), forKey: .factors)
        try c.encode(note, forKey: .note)
    }

    /// Sum of all ratings, used for the "darker means harder day" strip.
    public var burden: Int { ratings.values.reduce(0) { $0 + $1.rawValue } }
}

/// A single hot flush or night sweat logged with one tap.
public struct Episode: Codable, Equatable, Sendable, Identifiable {
    public enum Kind: String, Codable, Sendable { case hotFlush, nightSweat }
    public enum Source: String, Codable, Sendable { case app, widget, lockScreen, shortcut }

    public var id: UUID
    public var kind: Kind
    public var at: Date
    public var intensity: Severity
    public var source: Source

    public init(id: UUID = UUID(), kind: Kind, at: Date, intensity: Severity = .moderate, source: Source = .app) {
        self.id = id
        self.kind = kind
        self.at = at
        self.intensity = intensity
        self.source = source
    }
}

/// A medicine or supplement exactly as the user entered it. We never suggest names or doses.
public struct Medication: Codable, Equatable, Sendable, Identifiable {
    public enum Kind: String, Codable, Sendable { case prescribed, supplement, contraception }

    public var id: UUID
    public var name: String
    public var kind: Kind
    public var howTaken: String
    public var started: DayKey
    public var stopped: DayKey?

    public init(id: UUID = UUID(), name: String, kind: Kind, howTaken: String, started: DayKey, stopped: DayKey? = nil) {
        self.id = id
        self.name = name
        self.kind = kind
        self.howTaken = howTaken
        self.started = started
        self.stopped = stopped
    }
}

/// A fortnightly questionnaire. Eleven answers, each 0–4. Shown as a total with no interpretation.
public struct Questionnaire: Codable, Equatable, Sendable {
    public static let itemCount = 11
    public static let maxScore = 44

    public var day: DayKey
    public var answers: [Int]

    public init(day: DayKey, answers: [Int]) {
        self.day = day
        self.answers = answers
    }

    /// Nil until every item is answered with a value in 0...4.
    public var total: Int? {
        guard answers.count == Self.itemCount, answers.allSatisfy({ (0...4).contains($0) }) else { return nil }
        return answers.reduce(0, +)
    }
}
