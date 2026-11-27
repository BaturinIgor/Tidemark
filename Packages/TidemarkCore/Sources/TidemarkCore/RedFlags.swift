import Foundation

/// Bleeding patterns that should not wait for the appointment.
///
/// Wording is fixed and reviewed; the app never says what the cause might be.
public enum RedFlag: String, Sendable, Equatable {
    case heavyBleeding
    case bleedingAfterTwelveMonths

    /// The prompt in the user's region terms: UK users are pointed to their GP.
    public func message(region: Region) -> String {
        let gp = region == .unitedKingdom
        return switch self {
        case .heavyBleeding:
            gp ? L10n.text("Heavy bleeding shouldn't wait for your appointment. Contact your GP now.")
               : L10n.text("Heavy bleeding shouldn't wait for your appointment. Contact your doctor now.")
        case .bleedingAfterTwelveMonths:
            gp ? L10n.text("Bleeding after 12 months without a period shouldn't wait for your appointment. Contact your GP now.")
               : L10n.text("Bleeding after 12 months without a period shouldn't wait for your appointment. Contact your doctor now.")
        }
    }
}

public enum RedFlags {
    public static func check(today: CheckIn, cycle: CycleSummary) -> [RedFlag] {
        var flags: [RedFlag] = []
        if today.bleeding == .heavy { flags.append(.heavyBleeding) }
        if today.bleeding != .none,
           let previous = cycle.periods.last(where: { $0.end < today.day }),
           previous.end.days(until: today.day) >= 365 {
            flags.append(.bleedingAfterTwelveMonths)
        }
        return flags
    }
}
