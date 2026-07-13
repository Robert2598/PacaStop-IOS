//
//  RevenueCatPurchaseService.swift
//  PacaStop
//
//  Production paywall engine. Inert until the RevenueCat SPM package is added AND a
//  REVENUECAT_API_KEY is configured (Secrets.plist / env) — otherwise the app uses the
//  native StoreKit 2 service. See INTEGRATION.md.
//
//  Setup: add `https://github.com/RevenueCat/purchases-ios`, create an entitlement named
//  "premium" in the RevenueCat dashboard, and an offering with the annual + weekly packages.
//

#if canImport(RevenueCat)
import Foundation
import Observation
import RevenueCat
import StoreKit

@Observable
@MainActor
final class RevenueCatPurchaseService: PurchaseService {
    private(set) var products: [PaywallProduct] = []
    private(set) var isSubscribed = false
    private(set) var loadState: ProductsLoadState = .idle
    private(set) var isReady = false

    private var packages: [String: Package] = [:]
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init(apiKey: String) {
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: apiKey)
    }

    func start() {
        Task { await refreshEntitlement() }
        // React to any StoreKit transaction change (renewal, a deferred/Ask-to-Buy purchase
        // settling, an external purchase) so the unlock is never missed. RevenueCat finishes
        // the transactions; we just re-derive entitlement from the current state.
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await _ in StoreKit.Transaction.updates {
                await self?.refreshEntitlement()
            }
        }
    }

    /// Aliases the RevenueCat customer to the Clerk user id (nil = back to anonymous on
    /// sign-out), so the proxy's server-side `premium` check keys to the same user.
    func identify(_ userID: String?) {
        Task {
            if let userID {
                _ = try? await Purchases.shared.logIn(userID)
            } else {
                _ = try? await Purchases.shared.logOut()
            }
            await refreshEntitlement()
        }
    }

    func loadProducts() async {
        loadState = .loading
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let current = offerings.current else { loadState = .failed; return }
            packages = Dictionary(current.availablePackages.map { ($0.identifier, $0) }) { a, _ in a }
            var mapped = current.availablePackages.map(Self.map)
            // Yearly savings vs 12× monthly — the anchor on the yearly card.
            if let yearly = current.availablePackages.first(where: { Self.planPeriod(for: $0) == .yearly }),
               let monthly = current.availablePackages.first(where: { Self.planPeriod(for: $0) == .monthly }) {
                let yearlyPrice = (yearly.storeProduct.price as NSDecimalNumber).doubleValue
                let monthlyYear = (monthly.storeProduct.price as NSDecimalNumber).doubleValue * 12
                if monthlyYear > 0 {
                    let pct = Int(((1 - yearlyPrice / monthlyYear) * 100).rounded())
                    if pct > 0, let i = mapped.firstIndex(where: { $0.id == yearly.identifier }) {
                        mapped[i].savingsPercent = pct
                    }
                }
            }
            products = mapped.sorted { $0.sortRank < $1.sortRank }
            loadState = products.isEmpty ? .failed : .loaded
        } catch {
            loadState = .failed
        }
    }

    func purchase(_ productID: String) async -> PurchaseOutcome {
        guard let package = packages[productID] else { return .failed("unavailable") }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { return .cancelled }
            // Entitlement comes straight from the CustomerInfo the purchase returned — the same
            // `premium` entitlement the backend checks. No StoreKit shortcut: RevenueCat is the
            // single source of truth for both client and server.
            isSubscribed = Self.isEntitled(result.customerInfo)
            isReady = true
            return isSubscribed ? .purchased : .pending
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    func restore() async -> Bool {
        let info = try? await Purchases.shared.restorePurchases()
        isSubscribed = info.map(Self.isEntitled) ?? false
        isReady = true
        return isSubscribed
    }

    private func refreshEntitlement() async {
        // RevenueCat is the single source of truth: the client unlocks iff the same `premium`
        // entitlement the backend checks is active. `customerInfo()` returns RevenueCat's locally
        // cached view when offline, so a paying user isn't locked out by a transient network blip.
        if let info = try? await Purchases.shared.customerInfo() {
            isSubscribed = Self.isEntitled(info)
        }
        isReady = true
    }

    /// Premium = ANY active RevenueCat entitlement. PacaStop sells a single entitlement (its
    /// identifier is "PacaStop Pro", not "premium"), so we never hardcode the lookup key — this
    /// matches the backend, which counts any active entitlement from the RevenueCat V2 API. Same
    /// question, same answer, both sides. (Lifetime reports a nil expiry and still counts as active.)
    private static func isEntitled(_ info: CustomerInfo) -> Bool {
        !info.entitlements.active.isEmpty
    }

    private static func map(_ package: Package) -> PaywallProduct {
        let product = package.storeProduct
        let period = planPeriod(for: package)
        var perMonth: String?
        if period == .yearly, let priceString = monthlyPrice(for: product) {
            perMonth = priceString
        }
        return PaywallProduct(
            id: package.identifier,
            displayName: product.localizedTitle,
            displayPrice: product.localizedPriceString,
            period: period,
            perMonthDisplay: perMonth,
            isBestValue: period == .yearly
        )
    }

    /// Prefer RevenueCat's declared package type; fall back to the product's period.
    private static func planPeriod(for package: Package) -> PlanPeriod {
        switch package.packageType {
        case .lifetime: return .lifetime
        case .annual: return .yearly
        case .monthly: return .monthly
        default:
            switch package.storeProduct.subscriptionPeriod?.unit {
            case .month: return .monthly
            case .year: return .yearly
            default: return package.storeProduct.subscriptionPeriod == nil ? .lifetime : .other
            }
        }
    }

    private static func monthlyPrice(for product: StoreProduct) -> String? {
        let monthly = product.price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatter?.locale ?? .current
        return formatter.string(from: monthly as NSDecimalNumber)
    }
}
#endif
