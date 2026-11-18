import Foundation

/// One stored value with the time it was last changed on any device.
public struct Stamped<Value: Equatable & Sendable>: Equatable, Sendable {
    public var value: Value
    public var updatedAt: Date
    public var deviceID: String

    public init(_ value: Value, updatedAt: Date, deviceID: String) {
        self.value = value
        self.updatedAt = updatedAt
        self.deviceID = deviceID
    }
}

/// Requirement D8: when two devices edit the same day offline, each field keeps its newest value.
///
/// Storage keeps one row per field (one symptom rating, the day's bleeding, the note), so CloudKit
/// conflicts are per field already. Two devices can still create the same row at once; after an
/// import we collapse such duplicates with this rule. Ties break on device id so every device
/// picks the same winner.
public enum FieldMerge {
    public static func winner<Value: Equatable & Sendable>(_ candidates: [Stamped<Value>]) -> Stamped<Value>? {
        candidates.max { lhs, rhs in
            if lhs.updatedAt != rhs.updatedAt { return lhs.updatedAt < rhs.updatedAt }
            return lhs.deviceID < rhs.deviceID
        }
    }

    /// Collapses duplicate rows that share a key. Returns the winners and the losers to delete.
    public static func deduplicate<Key: Hashable, Value: Equatable & Sendable>(
        _ rows: [(key: Key, value: Stamped<Value>)]
    ) -> (keep: [Key: Stamped<Value>], discard: [(key: Key, value: Stamped<Value>)]) {
        var keep: [Key: Stamped<Value>] = [:]
        var discard: [(key: Key, value: Stamped<Value>)] = []
        for row in rows {
            guard let existing = keep[row.key] else {
                keep[row.key] = row.value
                continue
            }
            let best = winner([existing, row.value])!
            if best == row.value {
                discard.append((key: row.key, value: existing))
                keep[row.key] = row.value
            } else {
                discard.append(row)
            }
        }
        return (keep, discard)
    }
}

/// Requirement D7: deleted items stay recoverable for 30 days.
public enum RecentlyDeleted {
    public static let retentionDays = 30

    public static func isExpired(deletedAt: Date, now: Date) -> Bool {
        now.timeIntervalSince(deletedAt) > TimeInterval(retentionDays) * 86_400
    }

    public static func daysLeft(deletedAt: Date, now: Date) -> Int {
        let elapsed = Int(now.timeIntervalSince(deletedAt) / 86_400)
        return max(0, retentionDays - elapsed)
    }
}

/// Requirement D4: warn when there has been no successful backup for a day.
public enum BackupHealth: Equatable, Sendable {
    case ok(lastBackup: Date)
    case warning(Reason)

    public enum Reason: Equatable, Sendable {
        case iCloudSignedOut
        case iCloudFull
        case noBackupFor(hours: Int)
        case neverBackedUp
    }

    public static let warningAfterHours = 24

    public static func evaluate(signedIn: Bool, quotaExceeded: Bool, lastSuccess: Date?, now: Date) -> BackupHealth {
        if !signedIn { return .warning(.iCloudSignedOut) }
        if quotaExceeded { return .warning(.iCloudFull) }
        guard let last = lastSuccess else { return .warning(.neverBackedUp) }
        let hours = Int(now.timeIntervalSince(last) / 3_600)
        return hours >= warningAfterHours ? .warning(.noBackupFor(hours: hours)) : .ok(lastBackup: last)
    }
}
