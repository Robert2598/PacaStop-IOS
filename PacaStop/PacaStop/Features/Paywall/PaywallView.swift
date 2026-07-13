//
//  PaywallView.swift
//  PacaStop
//
//  The hard paywall (value before ask), rebuilt for conversion:
//   • compact 2-line headline + one-line benefit subtitle
//   • a slim 2-column price anchor (red "what the machines take" vs. lime "PăcăStop from…")
//   • 4 benefit chips (2×2) as value proof, above the plans
//   • clean, identical plan rows so the eye compares vertically in a second
//   • one dominant CTA with a dynamic price line, and a fixed, fully-visible footer with
//     the Apple-required Restore + Terms + Privacy links.
//  Prices render in the user's App Store storefront currency (RON on a Romanian account).
//

import SwiftUI

struct PaywallView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(LocalizationStore.self) private var loc
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedProductID: String?
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var showError = false
    @State private var showPending = false
    @State private var showNothingToRestore = false
    @State private var didPurchase = false
    @State private var shownAt = Date()

    private var s: any Localization { loc.s }
    private var purchases: any PurchaseService { env.purchases }
    private var selectedProduct: PaywallProduct? {
        purchases.products.first { $0.id == selectedProductID }
    }
    /// The annual plan's normalized monthly price, for the "PăcăStop, from …/month" anchor.
    private var fromPerMonth: String? {
        purchases.products.first { $0.period == .yearly }?.perMonthDisplay
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    headline
                    anchorBand
                    benefitChips
                    planSelector
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.md)
            }
        }
        .safeAreaInset(edge: .bottom) { footer }
        .screenBackground()
        .onAppear {
            shownAt = Date()
            env.analytics.track(.paywallShown)
            Task { await ensureProductsLoaded() }
        }
        .onChange(of: purchases.products.map(\.id)) { _, _ in selectDefaultPlan() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background && !didPurchase {
                env.analytics.track(.paywallResult(purchased: false, dwellSeconds: Date().timeIntervalSince(shownAt)))
            }
        }
        .alert(s.paywallPurchaseError, isPresented: $showError) {
            Button(s.continueLabel, role: .cancel) {}
        }
        .alert(s.paywallPurchasePending, isPresented: $showPending) {
            Button(s.continueLabel, role: .cancel) {}
        }
        .alert(s.paywallNothingToRestore, isPresented: $showNothingToRestore) {
            Button(s.continueLabel, role: .cancel) {}
        }
    }

    // MARK: - Top bar (Restore — Apple-required, always reachable)

    private var topBar: some View {
        HStack {
            Spacer()
            Button { restore() } label: {
                if isRestoring {
                    ProgressView().tint(Palette.textSecondary)
                } else {
                    Text(s.paywallRestoreShort)
                        .font(.body(14, weight: .semibold))
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            .disabled(isRestoring)
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.xxs)
    }

    // MARK: - Headline (compact)

    private var headline: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Kicker(s.paywallKicker)
            Text(s.paywallTitle)
                .font(.display(33, relativeTo: .largeTitle))
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(s.paywallSubtitle)
                .font(Typo.bodySm)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Price anchor (slim 2-column band)

    private var anchorBand: some View {
        HStack(spacing: 0) {
            anchorColumn(kicker: s.paywallAnchorTheyTake,
                         value: MoneyFormatter.leiWhole(env.appModel.savingsProfile.yearlyLoss),
                         unit: s.paywallPerYear, color: Palette.softRed)
            Rectangle().fill(Palette.hairline).frame(width: 1).padding(.vertical, Spacing.sm)
            anchorColumn(kicker: s.paywallAnchorFrom,
                         value: fromPerMonth ?? "—",
                         unit: s.paywallPerMonth, color: Palette.lime)
        }
        .pacaCard(Palette.surface)
    }

    private func anchorColumn(kicker: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(kicker)
                .font(.body(9.5, weight: .bold)).tracking(0.7)
                .foregroundStyle(color.opacity(0.85))
                .lineLimit(1).minimumScaleFactor(0.8)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.display(22, relativeTo: .title2))
                    .foregroundStyle(color)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text(unit)
                    .font(Typo.caption)
                    .foregroundStyle(color.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Benefit chips (value proof, 2×2)

    private var benefitChips: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: Spacing.sm, alignment: .leading),
                      GridItem(.flexible(), alignment: .leading)],
            spacing: Spacing.sm
        ) {
            ForEach(PaywallBenefit.allCases, id: \.self) { benefit in
                HStack(spacing: Spacing.xs) {
                    Image(systemName: benefit.symbol)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Palette.lime)
                        .frame(width: 26, height: 26)
                        .background(Palette.limeSoftFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Text(s.paywallChip(benefit))
                        .font(Typo.bodySm)
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1).minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: - Plans (clean, identical rows)

    @ViewBuilder
    private var planSelector: some View {
        switch purchases.loadState {
        case .loading, .idle:
            HStack(spacing: Spacing.xs) {
                ProgressView().tint(Palette.lime)
                Text(s.paywallLoadingPlans).font(Typo.bodySm).foregroundStyle(Palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
        case .failed where purchases.products.isEmpty:
            PacaButton(title: s.paywallRetry, kind: .dark) {
                Task { await purchases.loadProducts() }
            }
        default:
            VStack(spacing: Spacing.sm) {
                ForEach(purchases.products) { product in
                    PlanCard(product: product, isSelected: selectedProductID == product.id, loc: s) {
                        withAnimation(Motion.snappy) { selectedProductID = product.id }
                        env.analytics.track(.paywallPlanSelected(product.id))
                    }
                }
            }
            .padding(.top, Spacing.xs)   // room for the best-value ribbon
        }
    }

    // MARK: - Footer (fixed, fully visible)

    private var footer: some View {
        VStack(spacing: Spacing.xs) {
            if let product = selectedProduct {
                Text(s.paywallBillingNote(product.period, price: product.displayPrice))
                    .font(Typo.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            PacaButton(title: s.paywallCTA, kind: .lime, isLoading: isPurchasing,
                       isEnabled: selectedProductID != nil) {
                purchase()
            }
            restoreRow
            HStack(spacing: Spacing.xs) {
                Link(s.paywallLegalTerms, destination: AppConfiguration.termsURL)
                Text("·").foregroundStyle(Palette.textFaint)
                Link(s.paywallLegalPrivacy, destination: AppConfiguration.privacyURL)
                Text("·").foregroundStyle(Palette.textFaint)
                Text(s.paywallLegalCancel)
            }
            .font(Typo.caption)
            .foregroundStyle(Palette.textTertiary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xs)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(Palette.hairline).frame(height: 1), alignment: .top)
    }

    /// Prominent "Already subscribed? Restore purchase" affordance — the safety net for a real
    /// subscriber RevenueCat doesn't recognize yet (reinstall, new sign-in, sub under another id).
    /// On success `isSubscribed` flips and the app routes off the paywall automatically.
    private var restoreRow: some View {
        Button { restore() } label: {
            HStack(spacing: Spacing.xxs) {
                Text(s.paywallAlreadySubscribed)
                    .foregroundStyle(Palette.textSecondary)
                if isRestoring {
                    ProgressView().controlSize(.small).tint(Palette.lime)
                } else {
                    Text(s.paywallRestore)
                        .fontWeight(.semibold)
                        .foregroundStyle(Palette.lime)
                }
            }
            .font(Typo.bodySm)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableScale())
        .disabled(isRestoring)
    }

    // MARK: - Actions

    private func ensureProductsLoaded() async {
        if purchases.products.isEmpty { await purchases.loadProducts() }
        selectDefaultPlan()
    }

    private func selectDefaultPlan() {
        guard selectedProductID == nil else { return }
        selectedProductID = purchases.products.first(where: \.isBestValue)?.id ?? purchases.products.first?.id
    }

    private func purchase() {
        guard let id = selectedProductID else { return }
        isPurchasing = true
        env.analytics.track(.purchaseStarted(id))
        Task {
            let outcome = await purchases.purchase(id)
            isPurchasing = false
            switch outcome {
            case .purchased:
                didPurchase = true
                env.analytics.track(.purchaseCompleted(id))
                env.analytics.track(.paywallResult(purchased: true, dwellSeconds: Date().timeIntervalSince(shownAt)))
            case .failed:
                env.analytics.track(.purchaseFailed(id))
                showError = true
            case .cancelled:
                env.analytics.track(.purchaseCancelled(id))
            case .pending:
                // Ask-to-Buy / deferred bank authorization: the purchase isn't failed, it's
                // awaiting approval. Tell the user so the reverting button doesn't read as a
                // silent failure; the Transaction.updates listener unlocks the app once it settles.
                showPending = true
            }
        }
    }

    private func restore() {
        guard !isRestoring else { return }
        isRestoring = true
        Task {
            let ok = await purchases.restore()
            isRestoring = false
            env.analytics.track(.purchaseRestored)
            // On success, `isSubscribed` flips true and AppPhase routes off the paywall into the
            // app automatically — no manual dismissal needed. A false result is almost always "no
            // prior purchase on this account" (e.g. a reviewer tapping Restore first); show a
            // neutral message rather than the scary generic purchase error.
            if !ok { showNothingToRestore = true }
        }
    }
}

/// A clean, identical plan row: [radio] name + one description line · price + period.
/// The recommended (annual) plan is emphasized with a lime border + floating "best value"
/// ribbon; the selected plan gets a lime fill + filled check.
private struct PlanCard: View {
    let product: PaywallProduct
    let isSelected: Bool
    let loc: any Localization
    let action: () -> Void

    private var periodLabel: String {
        switch product.period {
        case .yearly: loc.paywallPerYear
        case .monthly: loc.paywallPerMonth
        case .lifetime: loc.paywallLifetimePeriod
        case .other: ""
        }
    }

    private var description: String {
        switch product.period {
        case .yearly:
            return [product.savingsPercent.map { loc.paywallSavePercent($0) },
                    product.perMonthDisplay.map { loc.paywallPricePerMonthFrom($0) }]
                .compactMap { $0 }
                .joined(separator: " · ")
        case .monthly: return loc.paywallMonthlyNote
        case .lifetime: return loc.paywallLifetimeNote
        case .other: return ""
        }
    }
    private var descriptionColor: Color {
        product.period == .yearly ? Palette.lime : Palette.textTertiary
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Palette.lime : Palette.textTertiary, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle().fill(Palette.lime).frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Palette.onLime)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(loc.paywallPlanName(product.period))
                        .font(Typo.headline)
                        .foregroundStyle(Palette.textPrimary)
                    if !description.isEmpty {
                        Text(description)
                            .font(Typo.caption)
                            .foregroundStyle(descriptionColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: Spacing.xs)

                VStack(alignment: .trailing, spacing: 0) {
                    Text(product.displayPrice)
                        .font(Typo.title)
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    if !periodLabel.isEmpty {
                        Text(periodLabel)
                            .font(Typo.caption)
                            .foregroundStyle(Palette.textTertiary)
                    }
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? Palette.limeSoftFill : Palette.surface,
                in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(
                        isSelected ? Palette.lime : (product.isBestValue ? Palette.limeSoftBorder : Palette.hairline),
                        lineWidth: (isSelected || product.isBestValue) ? 2 : 1
                    )
            )
            .overlay(alignment: .topLeading) {
                if product.isBestValue {
                    Text(loc.paywallBestValue)
                        .font(.body(9, weight: .bold)).tracking(0.5)
                        .foregroundStyle(Palette.onLime)
                        .padding(.vertical, 3).padding(.horizontal, 9)
                        .background(Palette.lime, in: Capsule())
                        .offset(x: Spacing.md, y: -9)
                }
            }
        }
        .buttonStyle(PressableScale())
        .accessibilityLabel("\(loc.paywallPlanName(product.period)), \(product.displayPrice)")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

#Preview {
    PreviewEnvironment(.preview(seedDemo: true, subscribed: false)) { PaywallView() }
}
