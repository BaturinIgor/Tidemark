import SwiftUI
import TidemarkCore

/// Three steps, under two minutes: region and age, symptoms, visit date. Checks for a backup first (D3).
struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var step = 0
    @State private var region: Region = .unitedKingdom
    @State private var age = 46
    @State private var selected: Set<String> = ["waking_at_night", "fatigue", "brain_fog", "night_sweats"]
    @State private var visitDate = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var backupFound = false

    var body: some View {
        NavigationStack {
            Form {
                if backupFound {
                    Section {
                        Text("We found your data in iCloud. It will appear in a moment; you don't need to set up again.")
                    }
                }
                switch step {
                case 0:
                    Section("Where do you see your doctor?") {
                        Picker("Region", selection: $region) {
                            ForEach(Region.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        Stepper("Age: \(age)", value: $age, in: 30...70)
                    }
                    Section {
                        Label("Saved on this iPhone and backed up, encrypted, to your own iCloud. No account, no ads, no data sales.", systemImage: "lock")
                    }
                case 1:
                    Section("What have you noticed? Up to \(Symptom.dailyLimit) go in your daily check-in.") {
                        ForEach(Symptom.catalog) { symptom in
                            Toggle(symptom.label, isOn: binding(for: symptom.id))
                                .disabled(!selected.contains(symptom.id) && selected.count >= Symptom.dailyLimit)
                        }
                    }
                default:
                    Section("When is your appointment?") {
                        DatePicker("Visit", selection: $visitDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Step \(step + 1) of 3")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button(step < 2 ? "Continue" : "Start tracking") {
                        if step < 2 { step += 1 } else { finish() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(step == 1 && selected.isEmpty)
                }
            }
            .task { backupFound = await model.backup.hasExistingBackup() }
        }
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding(
            get: { selected.contains(id) },
            set: { on in if on { selected.insert(id) } else { selected.remove(id) } }
        )
    }

    private func finish() {
        let ordered = Symptom.catalog.map(\.id).filter(selected.contains)
        model.completeOnboarding(Profile(region: region, age: age, trackedSymptomIDs: ordered))
        Task {
            if await Reminders.requestPermission() {
                await Reminders.scheduleDaily(hour: 21, minute: 0)
                await Reminders.scheduleWeeklySummary()
            }
        }
    }
}
