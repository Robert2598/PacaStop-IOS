//
//  RootView.swift
//  PacaStop
//
//  Switches between the top-level phases with a crossfade. The phase is fully derived, so
//  completing onboarding, purchasing, or signing out moves the app automatically.
//

import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()

            Group {
                switch env.phase {
                case .launch: SplashView()
                case .login: LoginView()
                case .onboarding: OnboardingView()
                case .paywall: PaywallView()
                case .main: MainTabView()
                }
            }
            .transition(.opacity)
        }
        .animation(Motion.smooth, value: env.phase)
        .preferredColorScheme(.dark) // The palette is dark-only; there is no light theme.
        .environment(\.locale, Locale(identifier: env.loc.language == .ro ? "ro_RO" : "en_US"))
    }
}

/// Brief splash shown while the entitlement resolves.
struct SplashView: View {
    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            VStack(spacing: Spacing.md) {
                LogoTile(size: 56)
                Text("PĂCĂSTOP")
                    .font(.display(28))
                    .tracking(2)
                    .foregroundStyle(Palette.textPrimary)
            }
        }
    }
}

/// The lime logo tile (a rotated dark diamond on lime), used on Login and Splash.
struct LogoTile: View {
    var size: CGFloat = 40

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(Palette.lime)
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.13, style: .continuous)
                    .fill(Palette.background)
                    .frame(width: size * 0.42, height: size * 0.42)
                    .rotationEffect(.degrees(45))
            )
    }
}
