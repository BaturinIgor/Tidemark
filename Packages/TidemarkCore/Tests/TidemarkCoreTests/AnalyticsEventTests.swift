import Foundation
import Testing
@testable import TidemarkCore

/// CLAUDE.md: health data must never go to analytics. These tests build every event the catalog allows
/// and check that none of them can carry it.
@Suite("Analytics events")
struct AnalyticsEventTests {
    /// Every parameter value the typed API can produce.
    private var allParameters: [AnalyticsParameter] {
        AppTab.allCases.map { .tab($0) }
            + (0...4).map { .step($0) }
            + HistoryRange.allCases.map { .range($0) }
            + ProFeature.allCases.map { .feature($0) }
            + SubscriptionPlan.allCases.map { .plan($0) }
            + [.enabled(true), .enabled(false)]
            + [0, 1, 5, 8, 13, 22, 40, 400].map { .count($0) }
            + AppearanceTheme.allCases.map { .theme($0) }
            + AppIconChoice.allCases.map { .icon($0) }
    }

    private var allEvents: [AnalyticsEvent] {
        let base = AnalyticsScreen.allCases.map(AnalyticsEvent.screen)
            + AnalyticsAction.allCases.flatMap { action in
                [AnalyticsEvent.action(action)] + allParameters.map { AnalyticsEvent.action(action, $0) }
            }
            + SubscriptionPlan.allCases.flatMap { plan in
                [true, false].map { AnalyticsEvent.purchase(plan: plan, productID: plan.productID, value: 39.99, currency: "usd", trial: $0) }
            }
        return base + AnalyticsScreen.allCases.flatMap { screen in base.prefix(60).map { $0.on(screen) } }
    }

    /// Words that would reveal what the user recorded.
    private var forbidden: [String] {
        Symptom.catalog.flatMap { [$0.id, $0.name.lowercased()] }
            + Factor.allCases.map { $0.rawValue.lowercased() }
            + ["mild", "moderate", "severe", "spotting", "heavy", "bleed", "period", "flush", "sweat", "note",
               "custom_", "flag", "score", "answer", "dose", "medication_name", "question_text", "reason", "outcome"]
    }

    private func texts(_ event: AnalyticsEvent) -> [String] {
        [event.name] + event.parameters.flatMap { key, value -> [String] in
            switch value {
            case .text(let t): [key, t]
            case .number, .decimal: [key]
            }
        }
    }

    @Test("Only whitelisted parameter keys are ever sent")
    func parameterKeys() {
        for event in allEvents {
            #expect(Set(event.parameters.keys).isSubset(of: AnalyticsEvent.allowedParameterKeys), "\(event.name)")
        }
    }

    @Test("No event name or value contains symptom, rating, bleeding or other health words")
    func noHealthData() {
        for event in allEvents {
            for text in texts(event) {
                let lower = text.lowercased()
                for word in forbidden {
                    #expect(!lower.contains(word), "\(event.name): '\(text)' contains '\(word)'")
                }
            }
        }
    }

    @Test("There is no event for a bleeding prompt (red flag)")
    func noRedFlagEvent() {
        #expect(!AnalyticsAction.allCases.contains { $0.rawValue.contains("flag") || $0.rawValue.contains("alert") })
        #expect(!AnalyticsScreen.allCases.contains { $0.rawValue.contains("flag") })
    }

    @Test("Event names follow Firebase limits: snake_case, at most 40 characters, not reserved")
    func firebaseNames() {
        let reserved: Set<String> = ["app_remove", "first_open", "session_start", "user_engagement", "in_app_purchase"]
        for action in AnalyticsAction.allCases {
            let name = action.rawValue
            #expect(name.count <= 40)
            #expect(name.range(of: "^[a-z][a-z0-9_]*$", options: .regularExpression) != nil, "\(name)")
            #expect(!reserved.contains(name) && !name.hasPrefix("firebase_") && !name.hasPrefix("google_"))
        }
    }

    @Test("purchase is GA4's standard event; a trial start has value 0; unknown products are not echoed")
    func purchase() {
        let paid = AnalyticsEvent.purchase(plan: .yearly, productID: "app.tidemark.report.yearly", value: 39.99, currency: "usd", trial: false)
        #expect(paid.name == "purchase")
        #expect(paid.parameters["value"] == .decimal(39.99) && paid.parameters["currency"] == .text("USD"))
        let trial = AnalyticsEvent.purchase(plan: .yearly, productID: "app.tidemark.report.yearly", value: 39.99, currency: "GBP", trial: true)
        #expect(trial.parameters["value"] == .decimal(0))
        let odd = AnalyticsEvent.purchase(plan: .monthly, productID: "something typed", value: 1, currency: "not a code", trial: false)
        #expect(odd.parameters["item_id"] == .text("unknown") && odd.parameters["currency"] == .text("XXX"))
        #expect(AnalyticsEvent.action(.pdfSaved).on(.report).parameters["screen"] == .text("report"))
        #expect(AnalyticsEvent.screen(.report).on(.history).parameters["screen"] == nil)
    }

    @Test("Counts are sent as coarse buckets")
    func buckets() {
        #expect(AnalyticsEvent.bucket(0) == "0")
        #expect(AnalyticsEvent.bucket(7) == "7-13")
        #expect(AnalyticsEvent.bucket(1000) == "90+")
        #expect(AnalyticsEvent.action(.symptomsChanged, .count(11)).parameters["count_bucket"] == .text("7-13"))
        #expect(AnalyticsEvent.action(.onboardingStep, .step(9)).parameters["step"] == .number(3))
    }
}
