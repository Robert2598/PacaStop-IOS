//
//  AppConfiguration.swift
//  PacaStop
//
//  Reads third-party keys (Clerk, PostHog, RevenueCat) from the environment or a
//  bundled `Secrets.plist`. When a key is absent, the app falls back to a fully
//  functional native/local implementation, so it always runs — keys just upgrade
//  the relevant service to its production SDK.
//

import Foundation

nonisolated struct AppConfiguration: Sendable {
    let clerkPublishableKey: String?
    let postHogAPIKey: String?
    let postHogHost: String
    let revenueCatAPIKey: String?
    /// The AI mentor proxy base URL. When absent, the app uses the on-device canned mentor.
    let aiBackendURL: URL?

    /// The official ONJN self-exclusion page (§ handover).
    static let onjnSelfExclusionURL = URL(string: "https://onjn.gov.ro/relatii-publice/autoexcludere/")!

    // Legal links shown on the paywall — required by Apple for auto-renewable subscriptions.
    // Terms defaults to Apple's Standard EULA (always valid); swap in a custom one if you have it.
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyURL = URL(string: "https://paca-stop.ro/confidentialitate")!

    static let `default`: AppConfiguration = load()

    private static func load() -> AppConfiguration {
        let env = ProcessInfo.processInfo.environment
        let plist = secretsPlist()

        func value(_ key: String) -> String? {
            if let v = env[key], !v.isEmpty { return v }
            if let v = plist?[key] as? String, !v.isEmpty, !v.hasPrefix("YOUR_") { return v }
            return nil
        }

        return AppConfiguration(
            clerkPublishableKey: value("CLERK_PUBLISHABLE_KEY"),
            postHogAPIKey: value("POSTHOG_API_KEY"),
            postHogHost: value("POSTHOG_HOST") ?? "https://eu.i.posthog.com",
            revenueCatAPIKey: value("REVENUECAT_API_KEY"),
            aiBackendURL: value("AI_BACKEND_URL").flatMap(URL.init(string:))
        )
    }

    private static func secretsPlist() -> [String: Any]? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }
        return dict
    }
}
