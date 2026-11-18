import AppIntents
import SwiftUI
import TidemarkCore
import WidgetKit

@main
struct TidemarkWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickLogWidget()
    }
}

struct QuickLogEntry: TimelineEntry {
    let date: Date
    let flushesToday: Int
}

struct QuickLogProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickLogEntry { QuickLogEntry(date: .now, flushesToday: 3) }

    func getSnapshot(in context: Context, completion: @escaping (QuickLogEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLogEntry>) -> Void) {
        // Refresh at midnight so the count resets with the day.
        let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
        completion(Timeline(entries: [entry()], policy: .after(midnight)))
    }

    private func entry() -> QuickLogEntry {
        let store = PersistenceController(mode: .widget)
        return QuickLogEntry(date: .now, flushesToday: EpisodeLogger.countToday(in: store.container.viewContext))
    }
}

/// Home Screen and Lock Screen: one tap logs a hot flush without opening the app.
struct QuickLogWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "QuickLog", provider: QuickLogProvider()) { entry in
            QuickLogWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Log a hot flush")
        .description("One tap saves a hot flush with the time.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

struct QuickLogWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuickLogEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            Button(intent: LogHotFlushIntent()) {
                VStack(spacing: 0) {
                    Image(systemName: "flame")
                    Text("\(entry.flushesToday)").font(.caption.bold())
                }
            }
            .buttonStyle(.plain)
        case .accessoryRectangular:
            Button(intent: LogHotFlushIntent()) {
                VStack(alignment: .leading) {
                    Text("Tap to log a hot flush").font(.headline)
                    Text("\(entry.flushesToday) today")
                }
            }
            .buttonStyle(.plain)
        default:
            VStack(alignment: .leading, spacing: 8) {
                Text("Hot flushes today").font(.caption)
                Text("\(entry.flushesToday)").font(.largeTitle.bold())
                Button(intent: LogHotFlushIntent()) {
                    Label("Log one", systemImage: "plus")
                }
            }
        }
    }
}
