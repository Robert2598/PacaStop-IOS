//
//  AppRouter.swift
//  PacaStop
//
//  Top-level flow. The phase is derived from auth + onboarding + entitlement so the app is
//  always in a consistent state; the router additionally holds the main tab selection.
//

import SwiftUI
import Observation

enum AppPhase: Equatable {
    case launch          // resolving entitlement
    case login
    case onboarding
    case paywall
    case main

    /// Login → Onboarding → (hard) Paywall → Main. Demo override skips the paywall.
    static func resolve(
        isSignedIn: Bool,
        onboardingCompleted: Bool,
        hasPremiumOverride: Bool,
        entitlementReady: Bool,
        isSubscribed: Bool,
        authRestoring: Bool = false
    ) -> AppPhase {
        // While a persisted session is still loading, hold on the splash rather than flashing
        // Login — otherwise a returning user briefly sees Login before jumping into the app.
        guard isSignedIn else { return authRestoring ? .launch : .login }
        guard onboardingCompleted else { return .onboarding }
        if hasPremiumOverride { return .main }
        guard entitlementReady else { return .launch }
        return isSubscribed ? .main : .paywall
    }
}

@Observable
@MainActor
final class AppRouter {
    var mainTab: MainTab = .home
}
