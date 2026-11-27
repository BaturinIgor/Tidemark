import CoreData
import SwiftUI
import TidemarkCore

/// Mockups of every screen, state and popup (design/<version>/screens).
/// With `-design -design-screen <id>` the app opens that screen straight away on made-up data in an
/// in-memory store; TidemarkUITests/DesignCatalogUITests takes the pictures. Debug builds only:
/// in release every value here is the app's normal default and the real store is never touched.
enum DesignFlags {
    static var active: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-design")
        #else
        return false
        #endif
    }

    static func has(_ flag: String) -> Bool {
        active && ProcessInfo.processInfo.arguments.contains(flag)
    }

    static func value(_ name: String) -> String? {
        guard active else { return nil }
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    /// First tab to show (0 Today, 1 History, 2 Report, 3 Settings).
    static var initialTab: Int { Int(value("-design-tab") ?? "") ?? 0 }
    /// First onboarding step (0, 1 or 2).
    static var onboardingStep: Int { Int(value("-design-step") ?? "") ?? 0 }
    /// The report subscription is on without a purchase.
    static var subscribed: Bool { has("-design-plus") }
    static var alert: String? { value("-design-alert") }
}

#if DEBUG
/// Made-up data for the mockups only. Plain strings, so nothing here reaches the string catalog.
enum DesignData {
    static let symptoms = ["trouble_falling_asleep", "waking_at_night", "fatigue", "night_sweats",
                           "hot_flushes", "brain_fog", "anxiety", "joint_aches"]

    @MainActor
    static func makeModel() -> AppModel {
        let model = AppModel(persistence: PersistenceController(mode: .inMemory))
        seed(model)
        model.profile = model.repository.profile()
        model.dataChanged()
        return model
    }

    @MainActor
    private static func seed(_ model: AppModel) {
        guard !DesignFlags.has("-design-onboarding") else { return }
        let repo = model.repository
        let today = DayKey.today
        let first = -69
        // `-design-region US` for US English screenshots (doctor, hot flashes, Letter paper).
        let region = DesignFlags.value("-design-region").flatMap(Region.init(rawValue:)) ?? .unitedKingdom
        let text = DesignSampleText.current(region: region)
        repo.save(profile: Profile(region: region, age: 49, trackedSymptomIDs: symptoms))
        // Tracking started ten weeks ago, so day numbers and missed days read as in real use.
        let context = model.persistence.container.viewContext
        if let row = try? context.fetch(CDProfile.fetchRequest()).first {
            row.trackingStarted = today.adding(days: first).description
            try? context.save()
        }
        guard !DesignFlags.has("-design-empty") else { return }

        for offset in first...0 {
            if offset == 0 && !DesignFlags.has("-design-checked-in") { continue }
            if offset == -2 || offset == -3 || offset == -45 { continue }
            let day = today.adding(days: offset)
            var ratings: [String: Severity] = [:]
            for (i, id) in symptoms.enumerated() {
                let raw = (abs(offset) * (i + 3) + i * 5) % 7
                var level = raw < 2 ? 0 : raw < 4 ? 1 : raw < 6 ? 2 : 3
                // Calmer weeks after the treatment started.
                if offset > -30 && level > 0 && (offset + i) % 2 == 0 { level -= 1 }
                ratings[id] = Severity(rawValue: level) ?? .none
            }
            let bleeding: Bleeding = switch offset {
            case -62, -61: .medium
            case -60, -59, -58: .light
            case -31: .heavy
            case -30, -29: .medium
            case -28, -27: .light
            case -12: .spotting
            default: .none
            }
            var factors: Set<Factor> = []
            if offset % 5 == 0 { factors.insert(.poorSleep) }
            if offset % 7 == 0 { factors.formUnion([.caffeine, .stress]) }
            let note = offset == -1 ? text.note : ""
            repo.save(checkIn: CheckIn(day: day, ratings: ratings, impact: DailyImpact(rawValue: (abs(offset) + 1) % 4),
                                       bleeding: bleeding, factors: factors, note: note))
        }
        // One day in Recently deleted.
        repo.save(checkIn: CheckIn(day: today.adding(days: -45), ratings: ["fatigue": .moderate, "hot_flushes": .mild]))
        repo.delete(day: today.adding(days: -45))

        let scores: [(Int, [Int])] = [
            (-70, [3, 3, 2, 2, 3, 3, 2, 2, 1, 2, 3]),
            (-56, [3, 2, 2, 2, 3, 2, 2, 2, 1, 2, 3]),
            (-42, [2, 2, 2, 2, 2, 2, 2, 1, 1, 2, 2]),
            (-28, [2, 2, 1, 1, 2, 2, 1, 1, 1, 1, 2]),
            (-14, [2, 1, 1, 1, 2, 1, 1, 1, 0, 1, 2]),
        ]
        for (offset, answers) in scores {
            repo.save(questionnaire: Questionnaire(day: today.adding(days: offset), answers: answers))
        }

        repo.save(medication: Medication(name: text.vitaminD, kind: .supplement, howTaken: text.daily, started: today.adding(days: first)))
        repo.save(medication: Medication(name: text.patch, kind: .prescribed, howTaken: text.asPrescribed, started: today.adding(days: -30)))

        repo.save(visit: Visit(day: today.adding(days: -35), clinician: text.clinician, reason: text.firstReason,
                               takenSeriously: .partly, decisions: [.startedTreatment, .bloodTests],
                               outcome: text.outcome, followUp: today.adding(days: 9)))
        if DesignFlags.has("-design-after-visit") {
            repo.save(visit: Visit(day: today.adding(days: -1), clinician: text.clinician, reason: text.followUpReason))
        } else {
            repo.save(visit: Visit(day: today.adding(days: 9), clinician: text.clinician, reason: text.followUpReason))
        }

        let questions = text.questions
        for (rank, text) in questions.enumerated() {
            repo.save(question: DoctorQuestion(text: text, rank: rank))
        }

        let calendar = Calendar.current
        for offset in -13...0 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: Date()) else { continue }
            for (n, hour) in [7, 13, 16, 22].enumerated() where (offset + n) % 3 != 0 {
                guard let at = calendar.date(bySettingHour: hour, minute: 10 * n, second: 0, of: date), at < Date() else { continue }
                repo.logEpisode(hour == 22 ? .nightSweat : .hotFlush, intensity: Severity(rawValue: 1 + (abs(offset) + n) % 3) ?? .mild, at: at)
            }
        }
    }
}

enum DesignScreen: String, Identifiable {
    // Sheets
    case checkIn, checkInSaved, questionnaire, quickLog, afterVisit, paywall, addMedication, questions
    // Pushed screens
    case weekly, cycle, patterns, medications, treatmentCheck, visitNotes, symptoms, appointment, health, recentlyDeleted

    var id: String { rawValue }
    var isPush: Bool {
        switch self {
        case .checkIn, .checkInSaved, .questionnaire, .quickLog, .afterVisit, .paywall, .addMedication, .questions: false
        default: true
        }
    }

    static var requested: DesignScreen? { DesignFlags.value("-design-screen").flatMap(DesignScreen.init(rawValue:)) }

    @MainActor @ViewBuilder
    func content(_ model: AppModel) -> some View {
        switch self {
        case .checkIn: CheckInView(day: .today)
        case .checkInSaved:
            if let last = model.repository.allCheckIns().last {
                NavigationStack { CheckInSavedView(checkIn: last) {} }
            }
        case .questionnaire: QuestionnaireView()
        case .quickLog: QuickLogSheet(kind: .hotFlush).presentationDetents([.height(380)])
        case .afterVisit:
            if let visit = model.repository.currentVisit() { AfterVisitView(visit: visit) }
        case .paywall: PaywallView()
        case .addMedication: AddMedicationView()
        case .questions: NavigationStack { QuestionsView() }
        case .weekly: WeeklySummaryView()
        case .cycle: CycleView()
        case .patterns: PatternsView()
        case .medications: MedicationsView()
        case .treatmentCheck:
            if let medication = model.repository.medications().first(where: { $0.kind == .prescribed }) {
                TreatmentCheckView(medication: medication)
            }
        case .visitNotes: VisitNotesView()
        case .symptoms: SymptomsEditorView()
        case .appointment: AppointmentView()
        case .health: HealthSettingsView()
        case .recentlyDeleted: RecentlyDeletedView()
        }
    }
}

/// Opens the requested screen over the app the way the app itself shows it.
struct DesignPresenter: ViewModifier {
    @Environment(AppModel.self) private var model
    @State private var sheet: DesignScreen?
    @State private var push: DesignScreen?

    func body(content: Content) -> some View {
        content
            .overlay {
                if let push {
                    NavigationStack { push.content(model) }
                        .background(Theme.background.ignoresSafeArea())
                        .accessibilityIdentifier("design.ready")
                }
            }
            .sheet(item: $sheet) { screen in
                screen.content(model).accessibilityIdentifier("design.ready")
            }
            .task {
                if DesignFlags.has("-design-dark") {
                    for scene in UIApplication.shared.connectedScenes {
                        (scene as? UIWindowScene)?.windows.forEach { $0.overrideUserInterfaceStyle = .dark }
                    }
                }
                guard let screen = DesignScreen.requested else { return }
                if screen.isPush {
                    push = screen
                } else {
                    try? await Task.sleep(for: .milliseconds(300))
                    sheet = screen
                }
            }
    }
}
#endif

extension View {
    /// Debug builds only: the design catalog opens the requested screen by itself.
    @ViewBuilder
    func designPresenter() -> some View {
        #if DEBUG
        modifier(DesignPresenter())
        #else
        self
        #endif
    }

    /// Debug builds only: with `-design-alert <name>` the design catalog opens this popup by itself.
    @ViewBuilder
    func designAlert(_ name: String, _ open: @escaping () -> Void) -> some View {
        #if DEBUG
        task {
            guard DesignFlags.alert == name else { return }
            try? await Task.sleep(for: .milliseconds(900))
            open()
        }
        #else
        self
        #endif
    }
}
