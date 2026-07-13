//
//  PurchaseService.swift
//  PacaStop
//
//  The hard paywall's engine. Default is native StoreKit 2 (reads the bundled
//  PacaStop.storekit config in-simulator, real products in production). RevenueCat is
//  swapped in when an API key is configured. Entitlement gates access to the app.
//

import Foundation
import Observation
import StoreKit
import os

nonisolated enum PlanPeriod: Sendable {
    case monthly, yearly, lifetime, other
}

nonisolated struct PaywallProduct: Identifiable, Sendable {
    var id: String
    var displayName: String
    var displayPrice: String
    var period: PlanPeriod
    /// For the yearly plan: the price broken down per month, in the product's currency.
    var perMonthDisplay: String?
    var isBestValue: Bool
    /// For the yearly plan: % saved vs paying monthly for a year (the anchor).
    var savingsPercent: Int? = nil

    /// Stable display order: yearly (best value) → monthly → lifetime.
    var sortRank: Int {
        switch period {
        case .yearly: 0
        case .monthly: 1
        case .lifetime: 2
        case .other: 3
        }
    }
}

nonisolated enum PurchaseOutcome: Sendable {
    case purchased
    case pending
    case cancelled
    case failed(String)
}

nonisolated enum ProductsLoadState: Sendable {
    case idle, loading, loaded, failed
}

@MainActor
protocol PurchaseService: AnyObject {
    var products: [PaywallProduct] { get }
    var isSubscribed: Bool { get }
    var loadState: ProductsLoadState { get }
    /// True once the initial entitlement check has completed (prevents a paywall flash).
    var isReady: Bool { get }

    func start()
    /// Ties purchases/entitlements to a stable user id (the Clerk user id), so the backend's
    /// server-side premium check keys to the same user. Pass nil on sign-out.
    func identify(_ userID: String?)
    func loadProducts() async
    func purchase(_ productID: String) async -> PurchaseOutcome
    func restore() async -> Bool
}

@Observable
@MainActor
final class StoreKitPurchaseService: PurchaseService {
    static let yearlyID = "pacastop.yearly.subscription"
    static let monthlyID = "pacastop.monthly.subscription"
    static let lifetimeID = "com.pixelpaw.pacastop.lifetime"
    static let productIDs = [yearlyID, monthlyID, lifetimeID]

    private(set) var products: [PaywallProduct] = []
    private(set) var isSubscribed = false
    private(set) var loadState: ProductsLoadState = .idle
    private(set) var isReady = false

    private var rawProducts: [String: Product] = [:]
    private var updatesTask: Task<Void, Never>?
    private let logger = Logger(subsystem: "com.pixelpaw.PacaStop", category: "Purchases")

    func start() {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    await self.refreshEntitlement()
                }
            }
        }
        Task { await refreshEntitlement() }
    }

    /// StoreKit ties entitlements to the Apple ID, not an app user id — nothing to do here.
    func identify(_ userID: String?) {}

    func loadProducts() async {
        loadState = .loading
        #if DEBUG
        // Local paywall preview: command-line launches don't apply the .storekit test file,
        // so show the display-only fallback plans (all three tiers) for UI testing.
        if ProcessInfo.processInfo.arguments.contains("-localStore") {
            products = Self.fallbackProducts
            loadState = .loaded
            return
        }
        #endif
        do {
            let storeProducts = try await Product.products(for: Self.productIDs)
            var byID: [String: Product] = [:]
            for p in storeProducts { byID[p.id] = p }
            rawProducts = byID
            var mapped = Self.productIDs.compactMap { byID[$0] }.map(Self.map)
            // Compute yearly savings vs paying monthly for a year — the paywall's key anchor.
            if let yearly = byID[Self.yearlyID], let monthly = byID[Self.monthlyID] {
                let yearlyPrice = (yearly.price as NSDecimalNumber).doubleValue
                let monthlyYear = (monthly.price as NSDecimalNumber).doubleValue * 12
                if monthlyYear > 0 {
                    let pct = Int(((1 - yearlyPrice / monthlyYear) * 100).rounded())
                    if pct > 0, let i = mapped.firstIndex(where: { $0.id == Self.yearlyID }) {
                        mapped[i].savingsPercent = pct
                    }
                }
            }
            mapped.sort { $0.sortRank < $1.sortRank }
            if mapped.isEmpty {
                // StoreKit returned nothing (e.g. no .storekit config wired to the run, or
                // App Store Connect not reachable). Show display-only fallback plans so the
                // paywall never looks broken; purchase() degrades gracefully until real
                // products resolve.
                products = Self.fallbackProducts
                loadState = .loaded
            } else {
                products = mapped
                loadState = .loaded
            }
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription, privacy: .public)")
            products = Self.fallbackProducts
            loadState = .loaded
        }
    }

    /// Display-only plans mirroring PacaStop.storekit, used when live products can't load.
    private static let fallbackProducts: [PaywallProduct] = [
        PaywallProduct(id: yearlyID, displayName: "Anual", displayPrice: "199,99 lei",
                       period: .yearly, perMonthDisplay: "16,66 lei", isBestValue: true, savingsPercent: 52),
        PaywallProduct(id: monthlyID, displayName: "Lunar", displayPrice: "34,99 lei",
                       period: .monthly, perMonthDisplay: nil, isBestValue: false),
        PaywallProduct(id: lifetimeID, displayName: "Pe viață", displayPrice: "499,99 lei",
                       period: .lifetime, perMonthDisplay: nil, isBestValue: false),
    ]

    func purchase(_ productID: String) async -> PurchaseOutcome {
        guard let product = rawProducts[productID] else { return .failed("unavailable") }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlement()
                    return .purchased
                }
                return .failed("unverified")
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .failed("unknown")
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    func restore() async -> Bool {
        try? await AppStore.sync()
        await refreshEntitlement()
        return isSubscribed
    }

    private func refreshEntitlement() async {
        var active = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               Self.productIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                active = true
            }
        }
        isSubscribed = active
        isReady = true
    }

    private static func map(_ product: Product) -> PaywallProduct {
        let period = planPeriod(for: product)
        var perMonth: String?
        if period == .yearly {
            let monthly = product.price / 12
            perMonth = product.priceFormatStyle.format(monthly)
        }
        return PaywallProduct(
            id: product.id,
            displayName: product.displayName,
            displayPrice: product.displayPrice,
            period: period,
            perMonthDisplay: perMonth,
            isBestValue: period == .yearly
        )
    }

    private static func planPeriod(for product: Product) -> PlanPeriod {
        if product.type == .nonConsumable { return .lifetime }
        switch product.subscription?.subscriptionPeriod.unit {
        case .month: return .monthly
        case .year: return .yearly
        default: return .other
        }
    }
}

// MARK: - Preview / test double

@Observable
@MainActor
final class PreviewPurchaseService: PurchaseService {
    var products: [PaywallProduct]
    var isSubscribed: Bool
    var loadState: ProductsLoadState = .loaded
    var isReady = true

    init(subscribed: Bool = false) {
        isSubscribed = subscribed
        products = [
            PaywallProduct(id: "yearly", displayName: "Anual", displayPrice: "199,99 lei",
                           period: .yearly, perMonthDisplay: "16,66 lei", isBestValue: true, savingsPercent: 52),
            PaywallProduct(id: "monthly", displayName: "Lunar", displayPrice: "34,99 lei",
                           period: .monthly, perMonthDisplay: nil, isBestValue: false),
            PaywallProduct(id: "lifetime", displayName: "Pe viață", displayPrice: "499,99 lei",
                           period: .lifetime, perMonthDisplay: nil, isBestValue: false),
        ]
    }

    func start() {}
    func identify(_ userID: String?) {}
    func loadProducts() async {}
    func purchase(_ productID: String) async -> PurchaseOutcome { isSubscribed = true; return .purchased }
    func restore() async -> Bool { isSubscribed }
}
