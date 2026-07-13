//
//  AppEnvironment.swift
//  PacaStop
//
//  The dependency-injection container. Builds the SwiftData store, the domain model,
//  and every service, choosing production SDKs when keys are configured and functional
//  fallbacks otherwise. A single instance is injected into the SwiftUI environment.
//

import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class AppEnvironment {
    let config: AppConfiguration
    let modelContainer: ModelContainer
    let loc: LocalizationStore
    let prefs: PreferencesStore
    let router: AppRouter

    let auth: any AuthService
    let purchases: any PurchaseService
    let analytics: any AnalyticsService
    let blocking: any BlockingService
    let notifications: any NotificationService
    let chat: any ChatService

    let appModel: AppModel

    static let schema = Schema([UserProfile.self, PanicEventRecord.self, BadgeUnlock.self, ChatMessage.self])

    init(
        inMemory: Bool = false,
        auth: (any AuthService)? = nil,
        purchases: (any PurchaseService)? = nil,
        analytics: (any AnalyticsService)? = nil,
        blocking: (any BlockingService)? = nil,
        notifications: (any NotificationService)? = nil,
        chat: (any ChatService)? = nil
    ) {
        // Register bundled fonts before any view renders, so cached availability checks are valid.
        FontRegistrar.registerAll()

        let config = AppConfiguration.default
        self.config = config

        let container = Self.makeContainer(inMemory: inMemory)
        self.modelContainer = container

        self.loc = LocalizationStore()
        self.prefs = PreferencesStore()
        self.router = AppRouter()

        // Service selection: production SDK when configured, functional fallback otherwise.
        // (Clerk / PostHog / RevenueCat adapters are wired in the SPM integration step.)
        self.auth = auth ?? ServiceFactory.makeAuth(config: config)
        self.purchases = purchases ?? ServiceFactory.makePurchases(config: config)
        self.analytics = analytics ?? ServiceFactory.makeAnalytics(config: config)
        self.blocking = blocking ?? ServiceFactory.makeBlocking(inMemory: inMemory)
        self.notifications = notifications ?? LocalNotificationService()
        self.chat = chat ?? ServiceFactory.makeChat(config: config, auth: self.auth)

        self.appModel = AppModel(
            modelContext: container.mainContext,
            analytics: self.analytics,
            blocking: self.blocking,
            notifications: self.notifications
        )

        // A Clerk session is restored asynchronously (its Keychain client loads after a delay),
        // so a returning user must run the same post-auth pipeline as an interactive sign-in —
        // otherwise RevenueCat/analytics identity and the per-user profile aren't re-associated
        // and a paying user can be bounced to the paywall. The synchronous case is handled in start().
        self.auth.setRestoreHandler { [weak self] user in self?.onAuthenticated(user) }
    }

    /// Kick off services that need to run at launch.
    func start() {
        FontRegistrar.registerAll()
        analytics.start()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        analytics.register(["app_version": version, "build": build, "platform": "ios"])
        analytics.setLanguage(loc.language)
        appModel.registerAnalyticsState()
        purchases.start()
        // A synchronously-restored session (local/preview auth) runs the full post-auth pipeline
        // now; an async Clerk restore fires it later via the handler registered in init.
        if let user = auth.currentUser {
            onAuthenticated(user)
        } else {
            analytics.identify(nil)
        }
        Task { await purchases.loadProducts() }
        appModel.applyBlocking()
        analytics.track(.appOpened)
        #if DEBUG
        applyDebugLaunch()
        #endif
    }

    #if DEBUG
    /// Drives the app to a specific phase for verification screenshots, e.g.
    /// `xcrun simctl launch booted com.pixelpaw.PacaStop -uiState home`.
    private func applyDebugLaunch() {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-uiState"), idx + 1 < args.count else { return }
        let state = args[idx + 1]

        func signIn() { onAuthenticated(auth.continueAsReturningUser()) }

        switch state {
        case "login": break
        case "onboarding": signIn()
        case "paywall": signIn(); appModel.completeOnboarding(frequency: .fewTimesWeek, amount: 200)
        case "home": signIn(); appModel.seedDemoAccount()
        case "progress": signIn(); appModel.seedDemoAccount(); router.mainTab = .progress
        case "settings": signIn(); appModel.seedDemoAccount(); router.mainTab = .settings
        default: break
        }
        if args.contains("-lang"), let li = args.firstIndex(of: "-lang"), li + 1 < args.count {
            loc.language = args[li + 1] == "en" ? .en : .ro
        }
    }
    #endif

    func onBecameActive() {
        appModel.onBecameActive()
        appModel.registerAnalyticsState()
        purchases.start()
    }

    /// Single hook after any sign-in: update the domain model and tell RevenueCat who the
    /// user is, so the mentor proxy's server-side `premium` check keys to the same Clerk id.
    func onAuthenticated(_ user: AuthUser) {
        appModel.onAuthenticated(user)
        purchases.identify(user.id)
    }

    /// Symmetric hook on sign-out / account deletion: drop the RevenueCat identity.
    func onSignedOut() {
        purchases.identify(nil)
    }

    var phase: AppPhase {
        AppPhase.resolve(
            isSignedIn: auth.isSignedIn,
            onboardingCompleted: appModel.profile.onboardingCompleted,
            hasPremiumOverride: appModel.hasPremiumOverride,
            entitlementReady: purchases.isReady,
            isSubscribed: purchases.isSubscribed,
            authRestoring: auth.isRestoringSession
        )
    }

    // MARK: - Builders

    private static func makeContainer(inMemory: Bool) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Last-resort in-memory container so the app never fails to launch.
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }
}

/// Chooses concrete service implementations. Isolated here so the SPM wiring step only
/// touches one file.
enum ServiceFactory {
    @MainActor
    static func makeAuth(config: AppConfiguration) -> any AuthService {
        #if canImport(ClerkKit)
        if let key = config.clerkPublishableKey { return ClerkAuthService(publishableKey: key) }
        #endif
        return LocalAuthService()
    }

    @MainActor
    static func makePurchases(config: AppConfiguration) -> any PurchaseService {
        #if DEBUG
        // Local paywall testing: force native StoreKit (uses the bundled .storekit config, or
        // its display-only fallback plans) so the paywall renders before RevenueCat offerings
        // are configured. Launch with `-localStore`.
        if ProcessInfo.processInfo.arguments.contains("-localStore") { return StoreKitPurchaseService() }
        #endif
        #if canImport(RevenueCat)
        if let key = config.revenueCatAPIKey { return RevenueCatPurchaseService(apiKey: key) }
        #endif
        return StoreKitPurchaseService()
    }

    @MainActor
    static func makeAnalytics(config: AppConfiguration) -> any AnalyticsService {
        #if canImport(PostHog)
        if let key = config.postHogAPIKey { return PostHogAnalyticsService(apiKey: key, host: config.postHogHost) }
        #endif
        return ConsoleAnalyticsService()
    }

    @MainActor
    static func makeBlocking(inMemory: Bool) -> any BlockingService {
        inMemory ? PreviewBlockingService() : ScreenTimeBlockingService()
    }

    /// The AI mentor: the real proxy-backed service when a backend URL is configured,
    /// otherwise a fully-working on-device canned mentor so the feature always runs.
    @MainActor
    static func makeChat(config: AppConfiguration, auth: any AuthService) -> any ChatService {
        if let url = config.aiBackendURL { return RemoteChatService(baseURL: url, auth: auth) }
        return PreviewChatService()
    }
}
