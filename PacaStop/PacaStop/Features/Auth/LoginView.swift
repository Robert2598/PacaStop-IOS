//
//  LoginView.swift
//  PacaStop
//
//  Get in fast, privately, reassure it's discreet (§5.1). Apple + Google both run through Clerk's
//  OAuth flow (so each yields a real session for the mentor); plus a returning-user/demo shortcut.
//

import SwiftUI

struct LoginView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(LocalizationStore.self) private var loc

    @State private var showAuthError = false
    /// The underlying auth failure reason, surfaced in the alert so a real-device failure is
    /// diagnosable instead of showing only a generic message.
    @State private var authErrorDetail: String?

    private var s: any Localization { loc.s }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                statPill
                Spacer(minLength: Spacing.xl)
                Text(s.loginHeadline)
                    .font(Typo.heroHuge)
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(s.loginSub)
                    .font(Typo.bodyLg)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Spacing.xl)
                buttons
                fineprint
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.lg)
            .frame(minHeight: UIScreen.main.bounds.height - 60, alignment: .top)
        }
        .scrollBounceBehavior(.basedOnSize)
        .screenBackground()
        .onAppear { env.analytics.track(.loginShown) }
        .alert(s.signInError, isPresented: $showAuthError) {
            Button(s.closeLabel, role: .cancel) {}
        } message: { Text(authErrorDetail ?? s.signInErrorBody) }
    }

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            LogoTile(size: 40)
            Text(s.appName)
                .font(.display(26))
                .tracking(2)
                .foregroundStyle(Palette.textPrimary)
        }
    }

    private var statPill: some View {
        HStack(spacing: Spacing.xs) {
            PulsingDot(color: Palette.red)
            Text(s.loginStat)
                .font(.body(12.5, weight: .semibold))
                .foregroundStyle(Palette.softRed)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .background(Palette.redSoftFill, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.redSoftBorder, lineWidth: 1))
    }

    private var buttons: some View {
        VStack(spacing: Spacing.sm) {
            PacaButton(title: s.continueWithApple, kind: .white, icon: "apple.logo", isLoading: env.auth.isWorking) {
                signInApple()
            }

            PacaButton(title: s.continueWithGoogle, kind: .dark, icon: "globe", isLoading: env.auth.isWorking) {
                signInGoogle()
            }

            Button {
                enterDemo()
            } label: {
                Text(s.alreadyHaveAccount)
                    .font(.body(14, weight: .semibold))
                    .foregroundStyle(Palette.lime)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(PressableScale())
        }
    }

    private var fineprint: some View {
        VStack(spacing: Spacing.xxs) {
            Text(s.loginTerms)
            Text(s.loginPrivacyNote)
        }
        .font(Typo.caption)
        .foregroundStyle(Palette.textTertiary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xs)
    }

    // MARK: - Actions

    private func signInApple() {
        env.analytics.track(.signInStarted(.apple))
        Task {
            // Apple runs through Clerk's OAuth flow, exactly like Google — so it yields a real Clerk
            // session (and mentor token), not a local-only fallback. The Apple connection must be
            // enabled in the Clerk dashboard.
            let outcome = await env.auth.signIn(with: .apple)
            switch outcome {
            case .success(let user):
                env.onAuthenticated(user)
                env.analytics.track(.signInCompleted(.apple))
            case .cancelled:
                env.analytics.track(.signInFailed(.apple))
            case .failed(let reason):
                // Surface the real reason so a device failure is diagnosable, not generic.
                env.analytics.track(.signInFailed(.apple))
                authErrorDetail = reason
                showAuthError = true
            }
        }
    }

    private func signInGoogle() {
        env.analytics.track(.signInStarted(.google))
        Task {
            let outcome = await env.auth.signIn(with: .google)
            switch outcome {
            case .success(let user):
                env.onAuthenticated(user)
                env.analytics.track(.signInCompleted(.google))
            case .cancelled:
                env.analytics.track(.signInFailed(.google))
            case .failed(let reason):
                // Surface the real reason so a device failure is diagnosable, not generic.
                env.analytics.track(.signInFailed(.google))
                authErrorDetail = reason
                showAuthError = true
            }
        }
    }

    private func enterDemo() {
        env.analytics.track(.demoEntered)
        let user = env.auth.continueAsReturningUser()
        env.appModel.onAuthenticated(user)
        #if DEBUG
        // Testing only: seed a populated, premium account. In release a returning user goes
        // through the normal onboarding → paywall (with Restore) flow — never a free bypass.
        env.appModel.seedDemoAccount()
        #endif
    }
}

/// A softly pulsing dot (the red "live loss" indicator).
struct PulsingDot: View {
    var color: Color
    var size: CGFloat = 8
    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.9), radius: pulsing ? 5 : 0)
            .scaleEffect(pulsing ? 1.15 : 0.85)
            .onAppear { withAnimation(Motion.pulse) { pulsing = true } }
            .accessibilityHidden(true)
    }
}

#Preview {
    PreviewEnvironment(.preview(seedDemo: false, subscribed: false)) { LoginView() }
}
