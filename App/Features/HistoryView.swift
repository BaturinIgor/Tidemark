import Charts
import SwiftUI
import TidemarkCore

struct HistoryView: View {
    @Environment(AppModel.self) private var model
    @State private var range: HistoryRange = .weeks8
    @State private var paywall: ProFeature?

    var body: some View {
        let _ = model.revision
        let today = DayKey.today
        let from = HistoryRange.allowed(range.weeks, isPro: model.isPro).start(endingOn: today)
        let checkIns = model.repository.allCheckIns(from: from, to: today)
        let ids = model.profile?.trackedSymptomIDs ?? []
        let questionnaires = model.repository.questionnaires().filter { $0.total != nil }
        let medications = model.repository.medications()
        let visits = model.repository.visits().filter { $0.takenSeriously != nil }

        Page {
            ScreenHeader(title: "History")
            RangePicker(selection: $range, isPro: model.isPro) {
                UsageAnalytics.shared.log(.proFeatureTapped, .feature(.longHistory))
                paywall = .longHistory
            }

            Card {
                Text("Day by day").font(.headline)
                if checkIns.isEmpty {
                    Text("Your check-ins will appear here.").foregroundStyle(Theme.muted)
                } else {
                    HeatMap(checkIns: checkIns, symptomIDs: ids, from: from, to: today)
                }
            }

            Card {
                Text("Questionnaire score").font(.headline)
                if questionnaires.isEmpty {
                    Text("Answer the questionnaire every 2 weeks to see it change.").foregroundStyle(Theme.muted)
                } else {
                    Chart(questionnaires.suffix(6), id: \.day) { q in
                        BarMark(x: .value("Date", q.day.short), y: .value("Score", q.total ?? 0))
                            .foregroundStyle(Theme.accent)
                            .annotation(position: .top) { Text("\(q.total ?? 0)").font(.caption.bold()) }
                    }
                    .chartYScale(domain: 0...Questionnaire.maxScore)
                    .chartYAxis(.hidden)
                    .frame(height: 120)
                }
                Text("Menopause Rating Scale, 0 to 44. Higher means more symptoms.").font(.caption).foregroundStyle(Theme.muted)
            }

            Card(spacing: 0, padding: 0) {
                NavRow(title: String(localized: "Cycle"), detail: nil) { CycleView().analyticsScreen(.cycle) }
                NavRow(title: String(localized: "Patterns"), detail: nil) { PatternsView().analyticsScreen(.patterns) }
                NavRow(title: String(localized: "Medicines and supplements"), detail: String(localized: "\(medications.filter { $0.stopped == nil }.count) active")) { MedicationsView().analyticsScreen(.medicines) }
                NavRow(title: String(localized: "Visit notes"), detail: visits.isEmpty ? String(localized: "None yet") : visits.count.formatted()) { VisitNotesView().analyticsScreen(.visitNotes) }
                NavRow(title: String(localized: "Your week"), detail: nil, last: true) { WeeklySummaryView().analyticsScreen(.weeklySummary) }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $paywall) { PaywallView(feature: $0) }
        .analyticsScreen(.history)
    }
}

struct NavRow<Destination: View>: View {
    let title: String
    let detail: String?
    var last = false
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: destination) {
                HStack {
                    Text(verbatim: title).foregroundStyle(Theme.ink)
                    Spacer()
                    if let detail { Text(verbatim: detail).font(.subheadline).foregroundStyle(Theme.muted) }
                    Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Theme.muted)
                }
                .frame(minHeight: 50)
                .padding(.horizontal, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if !last { Divider().padding(.leading, 14) }
        }
    }
}

/// Symptoms by day with bleeding underneath. Blank means not logged.
struct HeatMap: View {
    let checkIns: [CheckIn]
    let symptomIDs: [String]
    let from: DayKey
    let to: DayKey

    var body: some View {
        let byDay = Dictionary(checkIns.map { ($0.day, $0) }, uniquingKeysWith: { _, last in last })
        let count = from.days(until: to) + 1
        VStack(alignment: .leading, spacing: 6) {
            ForEach(symptomIDs + ["bleeding"], id: \.self) { id in
                VStack(alignment: .leading, spacing: 2) {
                    Text(id == "bleeding" ? String(localized: "Bleeding") : Symptom.label(for: id)).font(.caption).foregroundStyle(Theme.secondary)
                    if count <= 84 {
                        HStack(spacing: 1) {
                            ForEach(0..<count, id: \.self) { offset in
                                let day = from.adding(days: offset)
                                Rectangle()
                                    .fill(color(for: id, checkIn: byDay[day]))
                                    .frame(height: 12)
                            }
                        }
                    } else {
                        // 6 and 12 months (Pro): too many days for one view each, so draw them.
                        Canvas { context, size in
                            let width = size.width / CGFloat(count)
                            for offset in 0..<count {
                                let rect = CGRect(x: CGFloat(offset) * width, y: 0, width: max(width, 0.5), height: size.height)
                                context.fill(Path(rect), with: .color(color(for: id, checkIn: byDay[from.adding(days: offset)])))
                            }
                        }
                        .frame(height: 12)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(summary(for: id))
            }
            HStack {
                Text(from.short)
                Spacer()
                Text(to.short)
            }
            .font(.caption2).foregroundStyle(Theme.muted)
        }
    }

    private func color(for id: String, checkIn: CheckIn?) -> Color {
        guard let checkIn else { return Color.clear }
        if id == "bleeding" {
            switch checkIn.bleeding {
            case .none: return Theme.fill(.none)
            case .spotting, .light: return Theme.bleedingLight
            case .medium, .heavy: return Theme.bleeding
            }
        }
        return checkIn.ratings[id].map(Theme.fill) ?? Color.clear
    }

    private func summary(for id: String) -> String {
        if id == "bleeding" {
            return String(localized: "Bleeding on \(checkIns.filter { $0.bleeding != Bleeding.none }.count) days")
        }
        let rated = checkIns.compactMap { $0.ratings[id] }
        return String(localized: "\(Symptom.label(for: id)): moderate or severe on \(rated.filter { $0 >= .moderate }.count) of \(rated.count) days")
    }
}

struct CycleView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let checkIns = model.repository.allCheckIns()
        let summary = CycleStats.summary(of: Dictionary(checkIns.map { ($0.day, $0.bleeding) }, uniquingKeysWith: { _, b in b }))
        Page {
            ScreenHeader(title: "Cycle")
            if let last = summary.periods.last {
                Card {
                    Text("Last period started \(last.start.short)").font(.headline)
                    Text("\(last.start.days(until: .today)) days ago · \(last.lengthInDays) days long").font(.subheadline).foregroundStyle(Theme.secondary)
                }
            } else {
                Card {
                    Text("No period logged yet").font(.headline)
                    Text("Log bleeding in your daily check-in. Cycle lengths appear after two periods.").font(.subheadline).foregroundStyle(Theme.secondary)
                }
            }
            MonthCalendar(month: .today, bleeding: Dictionary(checkIns.map { ($0.day, $0.bleeding) }, uniquingKeysWith: { _, b in b }))
            if !summary.cycleLengths.isEmpty {
                Card {
                    Text("Cycle lengths").font(.headline)
                    HStack(spacing: 8) {
                        ForEach(Array(summary.cycleLengths.suffix(3).enumerated()), id: \.offset) { pair in
                            VStack {
                                Text("\(pair.element)").font(.title2.bold())
                                Text("days").font(.caption).foregroundStyle(Theme.muted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    if let spread = summary.spread {
                        Text("\(spread) days between shortest and longest. Goes in the Cycle section of your report.")
                            .font(.subheadline).foregroundStyle(Theme.secondary)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MonthCalendar: View {
    static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    let month: DayKey
    let bleeding: [DayKey: Bleeding]

    /// Monday-first single-letter weekday names in the user's language.
    static var weekdayInitials: [String] {
        let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols // Sunday first
        return Array(symbols[1...]) + [symbols[0]]
    }

    var body: some View {
        let first = DayKey(year: month.year, month: month.month, day: 1)
        let next = first.adding(days: 32)
        let daysInMonth = first.days(until: DayKey(year: next.year, month: next.month, day: 1))
        // Monday-first grid: weekday of the 1st, 0 = Monday.
        let lead = (Self.utcCalendar.component(.weekday, from: first.referenceDate) + 5) % 7
        let spotting = bleeding.filter { $0.key.year == month.year && $0.key.month == month.month && $0.value == .spotting }.count

        Card {
            HStack {
                Text(first.referenceDate.formatted(Date.FormatStyle(timeZone: TimeZone(identifier: "UTC")!).month(.wide))).font(.headline)
                Spacer()
                Text("\(spotting) spotting days").font(.footnote).foregroundStyle(Theme.muted)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(Self.weekdayInitials.indices, id: \.self) { i in
                    Text(verbatim: Self.weekdayInitials[i]).font(.caption2.weight(.semibold)).foregroundStyle(Theme.muted)
                }
                ForEach(0..<lead, id: \.self) { _ in Color.clear.frame(height: 32) }
                ForEach(1...daysInMonth, id: \.self) { d in
                    let day = DayKey(year: month.year, month: month.month, day: d)
                    let flow = bleeding[day] ?? Bleeding.none
                    VStack(spacing: 2) {
                        Text("\(d)").font(.subheadline.weight(day == .today ? .bold : .regular))
                        Circle().fill(flow == .spotting ? Theme.bleeding : Color.clear).frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity, minHeight: 32)
                    .foregroundStyle(flow.countsAsPeriod ? Color.white : (day > .today ? Theme.muted : Theme.ink))
                    .background(flow.countsAsPeriod ? (flow == .light ? Theme.bleedingLight : Theme.bleeding) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(day == .today ? Theme.ink : Color.clear, lineWidth: 2))
                    .accessibilityLabel("\(day.short), \(flow.label)")
                }
            }
        }
    }
}

struct PatternsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let checkIns = model.repository.allCheckIns()
        let patterns = PatternFinder.patterns(in: checkIns, symptomIDs: model.profile?.trackedSymptomIDs ?? [])
        Page {
            ScreenHeader(title: "Patterns")
            Text("What happened together in your \(checkIns.count) check-ins. Counts, not causes, and not advice.")
                .foregroundStyle(Theme.secondary)
            if patterns.isEmpty {
                Card {
                    Text("Nothing to show yet").font(.headline)
                    Text("Tag factors in your check-in. Patterns show up after at least \(PatternFinder.minimumFactorDays) days with a tag.")
                        .font(.subheadline).foregroundStyle(Theme.secondary)
                }
            }
            ForEach(patterns, id: \.self) { p in
                Card(spacing: 8) {
                    Text(verbatim: "\(p.factor.label.uppercased(with: .current)) · \((p.nextDay ? String(localized: "The day before") : String(localized: "The same day")).uppercased(with: .current))")
                        .font(.caption.weight(.semibold)).foregroundStyle(Theme.muted)
                    Text("\(Symptom.label(for: p.symptomID)) was moderate or worse").font(.headline)
                    RateBar(label: String(localized: "With \(Locale.current.language.languageCode == .english ? p.factor.label.lowercased() : p.factor.label)"), hits: p.withFactorHits, days: p.withFactorDays, color: Theme.accent)
                    RateBar(label: String(localized: "Other days"), hits: p.withoutFactorHits, days: p.withoutFactorDays, color: Theme.muted)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RateBar: View {
    let label: String
    let hits: Int
    let days: Int
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Text(verbatim: label).font(.footnote).frame(width: 100, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.line)
                    Capsule().fill(color).frame(width: geo.size.width * CGFloat(hits) / CGFloat(max(days, 1)))
                }
            }
            .frame(height: 10)
            Text("\(hits) of \(days)").font(.footnote.weight(.semibold)).monospacedDigit().fixedSize()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: label + ": " + String(localized: "\(hits) of \(days) days")))
    }
}

struct MedicationsView: View {
    @Environment(AppModel.self) private var model
    @State private var adding = false

    var body: some View {
        let _ = model.revision
        let all = model.repository.medications()
        Page {
            ScreenHeader(title: "Medicines and supplements")
            Text("Shown on your report so your doctor sees everything you take. We never suggest medicines or doses.")
                .foregroundStyle(Theme.secondary)
            section("Taking now", all.filter { $0.stopped == nil })
            section("Stopped", all.filter { $0.stopped != nil })
            Button("Add") { adding = true }.buttonStyle(PrimaryButtonStyle())
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $adding) { AddMedicationView().analyticsScreen(.addMedicine) }
    }

    @ViewBuilder
    private func section(_ title: LocalizedStringKey, _ items: [Medication]) -> some View {
        if !items.isEmpty {
            SectionLabel(text: title)
            Card(spacing: 0, padding: 0) {
                ForEach(items) { m in
                    NavRow(title: m.name, detail: m.stopped.map { String(localized: "Stopped \($0.short)") } ?? String(localized: "since \(m.started.short)"), last: m.id == items.last?.id) {
                        TreatmentCheckView(medication: m).analyticsScreen(.medicineDetail)
                    }
                }
            }
        }
    }
}

struct AddMedicationView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var kind: Medication.Kind = .prescribed
    @State private var name = ""
    @State private var howTaken = ""
    @State private var started = Date()

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $kind) {
                    Text("Prescribed").tag(Medication.Kind.prescribed)
                    Text("Supplement").tag(Medication.Kind.supplement)
                    Text("Contraception").tag(Medication.Kind.contraception)
                }
                .pickerStyle(.segmented)
                TextField("Name", text: $name)
                TextField("How you take it, as your doctor or the label says", text: $howTaken, axis: .vertical)
                DatePicker("Started", selection: $started, in: ...Date(), displayedComponents: .date)
            }
            .navigationTitle("Add medicine")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDismissable()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        model.repository.save(medication: Medication(name: name, kind: kind, howTaken: howTaken, started: DayKey(started)))
                        UsageAnalytics.shared.log(.medicineSaved)
                        model.dataChanged()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

/// Before and after starting a medicine. Numbers only; whether it works is for the doctor to say.
struct TreatmentCheckView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let medication: Medication

    var body: some View {
        let result = TreatmentCheck.compare(
            medication: medication,
            checkIns: model.repository.allCheckIns(),
            questionnaires: model.repository.questionnaires(),
            symptomIDs: model.profile?.trackedSymptomIDs ?? []
        )
        Page {
            ScreenHeader(verbatim: medication.name)
            Text("Started \(medication.started.short). Average of your daily ratings, \(result.windowDays / 7) weeks before and after. 0 is none, 3 is severe.")
                .foregroundStyle(Theme.secondary)
            if !result.isReady {
                Card {
                    Text("Keep logging").font(.headline)
                    Text("The comparison needs \(TreatmentCheck.minimumDaysPerSide) check-ins before and after the start date.")
                        .font(.subheadline).foregroundStyle(Theme.secondary)
                }
            }
            Card(spacing: 0, padding: 0) {
                HStack {
                    Text("Symptom")
                    Spacer()
                    Text("Before").frame(width: 56)
                    Text("After").frame(width: 56)
                }
                .font(.caption.weight(.semibold)).foregroundStyle(Theme.muted)
                .padding(.horizontal, 14).padding(.vertical, 10)
                ForEach(result.symptoms, id: \.symptomID) { w in
                    Divider()
                    HStack {
                        Text(Symptom.label(for: w.symptomID))
                        Spacer()
                        ValueCell(value: w.before)
                        ValueCell(value: w.after)
                    }
                    .padding(.horizontal, 14).frame(minHeight: 50)
                }
                if let before = result.questionnaireBefore, let after = result.questionnaireAfter {
                    Divider()
                    HStack {
                        Text("Questionnaire").fontWeight(.semibold)
                        Spacer()
                        Text("\(before) → \(after) of \(Questionnaire.maxScore)").fontWeight(.semibold)
                    }
                    .padding(.horizontal, 14).frame(minHeight: 50)
                }
            }
            Text("Your doctor will weigh these numbers. The app does not say whether a treatment works.")
                .font(.footnote).foregroundStyle(Theme.muted)
            if medication.stopped == nil {
                Button("I stopped taking this") {
                    model.repository.stop(medication: medication, on: .today)
                    model.dataChanged()
                    dismiss()
                }
                .buttonStyle(OutlineButtonStyle())
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ValueCell: View {
    let value: Double?
    var body: some View {
        let level = value.map { Severity(rawValue: min(3, Int($0.rounded()))) ?? Severity.none } ?? Severity.none
        Text(verbatim: value.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "–")
            .font(.subheadline.weight(.semibold))
            .frame(width: 48, height: 30)
            .foregroundStyle(Theme.onFill(level))
            .background(Theme.fill(level), in: RoundedRectangle(cornerRadius: 8))
            .padding(.leading, 8)
    }
}

struct VisitNotesView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let visits = model.repository.visits().filter { $0.takenSeriously != nil }.reversed()
        Page {
            ScreenHeader(title: "Visit notes")
            if visits.isEmpty {
                Text("After each appointment, Today asks how it went. Your notes appear here.").foregroundStyle(Theme.secondary)
            }
            ForEach(Array(visits)) { visit in
                Card {
                    Text(verbatim: visit.clinician.isEmpty ? String(localized: "Visit · \(visit.day.short)") : "\(visit.clinician) · \(visit.day.short)").font(.headline)
                    if !visit.decisions.isEmpty {
                        Text(visit.decisions.map(\.label).sorted().joined(separator: ", ")).font(.subheadline)
                    }
                    if !visit.outcome.isEmpty { Text(visit.outcome).foregroundStyle(Theme.secondary) }
                    if let follow = visit.followUp { Text("Follow-up \(follow.short)").font(.footnote).foregroundStyle(Theme.muted) }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WeeklySummaryView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let checkIns = model.repository.allCheckIns()
        let episodes = model.repository.episodes()
        let today = DayKey.today
        let summary = WeeklySummaryBuilder.build(weekEnding: today, checkIns: checkIns, episodes: episodes)
        let flushes = episodes.filter { $0.kind == .hotFlush }
        let sweats = episodes.filter { $0.kind == .nightSweat }
        let thisWeek = today.adding(days: -6)...today
        let lastWeek = today.adding(days: -13)...today.adding(days: -7)
        let count: ([Episode], ClosedRange<DayKey>) -> Int = { list, range in list.filter { range.contains(DayKey($0.at)) }.count }

        Page {
            ScreenHeader(title: "Your week", subtitle: "\(today.adding(days: -6).short) – \(today.short)")
            Card {
                Text("How the days felt").font(.headline)
                WeekStrip(checkIns: checkIns, ending: today)
                if let hard = summary.hardestDay, let easy = summary.easiestDay, hard != easy {
                    Text("Darker means a harder day. Hardest: \(hard.short). Easiest: \(easy.short).")
                        .font(.subheadline).foregroundStyle(Theme.secondary)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                Stat(value: String(localized: "\(summary.checkInCount) of 7"), title: String(localized: "Check-ins"), detail: nil)
                Stat(value: count(flushes, thisWeek).formatted(), title: String(localized: "Hot flushes"), detail: String(localized: "Last week \(count(flushes, lastWeek))"))
                Stat(value: count(sweats, thisWeek).formatted(), title: String(localized: "Night sweats"), detail: String(localized: "Last week \(count(sweats, lastWeek))"))
                if let visit = model.repository.currentVisit(), visit.day >= today {
                    Stat(value: String(localized: "\(today.days(until: visit.day)) days"), title: String(localized: "To your visit"), detail: visit.day.short)
                }
            }
            Text("A pattern, not a verdict.").font(.caption).foregroundStyle(Theme.muted)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct Stat: View {
    let value: String
    let title: String
    let detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: value).font(.title2.bold())
            Text(verbatim: title).font(.subheadline.weight(.semibold))
            if let detail { Text(detail).font(.caption).foregroundStyle(Theme.muted) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border))
    }
}
