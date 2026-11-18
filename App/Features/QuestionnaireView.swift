import SwiftUI
import TidemarkCore

/// The fortnightly questionnaire: one question per screen, five answers, a score with no interpretation.
struct QuestionnaireView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var answers = Array(repeating: -1, count: Questionnaire.itemCount)
    @State private var finished: Questionnaire?

    var body: some View {
        NavigationStack {
            Group {
                if let finished { result(finished) } else { question }
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar {
                if finished == nil {
                    ToolbarItem(placement: .cancellationAction) { Button("Later") { dismiss() } }
                    ToolbarItem(placement: .principal) {
                        Text("\(index + 1) of \(Questionnaire.itemCount)").font(.subheadline).foregroundStyle(Theme.muted)
                    }
                }
            }
        }
    }

    private var question: some View {
        let item = Questionnaire.items[index]
        return VStack(alignment: .leading, spacing: 16) {
            ProgressView(value: Double(index), total: Double(Questionnaire.itemCount)).tint(Theme.accent)
            Text("Over the last 2 weeks").font(.subheadline).foregroundStyle(Theme.muted)
            Text(item.title).font(.title.bold())
            Text(item.hint).foregroundStyle(Theme.secondary)
            VStack(spacing: 8) {
                ForEach(Array(Questionnaire.answerLabels.enumerated()), id: \.offset) { pair in
                    let value = pair.offset
                    let label = pair.element
                    let selected = answers[index] == value
                    Button {
                        answers[index] = value
                        advance()
                    } label: {
                        Text(label)
                            .font(.body.weight(selected ? .bold : .regular))
                            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                            .padding(.horizontal, 16)
                            .foregroundStyle(Theme.ink)
                            .background(selected ? Theme.tint : Theme.card, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Theme.accentInk : Theme.chipBorder, lineWidth: selected ? 2 : 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            if index > 0 {
                Button("Back") { index -= 1 }.font(.subheadline.weight(.semibold))
            }
            Spacer()
        }
        .padding(24)
    }

    private func advance() {
        if index < Questionnaire.itemCount - 1 {
            withAnimation { index += 1 }
            return
        }
        let result = Questionnaire(day: .today, answers: answers)
        guard result.total != nil else {
            index = answers.firstIndex(of: -1) ?? 0
            return
        }
        model.repository.save(questionnaire: result)
        model.dataChanged()
        finished = result
    }

    private func result(_ q: Questionnaire) -> some View {
        let previous = model.repository.questionnaires().filter { $0.day < q.day }.last?.total
        return VStack(alignment: .leading, spacing: 16) {
            Text("Thank you").font(.largeTitle.bold()).padding(.top, 40)
            Card {
                Text("Score").font(.subheadline).foregroundStyle(Theme.muted)
                Text("\(q.total ?? 0) of \(Questionnaire.maxScore)").font(.largeTitle.bold())
                if let previous { Text("Last time: \(previous).").foregroundStyle(Theme.secondary) }
                if let next = Questionnaire.nextDue(after: [q]) {
                    Text("Next questionnaire in 2 weeks, on \(next.short).").foregroundStyle(Theme.secondary)
                }
            }
            Text("The score is for your doctor to interpret. It is not a diagnosis.").font(.footnote).foregroundStyle(Theme.muted)
            Spacer()
            Button("Back to today") { dismiss() }.buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
    }
}

/// Top 3 questions for the appointment, plus prompts other women often ask.
struct QuestionsView: View {
    @Environment(AppModel.self) private var model
    @State private var draft = ""

    var body: some View {
        let _ = model.revision
        let questions = model.repository.questions()
        let texts = Set(questions.map(\.text))
        let suggestions = DoctorQuestion.suggestions(for: model.profile?.region ?? .unitedKingdom).filter { !texts.contains($0) }

        Page {
            ScreenHeader(title: "Your top \(max(3, questions.count)) questions")
            Text("Appointments are short. Put the most important first, and ask it at the start.")
                .foregroundStyle(Theme.secondary)

            Card(spacing: 0, padding: 0) {
                ForEach(Array(questions.enumerated()), id: \.element.id) { pair in
                    let offset = pair.offset
                    let question = pair.element
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(offset + 1)")
                            .font(.subheadline.bold())
                            .frame(width: 28, height: 28)
                            .foregroundStyle(Theme.onAccent)
                            .background(Theme.accent, in: Circle())
                        Text(question.text).frame(maxWidth: .infinity, alignment: .leading)
                        Menu {
                            if offset > 0 { Button("Move up") { move(questions, from: offset, to: offset - 1) } }
                            if offset < questions.count - 1 { Button("Move down") { move(questions, from: offset, to: offset + 1) } }
                            Button("Remove", role: .destructive) { model.repository.delete(question: question); model.dataChanged() }
                        } label: {
                            Image(systemName: "ellipsis").frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Options for question \(offset + 1)")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    if offset < questions.count - 1 { Divider() }
                }
                if questions.isEmpty {
                    Text("No questions yet. Add your own or pick from the list below.")
                        .foregroundStyle(Theme.muted).padding(14)
                }
            }

            Card(spacing: 8, padding: 14) {
                TextField("Write your own", text: $draft, axis: .vertical).lineLimit(1...4)
                Button("Add question") { add(draft); draft = "" }
                    .buttonStyle(OutlineButtonStyle(height: 44))
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if !suggestions.isEmpty {
                SectionLabel(text: "Questions other women often ask")
                ForEach(suggestions, id: \.self) { text in
                    Button { add(text) } label: {
                        HStack(alignment: .top) {
                            Image(systemName: "plus").foregroundStyle(Theme.accent)
                            Text(text).foregroundStyle(Theme.ink).multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(14)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Questions")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func add(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let next = (model.repository.questions().map(\.rank).max() ?? 0) + 1
        model.repository.save(question: DoctorQuestion(text: trimmed, rank: next))
        model.dataChanged()
    }

    private func move(_ questions: [DoctorQuestion], from: Int, to: Int) {
        var reordered = questions
        reordered.swapAt(from, to)
        for (offset, question) in reordered.enumerated() {
            var updated = question
            updated.rank = offset + 1
            model.repository.save(question: updated)
        }
        model.dataChanged()
    }
}

/// After the appointment: how it went, what was decided, follow-up date.
struct AfterVisitView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State var visit: Visit
    @State private var hasFollowUp = false
    @State private var followUp = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var addMedicine = false

    var body: some View {
        NavigationStack {
            Page {
                ScreenHeader(title: "How did it go?", subtitle: visit.clinician.isEmpty ? String(localized: "Visit · \(visit.day.short)") : String(localized: "Visit with \(visit.clinician) · \(visit.day.short)"))

                Card {
                    Text("Did you feel taken seriously?").font(.headline)
                    OptionRow(options: Visit.Feeling.allCases, selection: feeling) { $0.label }
                    if visit.takenSeriously == .no || visit.takenSeriously == .partly {
                        Text("You can ask for a second opinion. Keep checking in and take an updated report to another \(model.profile?.region.doctorTerm ?? "doctor") or a menopause clinic.")
                            .font(.subheadline).foregroundStyle(Theme.secondary)
                    }
                }

                Card {
                    Text("What was decided?").font(.headline)
                    FlowLayout {
                        ForEach(Visit.Decision.allCases, id: \.self) { decision in
                            Chip(title: decision.label, selected: visit.decisions.contains(decision)) {
                                if visit.decisions.contains(decision) { visit.decisions.remove(decision) } else { visit.decisions.insert(decision) }
                            }
                        }
                    }
                }

                Card {
                    Text("What the doctor said").font(.headline)
                    TextField("In your words", text: $visit.outcome, axis: .vertical).lineLimit(2...6)
                }

                Card {
                    Toggle("Follow-up appointment", isOn: $hasFollowUp).tint(Theme.accent)
                    if hasFollowUp {
                        DatePicker("Date", selection: $followUp, in: Date()..., displayedComponents: .date)
                    }
                    Text("We will mark this visit on your charts so the next report shows before and after.")
                        .font(.caption).foregroundStyle(Theme.muted)
                }

                Button("Save") { save(); dismiss() }.buttonStyle(PrimaryButtonStyle())
                if visit.decisions.contains(.startedTreatment) {
                    Button("Save and add new medicine") { save(); addMedicine = true }.buttonStyle(OutlineButtonStyle())
                }
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .sheet(isPresented: $addMedicine, onDismiss: { dismiss() }) { AddMedicationView() }
        }
    }

    private var feeling: Binding<Visit.Feeling> {
        Binding(get: { visit.takenSeriously ?? .yes }, set: { visit.takenSeriously = $0 })
    }

    private func save() {
        if visit.takenSeriously == nil { visit.takenSeriously = .yes }
        if hasFollowUp {
            let next = DayKey(followUp)
            visit.followUp = next
            model.repository.save(visit: Visit(day: next, clinician: visit.clinician))
        }
        model.repository.save(visit: visit)
        model.dataChanged()
    }
}

extension Visit.Feeling {
    var label: String {
        switch self {
        case .yes: String(localized: "Yes", comment: "Did you feel taken seriously")
        case .partly: String(localized: "Partly", comment: "Did you feel taken seriously")
        case .no: String(localized: "No", comment: "Did you feel taken seriously")
        }
    }
}
