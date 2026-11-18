import Charts
import SwiftUI
import TidemarkCore

struct HistoryView: View {
    @Environment(AppModel.self) private var model
    @State private var weeks = 8

    var body: some View {
        let today = DayKey(Date())
        let from = today.adding(days: -(weeks * 7) + 1)
        let checkIns = model.repository.allCheckIns(from: from, to: today)
        let ids = model.profile?.trackedSymptomIDs ?? []

        List {
            Picker("Period", selection: $weeks) {
                Text("4 weeks").tag(4)
                Text("8 weeks").tag(8)
                Text("12 weeks").tag(12)
            }
            .pickerStyle(.segmented)

            Section("Day by day") {
                Chart {
                    ForEach(checkIns, id: \.day) { checkIn in
                        ForEach(ids, id: \.self) { id in
                            if let severity = checkIn.ratings[id] {
                                RectangleMark(
                                    x: .value("Day", checkIn.day.referenceDate, unit: .day),
                                    y: .value("Symptom", label(id))
                                )
                                .foregroundStyle(Theme.fill(severity))
                            }
                        }
                        if checkIn.bleeding != .none {
                            RectangleMark(
                                x: .value("Day", checkIn.day.referenceDate, unit: .day),
                                y: .value("Symptom", "Bleeding")
                            )
                            .foregroundStyle(Theme.bleeding)
                        }
                    }
                }
                .frame(height: CGFloat(ids.count + 1) * 28)
                .accessibilityLabel("Heat map of symptoms over \(weeks) weeks")
            }

            Section("Questionnaire score") {
                ForEach(model.repository.questionnaires(), id: \.day) { q in
                    LabeledContent(q.day.description, value: q.total.map { "\($0) of \(Questionnaire.maxScore)" } ?? "Incomplete")
                }
                Text("Menopause Rating Scale, 0 to 44. Higher means more symptoms.").font(.footnote).foregroundStyle(.secondary)
            }

            Section {
                NavigationLink("Cycle") { CycleView() }
                NavigationLink("Patterns") { PatternsView() }
                NavigationLink("Medicines and supplements") { MedicationsView() }
                NavigationLink("Your week") { WeeklySummaryView() }
            }
        }
        .navigationTitle("History")
    }

    private func label(_ id: String) -> String { Symptom.catalog.first { $0.id == id }?.label ?? id }
}

struct CycleView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let checkIns = model.repository.allCheckIns()
        let summary = CycleStats.summary(of: Dictionary(checkIns.map { ($0.day, $0.bleeding) }, uniquingKeysWith: { _, b in b }))
        List {
            Section("Cycle lengths") {
                if summary.cycleLengths.isEmpty {
                    Text("Log bleeding in your check-in. Cycle lengths appear after two periods.")
                } else {
                    LabeledContent("Shortest", value: "\(summary.shortestCycle ?? 0) days")
                    LabeledContent("Longest", value: "\(summary.longestCycle ?? 0) days")
                    LabeledContent("Spotting days", value: "\(summary.spottingDays)")
                }
            }
            Section("Periods") {
                ForEach(summary.periods.reversed(), id: \.start) { period in
                    LabeledContent(period.start.description, value: "\(period.lengthInDays) days")
                }
            }
        }
        .navigationTitle("Cycle")
    }
}

struct PatternsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let patterns = PatternFinder.patterns(in: model.repository.allCheckIns(), symptomIDs: model.profile?.trackedSymptomIDs ?? [])
        List {
            Section {
                Text("Things that happened together in your log. This shows counts, not causes, and is not advice.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if patterns.isEmpty {
                Text("Tag factors in your check-in. Patterns show up after at least \(PatternFinder.minimumFactorDays) days with a tag.")
            }
            ForEach(patterns, id: \.self) { p in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(p.factor.label) \(p.nextDay ? "the day before" : "the same day")").font(.headline)
                    Text("\(label(p.symptomID)) was moderate or worse on \(p.withFactorHits) of \(p.withFactorDays) days with it, and on \(p.withoutFactorHits) of \(p.withoutFactorDays) other days.")
                }
            }
        }
        .navigationTitle("Patterns")
    }

    private func label(_ id: String) -> String { Symptom.catalog.first { $0.id == id }?.label ?? id }
}

struct MedicationsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        List {
            Section {
                Text("Shown on your report so your doctor sees everything you take. We never suggest medicines or doses.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(model.repository.medications()) { medication in
                NavigationLink {
                    TreatmentCheckView(medication: medication)
                } label: {
                    VStack(alignment: .leading) {
                        Text(medication.name).font(.headline)
                        Text("\(medication.howTaken) · since \(medication.started.description)").font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("Medicines")
    }
}

/// Before and after starting a medicine. Numbers only; whether it works is for the doctor to say.
struct TreatmentCheckView: View {
    @Environment(AppModel.self) private var model
    let medication: Medication

    var body: some View {
        let result = TreatmentCheck.compare(
            medication: medication,
            checkIns: model.repository.allCheckIns(),
            questionnaires: model.repository.questionnaires(),
            symptomIDs: model.profile?.trackedSymptomIDs ?? []
        )
        List {
            if !result.isReady {
                Text("Keep logging. The comparison needs \(TreatmentCheck.minimumDaysPerSide) days before and after \(medication.started.description).")
            }
            Section("Average, \(result.windowDays) days before and after") {
                ForEach(result.symptoms, id: \.symptomID) { w in
                    LabeledContent(Symptom.catalog.first { $0.id == w.symptomID }?.label ?? w.symptomID,
                                   value: "\(format(w.before)) → \(format(w.after))")
                }
                if let before = result.questionnaireBefore, let after = result.questionnaireAfter {
                    LabeledContent("Questionnaire", value: "\(before) → \(after)")
                }
            }
        }
        .navigationTitle(medication.name)
    }

    private func format(_ value: Double?) -> String { value.map { String(format: "%.1f", $0) } ?? "–" }
}

struct WeeklySummaryView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let summary = WeeklySummaryBuilder.build(weekEnding: DayKey(Date()), checkIns: model.repository.allCheckIns(), episodes: model.repository.episodes())
        List {
            LabeledContent("Check-ins", value: "\(summary.checkInCount) of 7")
            LabeledContent("Hot flushes and night sweats", value: "\(summary.episodeCount) (last week \(summary.previousEpisodeCount))")
            if let hardest = summary.hardestDay { LabeledContent("Hardest day", value: hardest.description) }
            if let easiest = summary.easiestDay { LabeledContent("Easiest day", value: easiest.description) }
        }
        .navigationTitle("Your week")
    }
}
