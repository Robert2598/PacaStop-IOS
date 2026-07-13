//
//  AnalyticsService.swift
//  PacaStop
//
//  Privacy-respecting, event-only analytics for funnel optimization (onboarding + paywall).
//  No PII, no autocapture — just the named events below. PostHog (EU) is used when a key is
//  configured; otherwise events are logged locally and go nowhere.
//

import Foundation
import os

/// The complete event vocabulary. Keeping it a typed enum means the funnel can never drift.
nonisolated enum AnalyticsEvent: Sendable {
    case appOpened
    case loginShown
    case signInStarted(AuthProvider)
    case signInCompleted(AuthProvider)
    case signInFailed(AuthProvider)
    case demoEntered

    case onboardingStarted
    case onboardingStepViewed(Int)
    case onboardingStepCompleted(step: Int, seconds: Double)
    case onboardingBackTapped(fromStep: Int)
    case frequencySelected(Frequency)
    case amountChanged(Double)
    case houseEdgeReplayed
    case onboardingCompleted(seconds: Double)

    case paywallShown
    case paywallPlanSelected(String)
    case purchaseStarted(String)
    case purchaseCompleted(String)
    case purchaseFailed(String)
    case purchaseCancelled(String)
    case purchaseRestored
    case paywallResult(purchased: Bool, dwellSeconds: Double)
    case paywallDismissed

    case panicOpened
    case panicHeldOut(seconds: Int)
    case panicGaveUp(secondsRemaining: Int)

    case relapsed
    case onjnPageOpened
    case onjnEnrolled
    case blockingToggled(Bool)
    case blockAppsSelected(Int)
    case screenTimeAuthChanged(String)
    case badgeUnlocked(Badge)
    case languageChanged(AppLanguage)

    // AI mentor — behavioral only. Never the message text, never any financial data.
    case chatOpened
    case chatMessageSent
    case chatCrisisDetected
    case chatEscalated(String)

    var name: String {
        switch self {
        case .appOpened: "app_opened"
        case .loginShown: "login_shown"
        case .signInStarted: "sign_in_started"
        case .signInCompleted: "sign_in_completed"
        case .signInFailed: "sign_in_failed"
        case .demoEntered: "demo_entered"
        case .onboardingStarted: "onboarding_started"
        case .onboardingStepViewed: "onboarding_step_viewed"
        case .onboardingStepCompleted: "onboarding_step_completed"
        case .onboardingBackTapped: "onboarding_back_tapped"
        case .frequencySelected: "onboarding_frequency_selected"
        case .amountChanged: "onboarding_amount_changed"
        case .houseEdgeReplayed: "onboarding_house_edge_replayed"
        case .onboardingCompleted: "onboarding_completed"
        case .paywallShown: "paywall_shown"
        case .paywallPlanSelected: "paywall_plan_selected"
        case .purchaseStarted: "purchase_started"
        case .purchaseCompleted: "purchase_completed"
        case .purchaseFailed: "purchase_failed"
        case .purchaseCancelled: "purchase_cancelled"
        case .purchaseRestored: "purchase_restored"
        case .paywallResult: "paywall_result"
        case .paywallDismissed: "paywall_dismissed"
        case .panicOpened: "panic_opened"
        case .panicHeldOut: "panic_held_out"
        case .panicGaveUp: "panic_gave_up"
        case .relapsed: "relapsed"
        case .onjnPageOpened: "onjn_page_opened"
        case .onjnEnrolled: "onjn_enrolled"
        case .blockingToggled: "blocking_toggled"
        case .blockAppsSelected: "block_apps_selected"
        case .screenTimeAuthChanged: "screen_time_auth_changed"
        case .badgeUnlocked: "badge_unlocked"
        case .languageChanged: "language_changed"
        case .chatOpened: "chat_opened"
        case .chatMessageSent: "chat_message_sent"
        case .chatCrisisDetected: "chat_crisis_detected"
        case .chatEscalated: "chat_escalated"
        }
    }

    var properties: [String: String] {
        switch self {
        case .signInStarted(let p), .signInCompleted(let p), .signInFailed(let p):
            ["provider": p.rawValue]
        case .onboardingStepViewed(let n):
            ["step": String(n)]
        case .onboardingStepCompleted(let step, let seconds):
            ["step": String(step), "seconds": String(format: "%.1f", seconds)]
        case .onboardingBackTapped(let step):
            ["from_step": String(step)]
        case .frequencySelected(let f):
            // Coarse category only for the onboarding funnel — never the loss magnitude.
            ["frequency": f.rawValue]
        case .amountChanged:
            // The per-session amount is the user's loss magnitude; it must never leave the device.
            [:]
        case .onboardingCompleted(let seconds):
            ["seconds": String(format: "%.1f", seconds)]
        case .paywallPlanSelected(let id), .purchaseStarted(let id),
             .purchaseCompleted(let id), .purchaseFailed(let id), .purchaseCancelled(let id):
            ["product": id]
        case .paywallResult(let purchased, let dwell):
            ["purchased": String(purchased), "dwell_seconds": String(format: "%.1f", dwell)]
        case .panicHeldOut(let s):
            ["seconds": String(s)]
        case .panicGaveUp(let s):
            ["seconds_remaining": String(s)]
        case .blockingToggled(let on):
            ["enabled": String(on)]
        case .blockAppsSelected(let n):
            ["count": String(n)]
        case .screenTimeAuthChanged(let status):
            ["status": status]
        case .badgeUnlocked(let b):
            ["badge": b.rawValue]
        case .languageChanged(let l):
            ["language": l.rawValue]
        case .chatEscalated(let kind):
            // The escalation type (helpline / panic) — never any message content.
            ["kind": kind]
        default:
            [:]
        }
    }
}

@MainActor
protocol AnalyticsService: AnyObject {
    func start()
    func identify(_ userID: String?)
    func track(_ event: AnalyticsEvent)
    /// Super properties attached to every subsequent event (segmentation — non-financial).
    func register(_ properties: [String: String])
    func setLanguage(_ language: AppLanguage)
    func reset()
}

/// Default: logs to the unified log, sends nothing off-device.
@MainActor
final class ConsoleAnalyticsService: AnalyticsService {
    private let logger = Logger(subsystem: "com.pixelpaw.PacaStop", category: "Analytics")

    func start() { logger.debug("Analytics started (console).") }
    func identify(_ userID: String?) { logger.debug("identify \(userID ?? "nil", privacy: .public)") }
    func track(_ event: AnalyticsEvent) {
        logger.debug("event \(event.name, privacy: .public) \(event.properties.description, privacy: .public)")
    }
    func register(_ properties: [String: String]) {
        logger.debug("register \(properties.description, privacy: .public)")
    }
    func setLanguage(_ language: AppLanguage) { register(["language": language.rawValue]) }
    func reset() {}
}
