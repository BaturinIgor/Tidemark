import Foundation

/// Spreadsheet export (Pro). One row per day, one column per symptom, so the file opens ready to chart.
/// Dates are ISO (yyyy-MM-dd) whatever the phone's language, ratings are numbers, and labels are in the
/// user's language. Quick logs and medicines go in their own files.
public enum CSVExport {
    public struct Files: Equatable, Sendable {
        public let days: String
        public let quickLogs: String
        public let medicines: String
    }

    public static func make(_ file: ExportFile, timeZone: TimeZone = .current) -> Files {
        Files(days: days(file), quickLogs: quickLogs(file, timeZone: timeZone), medicines: medicines(file))
    }

    /// Tracked symptoms first, in her order, then anything else she rated at some point.
    public static func symptomColumns(_ file: ExportFile) -> [String] {
        let tracked = file.profile.trackedSymptomIDs
        let rated = Set(file.checkIns.flatMap { $0.ratings.keys }).subtracting(tracked)
        return tracked + rated.sorted()
    }

    public static func days(_ file: ExportFile) -> String {
        let columns = symptomColumns(file)
        let names = Dictionary(file.profile.customSymptoms.map { ($0.id, $0.name) }, uniquingKeysWith: { _, last in last })
        let header = [L10n.text("Date")]
            + columns.map { names[$0] ?? Symptom.label(for: $0) }
            + [L10n.text("Impact on the day (0–3)"), L10n.text("Bleeding"), L10n.text("Factors"), L10n.text("Note")]
        var lines = [row(header)]
        for c in file.checkIns.sorted(by: { $0.day < $1.day }) {
            let ratings = columns.map { c.ratings[$0].map { String($0.rawValue) } ?? "" }
            let factors = c.factors.sorted { $0.rawValue < $1.rawValue }.map(\.label).joined(separator: "; ")
            lines.append(row([c.day.description] + ratings
                             + [c.impact.map { String($0.rawValue) } ?? "", bleedingLabel(c.bleeding), factors, c.note]))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    public static func quickLogs(_ file: ExportFile, timeZone: TimeZone = .current) -> String {
        var lines = [row([L10n.text("Date"), L10n.text("Time"), L10n.text("Type"), L10n.text("Intensity (1–3)")])]
        for e in file.episodes.sorted(by: { $0.at < $1.at }) {
            let parts = Calendar.gregorian(timeZone).dateComponents([.hour, .minute], from: e.at)
            let time = String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
            let kind = e.kind == .hotFlush ? L10n.text("Hot flush") : L10n.text("Night sweat")
            lines.append(row([DayKey(e.at, in: timeZone).description, time, kind, String(e.intensity.rawValue)]))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    public static func medicines(_ file: ExportFile) -> String {
        var lines = [row([L10n.text("Name"), L10n.text("Type"), L10n.text("How taken"), L10n.text("Started"), L10n.text("Stopped")])]
        for m in file.medications.sorted(by: { $0.started != $1.started ? $0.started < $1.started : $0.name < $1.name }) {
            let kind: String = switch m.kind {
            case .prescribed: L10n.text("Prescribed")
            case .supplement: L10n.text("Supplement")
            case .contraception: L10n.text("Contraception")
            }
            lines.append(row([m.name, kind, m.howTaken, m.started.description, m.stopped?.description ?? ""]))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func bleedingLabel(_ b: Bleeding) -> String {
        switch b {
        case .none: ""
        case .spotting: L10n.text("Spotting")
        case .light: L10n.text("Light")
        case .medium: L10n.text("Medium")
        case .heavy: L10n.text("Heavy")
        }
    }

    static func row(_ fields: [String]) -> String { fields.map(escape).joined(separator: ",") }

    /// RFC 4180 quoting. A field that starts like a formula gets a leading apostrophe, so a spreadsheet
    /// shows a note such as "=2+2" as text and never runs it.
    static func escape(_ raw: String) -> String {
        var field = raw
        if let first = field.first, "=+-@\t\r".contains(first) { field = "'" + field }
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" || $0 == ";" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

private extension Calendar {
    static func gregorian(_ timeZone: TimeZone) -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = timeZone
        return c
    }
}
