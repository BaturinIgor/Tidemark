import Foundation

/// The report unlocks after a week of data, so the doctor never sees a one-day snapshot.
public enum ReportReadiness: Equatable, Sendable {
    case locked(checkInsSoFar: Int, needed: Int)
    case ready(checkIns: Int, questionnaires: Int)

    public static let minimumCheckIns = 7

    public static func evaluate(checkIns: Int, questionnaires: Int) -> ReportReadiness {
        checkIns < minimumCheckIns
            ? .locked(checkInsSoFar: checkIns, needed: minimumCheckIns)
            : .ready(checkIns: checkIns, questionnaires: questionnaires)
    }
}

/// Paper size follows the region: Letter in the US and Canada, A4 elsewhere.
public enum Region: String, Codable, CaseIterable, Sendable {
    case unitedStates = "US", unitedKingdom = "UK", canada = "CA", australia = "AU", europe = "EU", other = "OTHER"

    public var paper: Paper { self == .unitedStates || self == .canada ? .letter : .a4 }

    /// Words used on the report so it reads like local practice.
    public var doctorTerm: String { self == .unitedKingdom ? "GP" : "doctor" }
    public var hormoneTherapyTerm: String { self == .unitedKingdom ? "HRT" : "hormone therapy" }
}

public enum Paper: Sendable {
    case letter, a4

    /// Size in PostScript points.
    public var size: (width: Double, height: Double) {
        switch self {
        case .letter: (612, 792)
        case .a4: (595.28, 841.89)
        }
    }
}
