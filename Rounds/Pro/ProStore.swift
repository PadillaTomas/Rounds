import Foundation
import Observation
import StoreKit

/// The Rounds Pro entitlement. One non-consumable, native StoreKit 2 — no
/// RevenueCat. Owns the product, the purchase / restore flows, and the cached
/// `isPro` flag that every ``ProGate`` reads. Created once at the app root.
@MainActor
@Observable
final class ProStore {
    static let productID = "com.padillatomas.Rounds.pro"

    /// The single source of truth for "can this user see Pro features".
    private(set) var isPro = false
    private(set) var product: Product?
    private(set) var purchaseInFlight = false
    /// Set after a failed / pending purchase or a fruitless restore. The paywall
    /// surfaces it in an alert, then clears it.
    var lastError: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        // Transactions that land outside a direct `purchase()` call — Ask to Buy
        // approval, a buy on another device, a refund.
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                guard case .verified(let transaction) = update else { continue }
                if transaction.revocationDate != nil {
                    await self.syncEntitlement()          // refund / revoke
                } else {
                    await transaction.finish()
                    self.isPro = true
                }
            }
        }
    }

    /// Load the product and reconcile the entitlement. Call once at launch.
    func start() async {
        await loadProduct()
        await syncEntitlement()
    }

    func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            // Non-fatal — the paywall falls back to a hard-coded price string.
            product = nil
        }
    }

    /// The price to show — StoreKit's localized string, or a sensible default
    /// before the product loads.
    var displayPrice: String { product?.displayPrice ?? "$3.99" }

    func purchase() async {
        guard let product else {
            await loadProduct()
            if product == nil { lastError = Copy.Pro.errorNetwork }
            return
        }
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    lastError = Copy.Pro.errorFailed
                    return
                }
                await transaction.finish()
                // Trust the just-verified purchase. Do NOT re-query
                // `currentEntitlements` here — it can lag a beat and would
                // momentarily flip the unlock back off.
                isPro = true
            case .userCancelled:
                break
            case .pending:
                lastError = Copy.Pro.errorPending
            @unknown default:
                break
            }
        } catch {
            lastError = Copy.Pro.errorFailed
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await syncEntitlement()
            if !isPro { lastError = Copy.Pro.errorRestoreNone }
        } catch {
            lastError = Copy.Pro.errorNetwork
        }
    }

    /// Authoritative recompute of `isPro` from StoreKit's verified current
    /// entitlements. Used at launch, on restore, and on a revocation — moments
    /// when `currentEntitlements` is settled. Not called straight after a
    /// `purchase()` (see the note there).
    func syncEntitlement() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        isPro = owned
    }
}
