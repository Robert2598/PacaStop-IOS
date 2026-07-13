//
//  PostHogAnalyticsService.swift
//  PacaStop
//
//  Production analytics. Inert until the PostHog SPM package is added AND a POSTHOG_API_KEY
//  is configured — otherwise events are logged locally and go nowhere. Privacy-respecting:
//  autocapture, session replay, and screen views are all OFF; only the typed funnel events
//  are sent. Defaults to EU hosting.
//
//  Setup: add `https://github.com/PostHog/posthog-ios`.
//

#if canImport(PostHog)
import Foundation
import PostHog

@MainActor
final class PostHogAnalyticsService: AnalyticsService {
    private let apiKey: String
    private let host: String

    init(apiKey: String, host: String) {
        self.apiKey = apiKey
        self.host = host
    }

    func start() {
        let config = PostHogConfig(projectToken: apiKey, host: host)
        config.captureApplicationLifecycleEvents = false
        config.captureScreenViews = false
        PostHogSDK.shared.setup(config)
    }

    func identify(_ userID: String?) {
        guard let userID else { return }
        PostHogSDK.shared.identify(userID)
    }

    func track(_ event: AnalyticsEvent) {
        PostHogSDK.shared.capture(event.name, properties: event.properties)
    }

    func register(_ properties: [String: String]) {
        PostHogSDK.shared.register(properties)
    }

    func setLanguage(_ language: AppLanguage) {
        PostHogSDK.shared.register(["language": language.rawValue])
    }

    func reset() {
        PostHogSDK.shared.reset()
    }
}
#endif
