import SwiftUI
import TidemarkCore

struct TodayView: View {
    @Environment(AppModel.self) private var model
    @State private var refresh = 0
    @State private var showCheckIn = false
    @State private var showQuickLog = false

    private var today: DayKey { DayKey(Date()) }

    var body: some View {
        let checkIns = model.repository.allCheckIns()
        let todays = checkIns.last { $0.day == today }
        let flushesToday = model.repository.episodes().filter { DayKey($0.at) == today && $0.kind == .hotFlush }.count

        List {
            if case .warning(let reason) = model.backup.health, model.backup.isEnabled {
                BackupBanner(reason: reason)
            }

            Section {
                if let todays {
                    Text("Checked in").font(.headline)
                    ForEach(Array(todays.ratings.sorted { $0.value > $1.value }.prefix(3)), id: \.key) { pair in
                        Text("\(label(pair.key)) · \(pair.value.label)")
                    }
                    Button("Edit") { showCheckIn = true }
                } else {
                    Button("Start today's check-in") { showCheckIn = true }
                        .buttonStyle(.borderedProminent)
                }
            } header: { Text(today.description) }

            Section("Hot flushes today") {
                HStack {
                    Text("\(flushesToday)").font(.title.bold()).monospacedDigit()
                    Spacer()
                    Button("Log one", systemImage: "plus") { showQuickLog = true }
                        .buttonStyle(.bordered)
                }
            }

            Section("Last 7 days") {
                WeekStrip(checkIns: checkIns, ending: today)
            }
        }
        .navigationTitle("Today")
        .id(refresh)
        .sheet(isPresented: $showCheckIn, onDismiss: { refresh += 1 }) {
            CheckInView(day: today)
        }
        .sheet(isPresented: $showQuickLog, onDismiss: { refresh += 1 }) {
            QuickLogSheet().presentationDetents([.height(300)])
        }
    }

    private func label(_ id: String) -> String {
        Symptom.catalog.first { $0.id == id }?.label ?? id
    }
}

struct BackupBanner: View {
    let reason: BackupHealth.Reason

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text("Your data is safe on this iPhone. Export a copy until the backup works again.").font(.subheadline)
            }
        } icon: {
            Image(systemName: "exclamationmark.icloud")
        }
    }

    private var title: String {
        switch reason {
        case .iCloudSignedOut: "iCloud backup is off"
        case .iCloudFull: "Your iCloud is full"
        case .noBackupFor(let hours): "No backup for \(hours / 24) day(s)"
        case .neverBackedUp: "Not backed up yet"
        }
    }
}

struct WeekStrip: View {
    let checkIns: [CheckIn]
    let ending: DayKey

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { offset in
                let day = ending.adding(days: offset - 6)
                let burden = checkIns.first { $0.day == day }?.burden
                RoundedRectangle(cornerRadius: 8)
                    .fill(burden.map { Theme.fill(Severity(rawValue: min(3, $0 / 3)) ?? .none) } ?? Color.clear)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                    .frame(height: 36)
                    .accessibilityLabel("\(day.description): \(burden.map { "burden \($0)" } ?? "no check-in")")
            }
        }
    }
}

struct QuickLogSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var kind: Episode.Kind = .hotFlush
    @State private var intensity: Severity = .moderate

    var body: some View {
        VStack(spacing: 16) {
            Picker("Type", selection: $kind) {
                Text("Hot flush").tag(Episode.Kind.hotFlush)
                Text("Night sweat").tag(Episode.Kind.nightSweat)
            }
            .pickerStyle(.segmented)
            Picker("How strong", selection: $intensity) {
                ForEach([Severity.mild, .moderate, .severe], id: \.self) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            Button("Save, now") {
                model.repository.logEpisode(kind, intensity: intensity)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
