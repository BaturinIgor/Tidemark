import SwiftUI
import TidemarkCore
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var exportURL: URL?
    @State private var importing = false
    @State private var confirmDelete = false
    @State private var healthWrite = UserDefaults.standard.bool(forKey: "healthWrite")

    var body: some View {
        @Bindable var lock = model.lock
        List {
            Section("Your data") {
                Label("Stored on this iPhone and in your own iCloud, encrypted. We never see it. No ads, no data sales.", systemImage: "lock")
                    .font(.footnote)
                LabeledContent("Encrypted iCloud backup", value: backupText)
                Toggle("Lock with Face ID", isOn: $lock.isEnabled)
                Toggle("Save symptoms to Apple Health", isOn: $healthWrite)
                    .onChange(of: healthWrite) { _, on in
                        UserDefaults.standard.set(on, forKey: "healthWrite")
                        if on { Task { _ = await model.health.requestAccess(write: true) } }
                    }
                Button("Export all data") { exportURL = makeExport() }
                if let exportURL { ShareLink("Share export file", item: exportURL) }
                Button("Import from file") { importing = true }
                NavigationLink("Recently deleted") { RecentlyDeletedView() }
                Button("Delete all data", role: .destructive) { confirmDelete = true }
            }
            Section {
                Text("This app records what you report. It does not diagnose or give medical advice.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            guard case .success(let url) = result, url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            if let data = try? Data(contentsOf: url), let file = try? ExportCodec.decode(data) {
                model.repository.importFile(file)
            }
        }
        .confirmationDialog("Delete all your data?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Export a copy first") { exportURL = makeExport() }
            Button("Delete everything", role: .destructive) {
                for checkIn in model.repository.allCheckIns() { model.repository.delete(day: checkIn.day) }
            }
        } message: {
            Text("Check-ins go to Recently deleted for 30 days, on this iPhone and in your backup.")
        }
    }

    private var backupText: String {
        switch model.backup.health {
        case .ok(let date): "Last backup \(date.formatted(date: .abbreviated, time: .shortened))"
        case .warning: "Needs attention"
        }
    }

    private func makeExport() -> URL? {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        guard let file = model.repository.exportFile(appVersion: version),
              let data = try? ExportCodec.encode(file) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Tidemark export \(DayKey(Date())).json")
        try? data.write(to: url, options: .atomic)
        return url
    }
}

struct RecentlyDeletedView: View {
    @Environment(AppModel.self) private var model
    @State private var refresh = 0

    var body: some View {
        List {
            ForEach(model.repository.recentlyDeletedDays(), id: \.day) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.day.description)
                        Text("\(item.daysLeft) days left").font(.footnote).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Restore") { model.repository.restore(day: item.day); refresh += 1 }
                }
            }
        }
        .id(refresh)
        .navigationTitle("Recently deleted")
    }
}
