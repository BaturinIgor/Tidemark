import Foundation
import Observation
import StoreKit
import TidemarkCore

/// StoreKit 2. Logging is free; one subscription (Pro) unlocks everything in `ProFeature`.
@MainActor
@Observable
final class SubscriptionStore {
    static let productIDs = ["app.tidemark.report.yearly", "app.tidemark.report.monthly"]

    private(set) var products: [Product] = []
    private(set) var isSubscribed = false
    /// True once entitlements were read at least once, so a lapsed Pro is told apart from "not loaded yet".
    private(set) var hasLoaded = false
    /// Products whose introductory offer (the free trial) this Apple Account can still get.
    private(set) var introEligible: Set<String> = []
    var purchaseError: String?
    @ObservationIgnored private var updates: Task<Void, Never>?

    init() {
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result { await transaction.finish() }
                await self?.refreshEntitlements()
            }
        }
        Task { await load() }
    }

    func load() async {
        products = (try? await Product.products(for: Self.productIDs))?.sorted { $0.price > $1.price } ?? []
        await refreshEligibility()
        await refreshEntitlements()
    }

    func refreshEligibility() async {
        var eligible: Set<String> = []
        for product in products {
            if let sub = product.subscription, sub.introductoryOffer != nil, await sub.isEligibleForIntroOffer {
                eligible.insert(product.id)
            }
        }
        introEligible = eligible
    }

    func refreshEntitlements() async {
        // Debug design catalog: the simulator has no purchases.
        if DesignFlags.subscribed { isSubscribed = true; hasLoaded = true; return }
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil { active = true }
        }
        isSubscribed = active
        hasLoaded = true
        UsageAnalytics.shared.setPro(active)
    }

    /// Free-trial length in days when this account can still start it, else nil.
    func trialDays(for product: Product) -> Int? {
        guard introEligible.contains(product.id), let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        switch offer.period.unit {
        case .day: return offer.period.value
        case .week: return offer.period.value * 7
        default: return nil
        }
    }

    func purchase(_ product: Product) async {
        purchaseError = nil
        let analytics = UsageAnalytics.shared
        let plan = SubscriptionPlan(productID: product.id)
        let planParameter: [AnalyticsParameter] = plan.map { [.plan($0)] } ?? []
        analytics.log(.purchaseStarted, parameters: planParameter)
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                let trial = transaction.offerType == .introductory && product.subscription?.introductoryOffer?.paymentMode == .freeTrial
                await transaction.finish()
                await refreshEntitlements()
                await refreshEligibility()
                analytics.log(.purchaseCompleted, parameters: planParameter)
                analytics.purchase(product, trial: trial)
            case .success(.unverified):
                purchaseError = String(localized: "We couldn't verify the purchase with the App Store. You were not charged twice; try Restore.")
                analytics.log(.purchaseFailed, parameters: planParameter)
            case .userCancelled:
                analytics.log(.purchaseCancelled, parameters: planParameter)
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = String(localized: "The App Store didn't respond. Check your connection and try again.")
            analytics.log(.purchaseFailed, parameters: planParameter)
        }
    }

    func restore() async {
        UsageAnalytics.shared.log(.restoreTapped)
        try? await AppStore.sync()
        await refreshEntitlements()
    }
}
