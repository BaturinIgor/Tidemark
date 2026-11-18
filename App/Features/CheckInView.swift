import SwiftUI
import TidemarkCore

/// The 30-second daily check-in. Every tap is saved at once (D1).
struct CheckInView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let day: DayKey
    @State private var checkIn: CheckIn
    @State private var saved = false

    init(day: DayKey) {
        self.day = day
        _checkIn = State(initialValue: CheckIn(day: day))
    }

    private var symptoms: [Symptom] {
        let ids = model.profile?.trackedSymptomIDs ?? []
        return ids.compactMap { id in Symptom.catalog.first { $0.id == id } }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button("Same as yesterday") { copyYesterday() }
                }
                Section("How was it today?") {
                    ForEach(symptoms) { symptom in
                        VStack(alignment: .leading) {
                            Text(symptom.label)
                            Picker(symptom.label, selection: rating(symptom.id)) {
                                ForEach(Severity.allCases, id: \.self) { Text($0.label).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                    }
                }
                Section("Did symptoms get in the way of your day?") {
                    Picker("Impact", selection: $checkIn.impact) {
                        Text("Not at all").tag(DailyImpact?.some(.notAtAll))
                        Text("A little").tag(DailyImpact?.some(.aLittle))
                        Text("Quite a bit").tag(DailyImpact?.some(.quiteABit))
                        Text("A lot").tag(DailyImpact?.some(.aLot))
                    }
                    .pickerStyle(.segmented)
                }
                Section("Bleeding today") {
                    Picker("Bleeding", selection: $checkIn.bleeding) {
                        Text("None").tag(Bleeding.none)
                        Text("Spotting").tag(Bleeding.spotting)
                        Text("Light").tag(Bleeding.light)
                        Text("Medium").tag(Bleeding.medium)
                        Text("Heavy").tag(Bleeding.heavy)
                    }
                    .pickerStyle(.segmented)
                }
                Section("Anything else today? Optional") {
                    FactorChips(selection: $checkIn.factors)
                }
                Section("Note for your doctor (optional)") {
                    TextField("For example: woke up 3 times", text: $checkIn.note, axis: .vertical)
                }
                if saved {
                    SavedSummary(checkIn: checkIn)
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(saved ? "Done" : "Save") {
                        if saved { dismiss() } else { persist(); saved = true }
                    }
                }
            }
            .onAppear { if let existing = model.repository.checkIn(for: day) { checkIn = existing } }
            .onChange(of: checkIn) { _, _ in persist() }
        }
    }

    private func rating(_ id: String) -> Binding<Severity> {
        Binding(get: { checkIn.ratings[id] ?? .none }, set: { checkIn.ratings[id] = $0 })
    }

    private func copyYesterday() {
        guard let yesterday = model.repository.checkIn(for: day.adding(days: -1)) else { return }
        checkIn.ratings = yesterday.ratings
    }

    private func persist() {
        model.repository.save(checkIn: checkIn)
    }
}

struct FactorChips: View {
    @Binding var selection: Set<Factor>

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], alignment: .leading) {
            ForEach(Factor.allCases, id: \.self) { factor in
                let on = selection.contains(factor)
                Button(factor.label) {
                    if on { selection.remove(factor) } else { selection.insert(factor) }
                }
                .buttonStyle(.bordered)
                .tint(on ? Theme.accent : .secondary)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

/// After saving: compare with the last two weeks and show bleeding warnings. Describes, never diagnoses.
struct SavedSummary: View {
    @Environment(AppModel.self) private var model
    let checkIn: CheckIn

    var body: some View {
        let history = model.repository.allCheckIns()
        let flags = RedFlags.check(today: checkIn, cycle: CycleStats.summary(of: bleedingMap(history)))
        Section("Compared with your last 2 weeks") {
            ForEach(checkIn.ratings.keys.sorted(), id: \.self) { id in
                if let trend = Comparison.trend(symptomID: id, today: checkIn, history: history) {
                    Text("\(Symptom.catalog.first { $0.id == id }?.label ?? id): \(trend.rawValue)")
                }
            }
            Text("A pattern, not a verdict. Your doctor will see the same numbers.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        ForEach(flags, id: \.self) { flag in
            Section { Label(flag.message, systemImage: "exclamationmark.triangle.fill").foregroundStyle(Theme.danger) }
        }
    }

    private func bleedingMap(_ history: [CheckIn]) -> [DayKey: Bleeding] {
        Dictionary(history.map { ($0.day, $0.bleeding) }, uniquingKeysWith: { _, last in last })
    }
}
