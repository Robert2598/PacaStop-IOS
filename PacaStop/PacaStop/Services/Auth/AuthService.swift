//
//  AuthService.swift
//  PacaStop
//
//  The authentication seam. There is exactly ONE source of truth — `AuthState` — and every
//  routing/phase decision derives from it; no component keeps a parallel "am I signed in" flag.
//  The Clerk-backed implementation is used when a publishable key is configured; otherwise a
//  local implementation (real native Sign in with Apple + a local stub) is swapped in.
//

import Foundation
import Observation

nonisolated enum AuthProvider: String, Sendable {
    case apple
    case google
    case demo
}

nonisolated struct AuthUser: Codable, Equatable, Sendable {
    var id: String
    var displayName: String?
    var providerRaw: String

    var provider: AuthProvider { AuthProvider(rawValue: providerRaw) ?? .demo }
}

nonisolated enum AuthOutcome: Sendable {
    case success(AuthUser)
    case cancelled
    case failed(String)
}

/// The single source of truth for authentication status. Views and the router observe this and
/// derive everything from it — there is no separately-stored "currentUser"/"isSignedIn" that can
/// drift out of sync with the real backend session (the root cause of the earlier auth bugs).
nonisolated enum AuthState: Sendable, Equatable {
    /// A persisted session is still loading at launch — show the splash, not Login.
    case restoring
    /// No user — show Login.
    case signedOut
    /// Signed in with a live backend (Clerk) session: server features (the AI mentor) work.
    case authenticated(AuthUser)
    /// Signed in locally only — the demo shortcut, or a native sign-in whose backend exchange
    /// hasn't completed (e.g. offline Apple). The user is inside the app, but there is NO backend
    /// session yet, so the mentor stays gated until a real session is minted. This state makes
    /// that condition explicit instead of faking a successful sign-in.
    case localOnly(AuthUser)

    var user: AuthUser? {
        switch self {
        case .authenticated(let user), .localOnly(let user): user
        case .restoring, .signedOut: nil
        }
    }
    var isSignedIn: Bool { user != nil }
    var isRestoring: Bool { self == .restoring }
    /// Whether a backend session token can be minted — gates the premium AI mentor.
    var hasBackendSession: Bool {
        if case .authenticated = self { true } else { false }
    }
}

/// Abstract auth. Conformers are `@Observable @MainActor` classes that own a single `state`.
@MainActor
protocol AuthService: AnyObject {
    /// THE source of truth. `@Observable`, so views/router react automatically to changes.
    var state: AuthState { get }
    var isWorking: Bool { get }

    /// Reflects the currently-persisted session into `state` (idempotent).
    func restoreSession()
    /// Invoked once when a persisted session is restored *asynchronously* at launch (Clerk loads
    /// its Keychain client after a delay), so the app can run its post-auth pipeline for a
    /// returning user. No-op for local/preview auth, which restore synchronously in init.
    func setRestoreHandler(_ handler: @escaping @MainActor (AuthUser) -> Void)
    /// Provider-driven sign-in (Google/Apple web flow via Clerk, or a local stub).
    func signIn(with provider: AuthProvider) async -> AuthOutcome
    /// Records a natively-authenticated user as a local-only session (no backend exchange).
    func completeExternalSignIn(provider: AuthProvider, id: String, displayName: String?) -> AuthUser
    /// Completes native Sign in with Apple: the Clerk-backed service exchanges the identity token
    /// for a real session (`.authenticated`); if that exchange fails, the user is still admitted
    /// as `.localOnly` (Apple already vouched for them natively) — never a fake `.authenticated`.
    func completeAppleSignIn(idToken: String?, appleUserID: String, displayName: String?) async -> AuthOutcome
    /// The "Am deja cont" shortcut: enter as a returning/demo user (always local-only).
    func continueAsReturningUser() -> AuthUser
    /// Ends the session. Async + deterministic — no fire-and-forget race with a following sign-in.
    func signOut() async

    // Declared as requirements (with defaults below) so calls through `any AuthService` dispatch
    // dynamically to the Clerk-backed overrides rather than binding statically to the default.
    func sessionToken() async -> String?
    func deleteAccount() async -> Bool
    /// Called when the mentor proxy rejects our bearer token (401) or none could be minted. The
    /// Clerk service re-checks the session and, if a token still can't be produced, drops to
    /// `.signedOut` so the app routes to a clean re-login instead of a dead-end "session expired".
    func handleUnauthorized() async
}

extension AuthService {
    // Derived from the single source of truth — never a parallel copy.
    var currentUser: AuthUser? { state.user }
    var isSignedIn: Bool { state.isSignedIn }
    var isRestoringSession: Bool { state.isRestoring }
    /// True only when a real backend session exists (the AI mentor gate).
    var hasBackendSession: Bool { state.hasBackendSession }

    /// Default: local/preview auth restores synchronously in init, so there's nothing to hook.
    func setRestoreHandler(_ handler: @escaping @MainActor (AuthUser) -> Void) {}

    /// Default: no backend exchange — admit the natively-authenticated Apple user as local-only.
    /// `ClerkAuthService` overrides this to mint a real Clerk session when possible.
    func completeAppleSignIn(idToken: String?, appleUserID: String, displayName: String?) async -> AuthOutcome {
        .success(completeExternalSignIn(provider: .apple, id: appleUserID, displayName: displayName))
    }

    /// A short-lived bearer token authenticating the AI mentor proxy. Only a real Clerk session
    /// returns one; local/preview/demo return nil (and the app falls back to the canned mentor).
    func sessionToken() async -> String? { nil }

    /// Permanently deletes the account (App Store Guideline 5.1.1(v)). The Clerk-backed service
    /// deletes the remote user; local/preview auth has no server account, so it just clears the
    /// session. Returns true on success. Callers wipe local data after.
    func deleteAccount() async -> Bool {
        await signOut()
        return true
    }

    /// Default: local/preview/demo sessions have no backend to expire against — nothing to recover.
    func handleUnauthorized() async {}
}
