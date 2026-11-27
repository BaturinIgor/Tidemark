import Foundation

/// The only usage events the app can send (opt-in, Firebase). They describe what the user did in the app
/// (screens, taps, purchases), never what she recorded.
///
/// Rules, enforced by the types here and by `AnalyticsEventTests`:
/// - No symptom ids or names, ratings, bleeding, factors, notes, medicine, question or visit text,
///   custom symptom names, questionnaire answers or scores, and no event for a bleeding prompt.
/// - Parameter values come from closed enums or count buckets. There is no public initializer that takes
///   free text, so nothing typed by the user can reach an event.
public struct AnalyticsEvent: Equatable, Sendable {
    public enum Value: Equatable, Sendable {
        case text(String)
        case number(Int)
        case decimal(Double)
    }

    public let name: String
    public let parameters: [String: Value]

    init(name: String, parameters: [String: Value] = [:]) {
        self.name = name
        self.parameters = parameters
    }

    public static let allowedParameterKeys: Set<String> = [
        "screen_name", "screen_class", "tab", "step", "range_weeks", "feature", "plan", "enabled",
        "count_bucket", "theme", "icon", "screen", "value", "currency", "item_id",
    ]

    /// Firebase's own screen event.
    public static func screen(_ screen: AnalyticsScreen) -> AnalyticsEvent {
        AnalyticsEvent(name: "screen_view", parameters: ["screen_name": .text(screen.rawValue), "screen_class": .text(screen.rawValue)])
    }

    public static func action(_ action: AnalyticsAction, _ parameters: AnalyticsParameter...) -> AnalyticsEvent {
        self.action(action, parameters: parameters)
    }

    public static func action(_ action: AnalyticsAction, parameters: [AnalyticsParameter]) -> AnalyticsEvent {
        AnalyticsEvent(name: action.rawValue, parameters: Dictionary(parameters.map(\.pair), uniquingKeysWith: { _, last in last }))
    }

    /// GA4's standard `purchase` event, so revenue shows in the reports. `trial` is a free trial start
    /// (value 0). The product ID is one of ours; nothing about the user is in it.
    public static func purchase(plan: SubscriptionPlan, productID: String, value: Double, currency: String, trial: Bool) -> AnalyticsEvent {
        let id = SubscriptionPlan.productIDs.contains(productID) ? productID : "unknown"
        let code = currency.count == 3 && currency.allSatisfy(\.isLetter) ? currency.uppercased() : "XXX"
        return AnalyticsEvent(name: "purchase", parameters: [
            "value": .decimal(trial ? 0 : value), "currency": .text(code), "item_id": .text(id), "plan": .text(plan.rawValue),
        ])
    }

    /// Every event also says which screen it happened on (as in ZenHab and Hearthmend).
    public func on(_ screen: AnalyticsScreen?) -> AnalyticsEvent {
        guard let screen, name != "screen_view" else { return self }
        var p = parameters
        p["screen"] = .text(screen.rawValue)
        return AnalyticsEvent(name: name, parameters: p)
    }

    /// Counts are sent only as coarse buckets.
    public static func bucket(_ count: Int) -> String {
        switch count {
        case ..<1: "0"
        case 1: "1"
        case 2...6: "2-6"
        case 7...13: "7-13"
        case 14...29: "14-29"
        case 30...89: "30-89"
        default: "90+"
        }
    }
}

public enum AnalyticsParameter: Equatable, Sendable {
    case tab(AppTab)
    case step(Int)
    case range(HistoryRange)
    case feature(ProFeature)
    case plan(SubscriptionPlan)
    case enabled(Bool)
    case count(Int)
    case theme(AppearanceTheme)
    case icon(AppIconChoice)

    var pair: (String, AnalyticsEvent.Value) {
        switch self {
        case .tab(let t): ("tab", .text(t.rawValue))
        case .step(let s): ("step", .number(min(max(s, 1), 3)))
        case .range(let r): ("range_weeks", .number(r.weeks))
        case .feature(let f): ("feature", .text(f.rawValue))
        case .plan(let p): ("plan", .text(p.rawValue))
        case .enabled(let on): ("enabled", .text(on ? "on" : "off"))
        case .count(let n): ("count_bucket", .text(AnalyticsEvent.bucket(n)))
        case .theme(let t): ("theme", .text(t.rawValue))
        case .icon(let i): ("icon", .text(i.rawValue))
        }
    }
}

public enum AppTab: String, CaseIterable, Sendable {
    case today, history, report, settings
}

public enum SubscriptionPlan: String, CaseIterable, Sendable {
    case yearly, monthly

    public var productID: String { "app.tidemark.report.\(rawValue)" }
    public static let productIDs = allCases.map(\.productID)

    public init?(productID: String) {
        guard let plan = Self.allCases.first(where: { $0.productID == productID }) else { return nil }
        self = plan
    }
}

public enum AnalyticsScreen: String, CaseIterable, Sendable {
    case onboardingWelcome = "onboarding_welcome"
    case onboardingSymptoms = "onboarding_symptoms"
    case onboardingVisit = "onboarding_visit"
    case restore
    case today
    case checkIn = "check_in"
    case checkInSaved = "check_in_saved"
    case quickLog = "quick_log"
    case history
    case cycle
    case patterns
    case medicines
    case medicineDetail = "medicine_detail"
    case addMedicine = "add_medicine"
    case visitNotes = "visit_history"
    case afterVisit = "after_visit"
    case weeklySummary = "weekly_summary"
    case questionnaire
    case report
    case reportPreview = "report_preview"
    case questions
    case paywall
    case settings
    case symptomsEditor = "symptoms_editor"
    case appointment
    case appleHealth = "apple_health"
    case importPreview = "import_preview"
    case recentlyDeleted = "recently_deleted"
    case appearance
    case lock
    case storeError = "store_error"
}

public enum AnalyticsAction: String, CaseIterable, Sendable {
    // Navigation
    case tabSelected = "tab_selected"
    case onboardingStep = "onboarding_step"
    case onboardingCompleted = "onboarding_completed"
    case restoreChosen = "restore_chosen"
    case startFreshChosen = "start_fresh_chosen"
    // Logging (never what was logged)
    case checkInOpened = "check_in_opened"
    case ratingChanged = "rating_changed"
    case checkInSaved = "check_in_saved"
    case missedDayOpened = "missed_day_opened"
    case quickLogSaved = "quick_log_saved"
    case questionnaireCompleted = "questionnaire_completed"
    case medicineSaved = "medicine_saved"
    case questionSaved = "question_saved"
    case visitSaved = "visit_saved"
    case appointmentSaved = "appointment_saved"
    // History and report
    case rangeSelected = "range_selected"
    case reportPreviewed = "report_previewed"
    case pdfSaved = "pdf_saved"
    case comparisonToggled = "comparison_toggled"
    // Data
    case exportJSON = "export_json"
    case exportCSV = "export_csv"
    case importCompleted = "import_completed"
    case deleteAllConfirmed = "delete_all_confirmed"
    case restoreDeleted = "restore_deleted"
    // Settings
    case symptomsChanged = "symptoms_changed"
    case ownSymptomAdded = "own_symptom_added"
    case themeChanged = "theme_changed"
    case iconChanged = "icon_changed"
    case reminderToggled = "reminder_toggled"
    case faceIDToggled = "face_id_toggled"
    case appleHealthToggled = "apple_health_toggled"
    case contactTapped = "contact_tapped"
    case analyticsToggled = "analytics_toggled"
    // Subscription
    case paywallShown = "paywall_shown"
    case planSelected = "plan_selected"
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case trialStarted = "trial_started"
    case purchaseCancelled = "purchase_cancelled"
    case purchaseFailed = "purchase_failed"
    case restoreTapped = "restore_tapped"
    case manageSubscriptionTapped = "manage_subscription_tapped"
    case proFeatureTapped = "pro_feature_tapped"
}
