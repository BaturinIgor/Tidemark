import FirebaseAnalytics
import FirebaseCore
import Foundation
import StoreKit
import SwiftUI
import TidemarkCore

/// Anonymous usage statistics through Google Analytics for Firebase, set up as in ZenHab and Hearthmend
/// (tools/analytics/README.md), with one difference: it is opt-in. Tidemark is a menopause app, so even
/// which screens someone opens says something about her health (UK and EU GDPR).
///
/// - Only `AnalyticsEvent`s from TidemarkCore can be sent: screens, taps and purchases, never what was
///   recorded. TidemarkCore's AnalyticsEventTests check that no event can carry health data.
/// - Every event carries `screen`; purchases use GA4's standard `purchase` event with value and currency.
/// - User properties: `build_type` (debug / testflight / appstore; look at appstore only), `first_seen_week`, `is_pro`.
/// - Nothing is sent without GoogleService-Info.plist, in Debug, on the simulator or in the design catalog,
///   unless the app is started with -AnalyticsDebug (add -FIRDebugEnabled to see events in DebugView).
/// - No IDFA (FirebaseAnalyticsCore), IDFV and ad signals are off in project.yml, consent mode denies ads.
@MainActor
final class UsageAnalytics {
    static let shared = UsageAnalytics()

    /// true = the user agreed, false = she said no, missing = not asked yet (then nothing is sent).
    static let consentKey = "analyticsConsent"

    private let defaults = UserDefaults.standard
    private(set) var configured = false
    private var screenStack: [AnalyticsScreen] = []

    private enum Key {
        static let firstSeen = "analytics.firstSeen"
    }

    private init() {}

    // MARK: Availability and consent

    /// GoogleService-Info.plist is in the app, and this is not Debug, the simulator or the design catalog.
    static var isAvailable: Bool {
        guard !DesignFlags.active, !TidemarkApp.isRunningTests,
              Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else { return false }
        return sendsFrom(isDebug: isDebugBuild, isSimulator: isSimulator,
                         forced: ProcessInfo.processInfo.arguments.contains("-AnalyticsDebug"))
    }

    nonisolated static func sendsFrom(isDebug: Bool, isSimulator: Bool, forced: Bool) -> Bool {
        forced || (!isDebug && !isSimulator)
    }

    static var isDebugBuild: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    /// Nil until the user has answered the question in onboarding or in Settings.
    var consent: Bool? { defaults.object(forKey: Self.consentKey) as? Bool }

    /// Firebase is set up and the user said yes.
    var isActive: Bool { configured && consent == true }

    enum BuildType: String {
        case debug, testflight, appstore

        static func make(isDebug: Bool, isSimulator: Bool, isSandbox: Bool) -> BuildType {
            if isDebug || isSimulator { return .debug }
            return isSandbox ? .testflight : .appstore
        }
    }

    private static func isSandbox() async -> Bool {
        guard let result = try? await AppTransaction.shared else { return false }
        switch result {
        case .verified(let t), .unverified(let t, _): return t.environment != .production
        }
    }

    /// At launch. Configures Firebase (collection stays off) and turns collection on only with consent.
    func start() {
        guard Self.isAvailable, !configured,
              let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              // a broken plist would crash in configure(); this way there are simply no statistics
              let options = FirebaseOptions(contentsOfFile: path) else { return }
        FirebaseApp.configure(options: options)
        configured = true
        if defaults.object(forKey: Key.firstSeen) == nil { defaults.set(Date(), forKey: Key.firstSeen) }
        apply(consent == true)
    }

    /// The answer from onboarding or the Settings switch.
    func setConsent(_ granted: Bool) {
        defaults.set(granted, forKey: Self.consentKey)
        guard configured else { return }
        apply(granted)
        if !granted { Analytics.resetAnalyticsData() }
    }

    private func apply(_ granted: Bool) {
        Analytics.setConsent([
            .analyticsStorage: granted ? .granted : .denied,
            .adStorage: .denied, .adUserData: .denied, .adPersonalization: .denied,
        ])
        Analytics.setAnalyticsCollectionEnabled(granted)
        guard granted else { return }
        if let first = defaults.object(forKey: Key.firstSeen) as? Date {
            Analytics.setUserProperty(Self.weekKey(first), forName: "first_seen_week")
        }
        Task {
            let type = BuildType.make(isDebug: Self.isDebugBuild, isSimulator: Self.isSimulator, isSandbox: await Self.isSandbox())
            Analytics.setUserProperty(type.rawValue, forName: "build_type")
        }
    }

    func setPro(_ isPro: Bool) {
        guard isActive else { return }
        Analytics.setUserProperty(isPro ? "1" : "0", forName: "is_pro")
    }

    // MARK: Events

    func log(_ action: AnalyticsAction, _ parameters: AnalyticsParameter...) {
        log(action, parameters: parameters)
    }

    func log(_ action: AnalyticsAction, parameters: [AnalyticsParameter]) {
        send(AnalyticsEvent.action(action, parameters: parameters))
    }

    func purchase(_ product: Product, trial: Bool) {
        guard let plan = SubscriptionPlan(productID: product.id) else { return }
        if trial { log(.trialStarted, .plan(plan)) }
        send(.purchase(plan: plan, productID: product.id, value: NSDecimalNumber(decimal: product.price).doubleValue,
                       currency: product.priceFormatStyle.currencyCode, trial: trial))
    }

    func screenAppeared(_ screen: AnalyticsScreen) {
        screenStack.removeAll { $0 == screen }
        screenStack.append(screen)
        send(.screen(screen))
    }

    func screenDisappeared(_ screen: AnalyticsScreen) {
        let wasTop = screenStack.last == screen
        screenStack.removeAll { $0 == screen }
        if wasTop, let top = screenStack.last { send(.screen(top)) }
    }

    private func send(_ event: AnalyticsEvent) {
        let event = event.on(screenStack.last)
        #if DEBUG
        print("[analytics]", event.name, event.parameters)
        #endif
        guard isActive else { return }
        Analytics.logEvent(event.name, parameters: event.parameters.mapValues { value -> Any in
            switch value {
            case .text(let t): t
            case .number(let n): n
            case .decimal(let d): d
            }
        })
    }

    /// Week of the first launch, like 2026-W48, for retention cohorts.
    static func weekKey(_ date: Date) -> String {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        let parts = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", parts.yearForWeekOfYear ?? 0, parts.weekOfYear ?? 0)
    }
}

extension View {
    /// Sends screen_view while the view is on screen.
    func analyticsScreen(_ screen: AnalyticsScreen) -> some View {
        onAppear { UsageAnalytics.shared.screenAppeared(screen) }
            .onDisappear { UsageAnalytics.shared.screenDisappeared(screen) }
    }
}
