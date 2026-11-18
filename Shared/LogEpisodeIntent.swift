import AppIntents
import TidemarkCore
import WidgetKit

/// One tap from the widget, Lock Screen or Shortcuts logs a hot flush without opening the app.
struct LogHotFlushIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a hot flush"
    static let description = IntentDescription("Saves a hot flush with the current time.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = PersistenceController(mode: .widget)
        try EpisodeLogger.log(.hotFlush, source: .widget, in: store.newBackgroundContext())
        WidgetCenter.shared.reloadAllTimelines()
        return .result(dialog: "Hot flush saved")
    }
}

struct LogNightSweatIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a night sweat"
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        let store = PersistenceController(mode: .widget)
        try EpisodeLogger.log(.nightSweat, source: .widget, in: store.newBackgroundContext())
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
