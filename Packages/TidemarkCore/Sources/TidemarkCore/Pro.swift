import Foundation

/// What the subscription adds. Logging, history up to 12 weeks, patterns, backup, JSON export and the
/// on-screen report stay free.
public enum ProFeature: String, CaseIterable, Sendable {
    case pdfReport = "pdf_report"
    case sinceLastVisit = "since_last_visit"
    case longHistory = "long_history"
    case csvExport = "csv_export"
    case moreSymptoms = "more_symptoms"
    case appearance = "appearance"
}

/// Accent palettes (Pro). Teal is the default and the only one without Pro.
public enum AppearanceTheme: String, CaseIterable, Sendable {
    case teal, plum, ocean, forest
}

/// Home Screen icons (Pro). `assetName` is the alternate icon set in the asset catalog; nil is the main icon.
public enum AppIconChoice: String, CaseIterable, Sendable {
    case standard, plum, ocean, forest, night

    public var assetName: String? {
        switch self {
        case .standard: nil
        case .plum: "AppIcon-Plum"
        case .ocean: "AppIcon-Ocean"
        case .forest: "AppIcon-Forest"
        case .night: "AppIcon-Night"
        }
    }

    public init(assetName: String?) {
        self = Self.allCases.first { $0.assetName == assetName } ?? .standard
    }
}

/// Periods offered in History and in the report. The two longest need Pro.
public enum HistoryRange: Int, CaseIterable, Sendable, Identifiable {
    case weeks4 = 4, weeks8 = 8, weeks12 = 12, months6 = 26, months12 = 52

    public var id: Int { rawValue }
    public var weeks: Int { rawValue }
    public var days: Int { rawValue * 7 }
    public var needsPro: Bool { rawValue > 12 }

    /// Months for the long ranges, nil for the week ranges.
    public var months: Int? {
        switch self {
        case .months6: 6
        case .months12: 12
        default: nil
        }
    }

    /// First day of the range that ends on `today` (inclusive).
    public func start(endingOn today: DayKey) -> DayKey { today.adding(days: -days + 1) }

    /// A stored value that is no longer allowed (Pro lapsed) falls back to the longest free range.
    public static func allowed(_ weeks: Int, isPro: Bool) -> HistoryRange {
        let range = HistoryRange(rawValue: weeks) ?? .weeks8
        return range.needsPro && !isPro ? .weeks12 : range
    }
}
