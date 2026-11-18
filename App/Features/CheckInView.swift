import SwiftUI
import TidemarkCore

/// The 30-second daily check-in. Every tap is saved at once (D1).
struct CheckInView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let day: DayKey
    @State private var checkIn: CheckIn
    @State private var loaded = false
    @State private var saved = false

    init(day: DayKey) {
        self.day = day
        _checkIn = State(initialValue: CheckIn(day: day))
    }

    var body: some View {
        NavigationStack {
            if saved {
                CheckInSavedView(checkIn: checkIn) { dismiss() }
            } else {
                form
            }
        }
        .onAppear {
            guard !loaded else { return }
            if let existing = model.repository.checkIn(for: day) { checkIn = existing }
            loaded = true
        }
        .onChange(of: checkIn) { _, newValue in
            guard loaded else { return }
            model.repository.save(checkIn: newValue)
        }
    }

    private var form: some View {
        let ids = model.profile?.trackedSymptomIDs ?? []
        let visit = model.repository.currentVisit()
        return Page(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subtitle(visit: visit)).font(.subheadline).foregroundStyle(Theme.muted)
                    Text(day == .today ? String(localized: "Today") : day.short).font(.largeTitle.bold())
                }
                Spacer()
                Button("Same as yesterday") { copyYesterday() }
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 8)
            }

            ForEach(ids, id: \.self) { id in
                Card(spacing: 8, padding: 14) {
                    HStack {
                        Text(Symptom.label(for: id)).font(.body.weight(.semibold))
                        Spacer()
                        Text(checkIn.ratings[id]?.label ?? String(localized: "Not rated")).font(.footnote).foregroundStyle(Theme.muted)
                    }
                    SeverityPicker(value: rating(id))
                }
            }

            Card(spacing: 8, padding: 14) {
                Text("Did symptoms get in the way of your day?").font(.body.weight(.semibold))
                OptionRow(options: DailyImpact.allCases, selection: impact) { $0.shortLabel }
            }

            Card(spacing: 8, padding: 14) {
                Text("Bleeding today").font(.body.weight(.semibold))
                OptionRow(options: Bleeding.allCases, selection: $checkIn.bleeding) { $0.label }
            }

            Card(spacing: 8, padding: 14) {
                HStack {
                    Text("Anything else today?").font(.body.weight(.semibold))
                    Spacer()
                    Text("Optional").font(.footnote).foregroundStyle(Theme.muted)
                }
                FlowLayout {
                    ForEach(Factor.allCases, id: \.self) { factor in
                        Chip(title: factor.label, selected: checkIn.factors.contains(factor)) {
                            if checkIn.factors.contains(factor) { checkIn.factors.remove(factor) } else { checkIn.factors.insert(factor) }
                        }
                    }
                }
                Text("Tags help you spot what happens together. They show up in Patterns after 5 days.")
                    .font(.caption).foregroundStyle(Theme.muted)
            }

            Card(spacing: 8, padding: 14) {
                Text("Note for your doctor (optional)").font(.body.weight(.semibold))
                TextField("For example: woke at 3 and couldn't get back to sleep", text: $checkIn.note, axis: .vertical)
                    .lineLimit(2...5)
            }

            Button("Save check-in") {
                saved = true
                if UserDefaults.standard.bool(forKey: "healthWrite") {
                    let day = checkIn
                    Task { await model.health.write(day) }
                }
            }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(checkIn.ratings.isEmpty)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    private func subtitle(visit: Visit?) -> String {
        var parts = [day.short]
        if let started = model.repository.trackingStarted() { parts.append(String(localized: "Day \(started.days(until: day) + 1)")) }
        if let visit, visit.day >= day {
            parts.append(String(localized: "Appointment in \(day.days(until: visit.day)) days"))
        }
        return parts.joined(separator: " · ")
    }

    private func rating(_ id: String) -> Binding<Severity?> {
        Binding(get: { checkIn.ratings[id] }, set: { checkIn.ratings[id] = $0 })
    }

    private var impact: Binding<DailyImpact> {
        Binding(get: { checkIn.impact ?? .notAtAll }, set: { checkIn.impact = $0 })
    }

    private func copyYesterday() {
        guard let yesterday = model.repository.checkIn(for: day.adding(days: -1)) else { return }
        let tracked = Set(model.profile?.trackedSymptomIDs ?? [])
        checkIn.ratings = yesterday.ratings.filter { tracked.contains($0.key) }
    }
}

extension DailyImpact {
    var shortLabel: String {
        switch self {
        case .notAtAll: String(localized: "No", comment: "How much symptoms got in the way of the day")
        case .aLittle: String(localized: "A little", comment: "How much symptoms got in the way of the day")
        case .quiteABit: String(localized: "Quite a bit", comment: "How much symptoms got in the way of the day")
        case .aLot: String(localized: "A lot", comment: "How much symptoms got in the way of the day")
        }
    }
}

extension Bleeding {
    var label: String {
        switch self {
        case .none: String(localized: "None", comment: "Amount of bleeding")
        case .spotting: String(localized: "Spotting", comment: "Amount of bleeding")
        case .light: String(localized: "Light", comment: "Amount of bleeding")
        case .medium: String(localized: "Medium", comment: "Amount of bleeding")
        case .heavy: String(localized: "Heavy", comment: "Amount of bleeding")
        }
    }
}

/// After saving: compare with the last two weeks and show bleeding warnings. Describes, never diagnoses.
struct CheckInSavedView: View {
    @Environment(AppModel.self) private var model
    let checkIn: CheckIn
    let done: () -> Void
    @State private var addQuestion = false

    var body: some View {
        let history = model.repository.allCheckIns()
        let bleeding = Dictionary(history.map { ($0.day, $0.bleeding) }, uniquingKeysWith: { _, last in last })
        let flags = RedFlags.check(today: checkIn, cycle: CycleStats.summary(of: bleeding))
        let trends = checkIn.ratings.keys.sorted().compactMap { id in
            Comparison.trend(symptomID: id, today: checkIn, history: history).map { (id, $0) }
        }
        let visit = model.repository.currentVisit()

        Page(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            Text("Saved").font(.largeTitle.bold()).frame(maxWidth: .infinity)
            Text(savedLine(count: history.count, visit: visit))
                .foregroundStyle(Theme.secondary).multilineTextAlignment(.center).frame(maxWidth: .infinity)

            if !trends.isEmpty {
                Card {
                    Text("Compared with your last 2 weeks").font(.headline)
                    ForEach(trends, id: \.0) { item in
                        Text(verbatim: "\(Symptom.label(for: item.0)): \(item.1.label)").font(.subheadline)
                    }
                    Text("A pattern, not a verdict. Your doctor will see the same numbers.").font(.caption).foregroundStyle(Theme.muted)
                }
            }

            ForEach(flags, id: \.self) { flag in
                WarningCard(systemImage: "exclamationmark.triangle") {
                    Text(flag.message).font(.subheadline.weight(.semibold))
                }
            }

            Button("Done") {
                model.dataChanged()
                done()
            }
            .buttonStyle(PrimaryButtonStyle())
            Button("Add a question for your doctor") { addQuestion = true }
                .buttonStyle(OutlineButtonStyle())
        }
        .sheet(isPresented: $addQuestion) { NavigationStack { QuestionsView() } }
    }

    private func savedLine(count: Int, visit: Visit?) -> String {
        var line = String(localized: "\(count) check-ins so far.")
        if let visit, visit.day >= checkIn.day { line += " " + String(localized: "Your report for \(visit.day.short) is up to date.") }
        return line
    }
}
