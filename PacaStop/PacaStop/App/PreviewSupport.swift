//
//  PreviewSupport.swift
//  PacaStop
//
//  Shared helpers so every screen's #Preview gets a consistent, populated environment.
//

import SwiftUI
import SwiftData

// Available in all configurations because `#Preview` blocks (which reference these) are
// compiled in Release too. Harmless dead code at runtime — only Xcode Previews instantiate it.
extension AppEnvironment {
    /// An in-memory environment with a populated, premium, signed-in demo account.
    @MainActor
    static func preview(seedDemo: Bool = true, subscribed: Bool = true, language: AppLanguage = .ro) -> AppEnvironment {
        let env = AppEnvironment(
            inMemory: true,
            auth: PreviewAuthService(signedIn: true),
            purchases: PreviewPurchaseService(subscribed: subscribed),
            analytics: ConsoleAnalyticsService(),
            blocking: PreviewBlockingService()
        )
        env.loc.language = language
        if seedDemo { env.appModel.seedDemoAccount() }
        return env
    }
}

/// Injects a preview environment into a view under test.
struct PreviewEnvironment<Content: View>: View {
    let env: AppEnvironment
    @ViewBuilder var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.env = .preview()
        self.content = content()
    }

    init(_ env: AppEnvironment, @ViewBuilder content: () -> Content) {
        self.env = env
        self.content = content()
    }

    var body: some View {
        content
            .environment(env)
            .environment(env.loc)
            .environment(env.prefs)
            .environment(env.router)
            .environment(env.appModel)
            .modelContainer(env.modelContainer)
            .preferredColorScheme(.dark)
    }
}
