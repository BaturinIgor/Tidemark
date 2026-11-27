import SwiftUI
import TidemarkCore

/// Three steps, under two minutes: region and age, symptoms, visit date and reminder.
/// Before step 1 we look for a backup in iCloud, so a new iPhone never starts from zero (D3).
struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var step = DesignFlags.onboardingStep
    @State private var region: Region = .unitedKingdom
    @State private var age = ""
    @State private var noticed: Set<String> = []
    @State private var daily: [String] = []
    @State private var hasDate = true
    @State private var visitDate = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var clinician = ""
    /// Opt-in: off until she turns it on (Tidemark is a health app, so we never assume consent).
    @State private var shareUsage = false
    @State private var checkingBackup = true
    @State private var backupFound = false

    var body: some View {
        Group {
            if checkingBackup {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if backupFound {
                RestoreView(onRestore: {
                    UsageAnalytics.shared.log(.restoreChosen)
                    model.waitForRestore()
                }, onStartFresh: {
                    UsageAnalytics.shared.log(.startFreshChosen)
                    backupFound = false
                })
                .analyticsScreen(.restore)
            } else {
                steps
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .task {
            backupFound = DesignFlags.has("-design-backup-found") ? true : await model.backup.hasExistingBackup()
            checkingBackup = false
        }
        .onChange(of: step) { _, new in UsageAnalytics.shared.log(.onboardingStep, .step(new + 1)) }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule().fill(i <= step ? Theme.accent : Theme.border).frame(height: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .accessibilityLabel("Step \(step + 1) of 3")

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch step {
                    case 0: welcome.analyticsScreen(.onboardingWelcome)
                    case 1: symptoms.analyticsScreen(.onboardingSymptoms)
                    default: visit.analyticsScreen(.onboardingVisit)
                    }
                }
                .padding(24)
            }
            .keyboardDismissable()
        }
    }

    // MARK: Step 1

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("STEP 1 OF 3").font(.footnote.weight(.semibold)).foregroundStyle(Theme.muted)
                Text("Walk into your appointment with the full picture").font(.largeTitle.bold())
                Text("Log how you feel in 30 seconds a day. Before your visit, get a one-page summary your doctor can read in a minute.")
                    .foregroundStyle(Theme.secondary)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Where do you see your doctor?").font(.headline)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Region.allCases, id: \.self) { option in
                        let selected = option == region
                        Button { region = option } label: {
                            // Sized for the bold label, so selecting a region never re-wraps it.
                            ZStack(alignment: .leading) {
                                Text(option.displayName).font(.body.weight(.semibold)).hidden().accessibilityHidden(true)
                                Text(option.displayName).font(.body.weight(selected ? .semibold : .regular))
                            }
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                                .padding(.horizontal, 14)
                                .foregroundStyle(selected ? Theme.accentInk : Theme.ink)
                                .background(selected ? Theme.tint : Theme.card, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Theme.accent : Theme.chipBorder, lineWidth: selected ? 2 : 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                Text("We use your region for terms on the report (\(region.doctorTerm), \(region.hormoneTherapyTerm)).")
                    .font(.footnote).foregroundStyle(Theme.muted)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Your age").font(.headline)
                TextField("For example 46", text: $age)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 48)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.chipBorder))
            }
            Card {
                Label {
                    Text("**Your data stays yours.** Saved on this phone and backed up, encrypted, to your own iCloud. No account, no ads, no data sales.")
                        .font(.subheadline).foregroundStyle(Theme.secondary)
                } icon: {
                    Image(systemName: "lock").foregroundStyle(Theme.accent)
                }
            }
            Button("Continue") { step = 1 }.buttonStyle(PrimaryButtonStyle())
            Disclaimer(text: "This app keeps a record. It does not diagnose or give medical advice.")
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: Step 2

    private var symptoms: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("STEP 2 OF 3").font(.footnote.weight(.semibold)).foregroundStyle(Theme.muted)
                Text("What have you noticed in the last 3 months?").font(.title.bold())
                Text("All of these can come with hormonal change, even with regular periods. Many women never have hot flushes.")
                    .foregroundStyle(Theme.secondary)
            }
            ForEach(Symptom.groups, id: \.self) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(Symptom.groupLabel(group)).font(.headline)
                    FlowLayout {
                        ForEach(Symptom.catalog.filter { $0.group == group }) { symptom in
                            Chip(title: symptom.label, selected: noticed.contains(symptom.id)) {
                                toggle(symptom.id)
                            }
                        }
                    }
                }
            }
            Text(dailyHint).font(.footnote).foregroundStyle(Theme.muted)
            Button("Continue") { step = 2 }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(noticed.isEmpty)
        }
    }

    private var dailyHint: String {
        if noticed.count > Symptom.dailyLimit {
            return String(localized: "\(noticed.count) selected. Your first \(Symptom.dailyLimit) go in the daily check-in; change them anytime in Settings.")
        }
        return String(localized: "\(noticed.count) selected. You will rate these each day. Change them anytime.")
    }

    private func toggle(_ id: String) {
        if noticed.contains(id) {
            noticed.remove(id)
            daily.removeAll { $0 == id }
        } else {
            noticed.insert(id)
            daily.append(id)
        }
    }

    // MARK: Step 3

    private var visit: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("STEP 3 OF 3").font(.footnote.weight(.semibold)).foregroundStyle(Theme.muted)
                Text("Do you have an appointment booked?").font(.title.bold())
                Text("We will have your report ready the day before. Two weeks of check-ins is enough for a useful picture.")
                    .foregroundStyle(Theme.secondary)
            }
            Card {
                Toggle("Yes, I have a date", isOn: $hasDate).tint(Theme.accent)
                if hasDate {
                    DatePicker("Date", selection: $visitDate, in: Date()..., displayedComponents: .date)
                    TextField("Who you're seeing (optional)", text: $clinician)
                } else {
                    Text("Not yet. We will remind you to book in 2 weeks.").font(.subheadline).foregroundStyle(Theme.secondary)
                }
            }
            Card {
                Toggle(isOn: $shareUsage) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Help improve Tidemark").font(.headline)
                        Text("Share anonymous usage: which screens you open and which buttons you tap. Never your health data.")
                            .font(.subheadline).foregroundStyle(Theme.secondary)
                    }
                }
                .tint(Theme.accent)
                Text("You can change this anytime in Settings › Privacy.").font(.footnote).foregroundStyle(Theme.muted)
            }
            Card {
                Text("Daily reminder").font(.headline)
                Text("Most people check in before bed. It takes 30 seconds.").font(.subheadline).foregroundStyle(Theme.secondary)
            }
            Button("Turn on reminder and start") { finish(reminder: true) }.buttonStyle(PrimaryButtonStyle())
            Button("Skip reminder") { finish(reminder: false) }
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.accentInk)
                .frame(maxWidth: .infinity, minHeight: 44)
            Text("Next, iOS will ask to allow notifications.").font(.footnote).foregroundStyle(Theme.muted).frame(maxWidth: .infinity)
        }
    }

    private func finish(reminder: Bool) {
        let ordered = Array(daily.prefix(Symptom.dailyLimit))
        let profile = Profile(region: region, age: Int(age), trackedSymptomIDs: ordered)
        if hasDate {
            model.repository.save(visit: Visit(day: DayKey(visitDate), clinician: clinician.trimmingCharacters(in: .whitespaces)))
        }
        model.completeOnboarding(profile)
        UsageAnalytics.shared.setConsent(shareUsage)
        UsageAnalytics.shared.log(.onboardingCompleted, .count(ordered.count), .enabled(reminder))
        guard reminder else { return }
        Task {
            if await Reminders.requestPermission() {
                await Reminders.scheduleDaily(hour: 21, minute: 0)
                await Reminders.scheduleWeeklySummary()
            }
        }
    }
}

/// D3: a backup was found in iCloud. Restoring means waiting for CloudKit to bring the records in.
struct RestoreView: View {
    let onRestore: () -> Void
    let onStartFresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "icloud")
                .font(.system(size: 30))
                .foregroundStyle(Theme.accent)
                .frame(width: 64, height: 64)
                .background(Theme.tint, in: RoundedRectangle(cornerRadius: 20))
                .padding(.top, 40)
            Text("Welcome back").font(.largeTitle.bold())
            Text("We found your Tidemark backup in iCloud. Your check-ins, questionnaires, medicines and questions will come back to this iPhone.")
                .foregroundStyle(Theme.secondary)
            Spacer()
            Button("Restore my data", action: onRestore).buttonStyle(PrimaryButtonStyle())
            Button("Start fresh instead", action: onStartFresh)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.accentInk)
                .frame(maxWidth: .infinity, minHeight: 44)
            Text("Starting fresh keeps the backup in iCloud. You can restore it later from Settings.")
                .font(.caption).foregroundStyle(Theme.muted).multilineTextAlignment(.center).frame(maxWidth: .infinity)
        }
        .padding(24)
    }
}

extension Region {
    var displayName: String {
        switch self {
        case .unitedStates: String(localized: "United States")
        case .unitedKingdom: String(localized: "United Kingdom")
        case .canada: String(localized: "Canada")
        case .australia: String(localized: "Australia")
        case .europe: String(localized: "Europe")
        case .other: String(localized: "Other")
        }
    }
}
