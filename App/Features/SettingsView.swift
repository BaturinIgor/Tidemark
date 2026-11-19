import StoreKit
import SwiftUI
import TidemarkCore
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("reminderEnabled") private var reminderEnabled = true
    @AppStorage("reminderMinutes") private var reminderMinutes = 21 * 60
    @State private var exportURL: URL?
    @State private var csvURL: URL?
    @State private var importing = false
    @State private var importPreview: ImportPreview?
    @State private var importError: String?
    @State private var confirmDelete = false
    @State private var showPaywall = false
    @State private var manageSubscription = false

    var body: some View {
        @Bindable var lock = model.lock
        let _ = model.revision
        let profile = model.profile ?? Profile(region: .unitedKingdom, age: nil, trackedSymptomIDs: [])
        let visit = model.repository.currentVisit()

        Form {
            Section("Tracking") {
                NavigationLink {
                    SymptomsEditorView()
                } label: {
                    LabeledContent("My symptoms", value: "\(profile.trackedSymptomIDs.count) of \(Symptom.dailyLimit)")
                }
                Toggle("Daily reminder", isOn: $reminderEnabled)
                    .onChange(of: reminderEnabled) { _, _ in rescheduleReminder() }
                if reminderEnabled {
                    DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                }
                NavigationLink {
                    AppointmentView()
                } label: {
                    LabeledContent("Next appointment", value: visit.map { $0.day >= .today ? $0.day.short : String(localized: "Add") } ?? String(localized: "Add"))
                }
                Picker("Region", selection: Binding(
                    get: { profile.region },
                    set: { region in var p = profile; p.region = region; model.update(profile: p) }
                )) {
                    ForEach(Region.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
            }

            Section {
                LabeledContent("iCloud backup", value: backupText)
                Toggle("Lock with Face ID", isOn: $lock.isEnabled)
                NavigationLink("Apple Health") { HealthSettingsView() }
                Button("Export all data (JSON)") { exportURL = DataExport.makeFile(model: model) }
                if let exportURL { ShareLink("Share JSON file", item: exportURL) }
                Button("Export as spreadsheet (CSV)") { csvURL = DataExport.makeCSV(model: model) }
                if let csvURL { ShareLink("Share CSV file", item: csvURL) }
                Button("Import from a Tidemark file") { importing = true }
                NavigationLink("Recently deleted") { RecentlyDeletedView() }
                Button("Delete all data", role: .destructive) { confirmDelete = true }
            } header: {
                Text("Your data")
            } footer: {
                Text("Stored on this iPhone and in your own iCloud, encrypted. We never see it. No ads, no data sales.")
            }

            Section("Report subscription") {
                if model.subscription.isSubscribed {
                    LabeledContent("Status", value: String(localized: "Active"))
                    Button("Manage subscription") { manageSubscription = true }
                } else {
                    LabeledContent("Status", value: String(localized: "Free"))
                    Button("See report plans") { showPaywall = true }
                }
                Button("Restore purchase") { Task { await model.subscription.restore() } }
            }

            Section {
                Disclaimer()
                Link("Privacy Policy", destination: Links.privacy)
                Link("Terms of Use", destination: Links.terms)
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .tint(Theme.accent)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .manageSubscriptionsSheet(isPresented: $manageSubscription)
        .sheet(item: $importPreview) { preview in ImportPreviewView(preview: preview) }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            importError = nil
            guard case .success(let url) = result else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let file = try ExportCodec.decode(Data(contentsOf: url))
                importPreview = ImportPreview(file: file, repository: model.repository)
            } catch {
                importError = "This file couldn't be read. Choose a file exported from Tidemark (.json)."
            }
        }
        .designAlert("importFailed") { importError = "This file couldn't be read. Choose a file exported from Tidemark (.json)." }
        .designAlert("deleteAll") { confirmDelete = true }
        .alert("Import failed", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "")
        }
        .confirmationDialog("Delete all your data?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Export a copy first") { exportURL = DataExport.makeFile(model: model) }
            Button("Delete everything", role: .destructive) {
                let stamp = model.repository.deleteAll()
                UserDefaults.standard.set(stamp, forKey: "bulkDeletedAt")
                model.dataChanged()
            }
        } message: {
            Text("Everything moves to Recently deleted for \(RecentlyDeleted.retentionDays) days, on this iPhone and in your backup. You can bring it back from there.")
        }
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: { Calendar.current.date(bySettingHour: reminderMinutes / 60, minute: reminderMinutes % 60, second: 0, of: Date()) ?? Date() },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                reminderMinutes = (parts.hour ?? 21) * 60 + (parts.minute ?? 0)
                rescheduleReminder()
            }
        )
    }

    private func rescheduleReminder() {
        let enabled = reminderEnabled, minutes = reminderMinutes
        Task {
            if enabled, await Reminders.requestPermission() {
                await Reminders.scheduleDaily(hour: minutes / 60, minute: minutes % 60)
            } else {
                Reminders.cancelDaily()
            }
        }
    }

    private var backupText: String {
        guard model.backup.isEnabled else { return String(localized: "Not available") }
        switch model.backup.health {
        case .ok(let date): return String(localized: "Backed up \(date.formatted(.relative(presentation: .named)))")
        case .warning(.iCloudSignedOut): return String(localized: "Off: not signed in to iCloud")
        case .warning(.iCloudFull): return String(localized: "Paused: iCloud is full")
        case .warning(.neverBackedUp): return String(localized: "Waiting for first backup")
        case .warning(.noBackupFor(let hours)): return String(localized: "Last backup \(hours / 24) days ago")
        }
    }
}

// MARK: My symptoms

struct SymptomsEditorView: View {
    @Environment(AppModel.self) private var model
    @State private var selected: [String] = []
    @State private var loaded = false

    var body: some View {
        Page {
            ScreenHeader(title: "My symptoms")
            Text("Up to \(Symptom.dailyLimit) in the daily check-in. Removing one keeps everything you logged for it.")
                .foregroundStyle(Theme.secondary)
            Text("\(selected.count) of \(Symptom.dailyLimit) chosen").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.accentInk)
            ForEach(Symptom.groups, id: \.self) { group in
                SectionLabel(text: Symptom.groupLabel(group))
                FlowLayout {
                    ForEach(Symptom.catalog.filter { $0.group == group }) { symptom in
                        let isOn = selected.contains(symptom.id)
                        Chip(title: symptom.label, selected: isOn) { toggle(symptom.id) }
                            .disabled(!isOn && selected.count >= Symptom.dailyLimit)
                            .opacity(!isOn && selected.count >= Symptom.dailyLimit ? 0.5 : 1)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !loaded else { return }
            selected = model.profile?.trackedSymptomIDs ?? []
            loaded = true
        }
    }

    private func toggle(_ id: String) {
        if let index = selected.firstIndex(of: id) {
            guard selected.count > 1 else { return }
            selected.remove(at: index)
        } else if selected.count < Symptom.dailyLimit {
            selected.append(id)
        }
        guard var profile = model.profile else { return }
        profile.trackedSymptomIDs = selected
        model.update(profile: profile)
    }
}

// MARK: Appointment

struct AppointmentView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var date = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var clinician = ""
    @State private var existing: Visit?

    var body: some View {
        Form {
            Section {
                DatePicker("Date", selection: $date, in: Date()..., displayedComponents: .date)
                TextField("Who you're seeing (optional)", text: $clinician)
            } footer: {
                Text("The day before, Tidemark reminds you to check your report. Nothing is shared with the practice.")
            }
            Section {
                Button("Save") {
                    var visit = existing ?? Visit(day: DayKey(date))
                    visit.day = DayKey(date)
                    visit.clinician = clinician.trimmingCharacters(in: .whitespacesAndNewlines)
                    if visit.reason.isEmpty, let draft = UserDefaults.standard.string(forKey: "report.reasonDraft") {
                        visit.reason = draft
                        UserDefaults.standard.removeObject(forKey: "report.reasonDraft")
                    }
                    model.repository.save(visit: visit)
                    model.dataChanged()
                    dismiss()
                }
            }
        }
        .navigationTitle("Next appointment")
        .onAppear {
            guard existing == nil, let visit = model.repository.visits().first(where: { $0.day >= .today }) else { return }
            existing = visit
            date = visit.day.referenceDate
            clinician = visit.clinician
        }
    }
}

// MARK: Apple Health

struct HealthSettingsView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("healthWrite") private var writeOn = false

    var body: some View {
        Form {
            if !model.health.isAvailable {
                Section { Text("Apple Health isn't available on this device.") }
            } else {
                Section {
                    Toggle("Save symptoms to Health", isOn: $writeOn)
                        .onChange(of: writeOn) { _, on in if on { Task { _ = await model.health.requestAccess(write: true) } } }
                } footer: {
                    Text("Each check-in adds your ratings to Health. Editing a day replaces what Tidemark wrote for it.")
                }
                Section {
                    Text("To take back access, open the Health app › your profile › Apps › Tidemark.")
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
            }
        }
        .navigationTitle("Apple Health")
        .tint(Theme.accent)
    }
}

// MARK: Import

/// What an import would add. Import never overwrites anything already on this iPhone.
struct ImportPreview: Identifiable {
    let id = UUID()
    let file: ExportFile
    let newDays: Int
    let existingDays: Int
    let newOther: Int

    @MainActor
    init(file: ExportFile, repository: Repository) {
        self.file = file
        let known = Set(repository.allCheckIns().map(\.day))
        newDays = file.checkIns.filter { !known.contains($0.day) }.count
        existingDays = file.checkIns.count - newDays
        let ids = Set(repository.episodes().map(\.id))
        let meds = Set(repository.medications().map(\.id))
        newOther = file.episodes.filter { !ids.contains($0.id) }.count + file.medications.filter { !meds.contains($0.id) }.count
    }
}

struct ImportPreviewView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let preview: ImportPreview

    var body: some View {
        NavigationStack {
            Page {
                ScreenHeader(title: "Import data")
                Card {
                    Text("File exported \(preview.file.exportedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.subheadline).foregroundStyle(Theme.muted)
                    Text("\(preview.newDays) new days will be added").font(.headline)
                    if preview.existingDays > 0 {
                        Text("\(preview.existingDays) days are already on this iPhone and stay as they are.")
                    }
                    if preview.newOther > 0 {
                        Text("Also \(preview.newOther) quick logs and medicines.")
                    }
                }
                Text("Nothing on this iPhone is overwritten or deleted.").foregroundStyle(Theme.secondary)
                Button("Add to my data") {
                    model.repository.importFile(preview.file)
                    model.dataChanged()
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(preview.newDays == 0 && preview.newOther == 0 && preview.file.questions.isEmpty)
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}

// MARK: Recently deleted

struct RecentlyDeletedView: View {
    @Environment(AppModel.self) private var model
    @State private var bulk = UserDefaults.standard.object(forKey: "bulkDeletedAt") as? Date

    var body: some View {
        let _ = model.revision
        let days = model.repository.recentlyDeletedDays()
        List {
            if let bulk, !RecentlyDeleted.isExpired(deletedAt: bulk, now: Date()) {
                Section {
                    Button("Restore everything deleted on \(bulk.formatted(date: .abbreviated, time: .shortened))") {
                        model.repository.restoreAll(deletedAt: bulk)
                        UserDefaults.standard.removeObject(forKey: "bulkDeletedAt")
                        self.bulk = nil
                        model.dataChanged()
                    }
                } footer: {
                    Text("\(RecentlyDeleted.daysLeft(deletedAt: bulk, now: Date())) days left")
                }
            }
            Section {
                if days.isEmpty {
                    Text("Nothing here. Deleted days stay for \(RecentlyDeleted.retentionDays) days.").foregroundStyle(Theme.muted)
                }
                ForEach(days, id: \.day) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.day.medium)
                            Text("\(item.daysLeft) days left").font(.footnote).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        Button("Restore") {
                            model.repository.restore(day: item.day)
                            model.dataChanged()
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .navigationTitle("Recently deleted")
        .tint(Theme.accent)
    }
}
