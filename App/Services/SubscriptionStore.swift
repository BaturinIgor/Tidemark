import Foundation
import Observation
import StoreKit

/// StoreKit 2. Logging is free; the PDF report needs an active subscription.
@MainActor
@Observable
final class SubscriptionStore {
    static let productIDs = ["app.tidemark.report.yearly", "app.tidemark.report.monthly"]

    private(set) var products: [Product] = []
    private(set) var isSubscribed = false
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
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        // Debug design catalog: the simulator has no purchases.
        if DesignFlags.subscribed { isSubscribed = true; return }
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil { active = true }
        }
        isSubscribed = active
    }

    func purchase(_ product: Product) async {
        purchaseError = nil
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await transaction.finish()
                await refreshEntitlements()
            case .success(.unverified):
                purchaseError = String(localized: "We couldn't verify the purchase with the App Store. You were not charged twice; try Restore.")
            case .pending, .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = String(localized: "The App Store didn't respond. Check your connection and try again.")
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }
}
