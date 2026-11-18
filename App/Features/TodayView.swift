import SwiftUI
import TidemarkCore

struct TodayView: View {
    @Environment(AppModel.self) private var model
    @State private var checkInDay: DayKey?
    @State private var showQuestionnaire = false
    @State private var quickLog: Episode.Kind?

    var body: some View {
        let _ = model.revision
        let today = DayKey.today
        let checkIns = model.repository.allCheckIns()
        let logged = Set(checkIns.map(\.day))
        let todays = checkIns.last { $0.day == today }
        let started = model.repository.trackingStarted() ?? today
        let dayNumber = started.days(until: today) + 1
        let missed = MissedDays.fillable(today: today, logged: logged, trackingStarted: started)
        let visit = model.repository.currentVisit(today: today)
        let questionnaireDue = !checkIns.isEmpty && Questionnaire.isDue(today: today, history: model.repository.questionnaires())

        Page {
            ScreenHeader(title: checkIns.isEmpty ? "Good evening" : "Today", subtitle: "\(today.short) · Day \(dayNumber)")

            if model.backup.isEnabled, case .warning(let reason) = model.backup.health {
                BackupBanner(reason: reason, checkIns: checkIns.count)
            }

            if let visit, visit.day < today {
                AfterVisitCard(visit: visit)
            }

            if checkIns.isEmpty {
                firstCheckInCard
            } else if let todays {
                loggedCard(todays)
            } else {
                Card {
                    Text("How was today?").font(.headline)
                    Button("Start today's check-in") { checkInDay = today }.buttonStyle(PrimaryButtonStyle())
                }
            }

            if !missed.isEmpty, !checkIns.isEmpty {
                MissedDaysCard(days: missed) { checkInDay = $0 }
            }

            QuickLogCard(today: today) { quickLog = $0 }

            if questionnaireDue {
                Card {
                    Text("Fortnightly questionnaire is due").font(.headline)
                    Text("11 questions, about 2 minutes. Doctors know this scale, so it goes at the top of your report.")
                        .font(.subheadline).foregroundStyle(Theme.secondary)
                    Button("Answer now") { showQuestionnaire = true }.buttonStyle(PrimaryButtonStyle(height: 46))
                }
            }

            if let visit, visit.day >= today {
                VisitCard(visit: visit, today: today, checkIns: checkIns.count)
            }

            if !checkIns.isEmpty {
                Card {
                    HStack {
                        Text("Last 7 days").font(.headline)
                        Spacer()
                        NavigationLink("Your week") { WeeklySummaryView() }.font(.subheadline.weight(.semibold))
                    }
                    WeekStrip(checkIns: checkIns, ending: today)
                    Text("Overall burden per day. Darker means a harder day.").font(.caption).foregroundStyle(Theme.muted)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $checkInDay) { day in CheckInView(day: day) }
        .sheet(isPresented: $showQuestionnaire) { QuestionnaireView() }
        .sheet(item: $quickLog) { kind in
            QuickLogSheet(kind: kind).presentationDetents([.height(380)])
        }
    }

    private var firstCheckInCard: some View {
        Card {
            Text("Your first check-in").font(.headline)
            Text("Rate how today felt for your \(model.profile?.trackedSymptomIDs.count ?? 0) symptoms. It takes about 30 seconds.")
                .font(.subheadline).foregroundStyle(Theme.secondary)
            Button("Start check-in") { checkInDay = .today }.buttonStyle(PrimaryButtonStyle())
            Text("Rate today only, not the worst day of the week. Missed a day? You can fill it in later.")
                .font(.caption).foregroundStyle(Theme.muted)
        }
    }

    private func loggedCard(_ checkIn: CheckIn) -> some View {
        let sorted = checkIn.ratings.filter { $0.value >= .moderate }.sorted { $0.value > $1.value }
        let mild = checkIn.ratings.filter { $0.value == .mild }.count
        return Card {
            HStack {
                Label("Checked in", systemImage: "checkmark.circle").font(.headline).foregroundStyle(Theme.ink)
                Spacer()
                Button("Edit") { checkInDay = checkIn.day }.font(.subheadline.weight(.semibold))
            }
            FlowLayout(spacing: 6) {
                ForEach(sorted, id: \.key) { pair in
                    SeverityTag(text: "\(Symptom.label(for: pair.key)) · \(pair.value.label)", severity: pair.value)
                }
                if mild > 0 { SeverityTag(text: String(localized: "+\(mild) mild"), severity: .mild) }
            }
        }
    }
}

extension DayKey: Identifiable {
    public var id: String { description }
}

extension Episode.Kind: Identifiable {
    public var id: String { rawValue }
}

struct SeverityTag: View {
    let text: String
    let severity: Severity
    var body: some View {
        Text(verbatim: text)
            .font(.footnote)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(Theme.onFill(severity))
            .background(Theme.fill(severity), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct BackupBanner: View {
    let reason: BackupHealth.Reason
    let checkIns: Int
    @State private var exportURL: URL?
    @Environment(AppModel.self) private var model

    var body: some View {
        WarningCard(systemImage: "exclamationmark.icloud") {
            Text(title).font(.headline)
            Text("Your \(checkIns) check-ins are safe on this iPhone, but they are not backed up. If you lose the phone, they are gone.")
                .font(.subheadline).foregroundStyle(Theme.secondary)
            HStack(spacing: 8) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
                .buttonStyle(PrimaryButtonStyle(height: 44))
                if let exportURL {
                    ShareLink("Share copy", item: exportURL).buttonStyle(OutlineButtonStyle(height: 44))
                } else {
                    Button("Export a copy") { exportURL = DataExport.makeFile(model: model) }
                        .buttonStyle(OutlineButtonStyle(height: 44))
                }
            }
        }
    }

    private var title: String {
        switch reason {
        case .iCloudSignedOut: String(localized: "iCloud backup is off")
        case .iCloudFull: String(localized: "Your iCloud is full")
        case .noBackupFor(let hours): String(localized: "No backup for \(max(1, hours / 24)) days")
        case .neverBackedUp: String(localized: "Not backed up yet")
        }
    }
}

struct MissedDaysCard: View {
    let days: [DayKey]
    let fill: (DayKey) -> Void
    @State private var dismissed = false

    var body: some View {
        if !dismissed {
            Card {
                Text("You missed \(days.count) days").font(.headline)
                Text("Fill them in while you remember. You can add up to \(MissedDays.maxDaysBack) days back, so the report stays honest.")
                    .font(.subheadline).foregroundStyle(Theme.secondary)
                ForEach(days) { day in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(day.short).font(.body.weight(.semibold))
                            Text("No check-in").font(.caption).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        Button("Fill in") { fill(day) }.buttonStyle(OutlineButtonStyle(height: 40)).frame(width: 96)
                    }
                }
                Button("Skip, they were ordinary days") { dismissed = true }
                    .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 40)
            }
        }
    }
}

struct QuickLogCard: View {
    @Environment(AppModel.self) private var model
    let today: DayKey
    let log: (Episode.Kind) -> Void

    var body: some View {
        let todays = model.repository.episodes().filter { DayKey($0.at) == today && $0.kind == .hotFlush }.sorted { $0.at < $1.at }
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hot flushes today").font(.headline)
                    if let last = todays.last {
                        Text("Last one at \(last.at.formatted(date: .omitted, time: .shortened))").font(.footnote).foregroundStyle(Theme.muted)
                    }
                }
                Spacer()
                Text("\(todays.count)").font(.largeTitle.bold()).monospacedDigit()
            }
            HStack(spacing: 8) {
                Button("+ Hot flush") { log(.hotFlush) }.buttonStyle(PrimaryButtonStyle(height: 46))
                Button("+ Night sweat") { log(.nightSweat) }.buttonStyle(OutlineButtonStyle(height: 46))
            }
        }
    }
}

struct VisitCard: View {
    @Environment(AppModel.self) private var model
    let visit: Visit
    let today: DayKey
    let checkIns: Int

    var body: some View {
        let days = today.days(until: visit.day)
        Card {
            HStack(alignment: .firstTextBaseline) {
                Text(days == 0 ? String(localized: "Appointment today") : String(localized: "Appointment in \(days) days")).font(.headline)
                Spacer()
                Text(verbatim: visit.clinician.isEmpty ? visit.day.short : "\(visit.clinician) · \(visit.day.short)")
                    .font(.footnote).foregroundStyle(Theme.muted)
            }
            switch ReportReadiness.evaluate(checkIns: checkIns, questionnaires: 0) {
            case .locked(let soFar, let needed):
                Text("\(soFar) of \(needed) check-ins. You can make a report after \(needed), but 14 shows your doctor a clear pattern.")
                    .font(.subheadline).foregroundStyle(Theme.secondary)
            case .ready(let count, _):
                Text("**Report ready:** \(count) check-ins, \(model.repository.questionnaires().count) questionnaires, \(model.repository.questions().count) questions saved.")
                    .font(.subheadline).foregroundStyle(Theme.secondary)
            }
        }
    }
}

struct AfterVisitCard: View {
    let visit: Visit
    @State private var open = false

    var body: some View {
        Card {
            Text("How did your visit on \(visit.day.short) go?").font(.headline)
            Text("A few taps. Your next report will show what changed after it.").font(.subheadline).foregroundStyle(Theme.secondary)
            Button("Add visit notes") { open = true }.buttonStyle(PrimaryButtonStyle(height: 46))
        }
        .sheet(isPresented: $open) { AfterVisitView(visit: visit) }
    }
}

struct WeekStrip: View {
    let checkIns: [CheckIn]
    let ending: DayKey

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { offset in
                let day = ending.adding(days: offset - 6)
                let level = checkIns.first { $0.day == day }.map(Self.level)
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(level.map(Theme.fill) ?? Color.clear)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
                        .frame(height: 36)
                    Text(String(day.referenceDate.formatted(Date.FormatStyle(timeZone: TimeZone(identifier: "UTC")!).weekday(.abbreviated)).prefix(2)))
                        .font(.caption).foregroundStyle(Theme.muted)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: "\(day.short): \(level?.label ?? String(localized: "no check-in"))"))
            }
        }
    }

    /// The day's hardest symptom sets its shade, so one severe symptom is never averaged away.
    static func level(_ checkIn: CheckIn) -> Severity {
        checkIn.ratings.values.max() ?? .none
    }
}

struct QuickLogSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let kind: Episode.Kind
    @State private var intensity: Severity = .moderate
    @State private var time = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(kind == .hotFlush ? "Hot flush" : "Night sweat").font(.title2.bold())
            Text("How strong was it?").font(.subheadline).foregroundStyle(Theme.secondary)
            OptionRow(options: [Severity.mild, .moderate, .severe], selection: $intensity) { $0.label }
            DatePicker("Time", selection: $time, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
            Button("Save") {
                model.repository.logEpisode(kind, intensity: intensity, at: time)
                model.dataChanged()
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
    }
}

/// Shared by Today and Settings.
enum DataExport {
    @MainActor
    static func makeFile(model: AppModel) -> URL? {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        guard let file = model.repository.exportFile(appVersion: version),
              let data = try? ExportCodec.encode(file) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Tidemark export \(DayKey.today).json")
        try? data.write(to: url, options: .atomic)
        return url
    }

    @MainActor
    static func makeCSV(model: AppModel) -> URL? {
        guard let file = model.repository.exportFile(appVersion: "") else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Tidemark export \(DayKey.today).csv")
        try? ExportCodec.csv(file).write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
