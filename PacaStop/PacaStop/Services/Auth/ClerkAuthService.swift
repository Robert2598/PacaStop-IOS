//
//  ClerkAuthService.swift
//  PacaStop
//
//  Production auth via Clerk (clerk-ios / ClerkKit 1.x). Active when a CLERK_PUBLISHABLE_KEY is
//  configured. Owns a single `AuthState`, derived from Clerk's session — the source of truth.
//  Enable the Apple + Google OAuth connections in the Clerk dashboard.
//

#if canImport(ClerkKit)
import Foundation
import Observation
import AuthenticationServices
import ClerkKit
import os

@Observable
@MainActor
final class ClerkAuthService: AuthService {
    private(set) var state: AuthState = .restoring
    private(set) var isWorking = false

    @ObservationIgnored private let logger = Logger(subsystem: "com.pixelpaw.PacaStop", category: "Auth")
    @ObservationIgnored private var restoreHandler: (@MainActor (AuthUser) -> Void)?
    /// How the current Clerk user signed in — Clerk doesn't expose our provider enum, so we
    /// remember the last interactive provider to label the restored session.
    @ObservationIgnored private var clerkProviderRaw = AuthProvider.google.rawValue

    init(publishableKey: String) {
        Clerk.configure(publishableKey: publishableKey)
        observeClerkSession()
    }

    // MARK: - Restore + live sync (Clerk session is the source of truth)

    func restoreSession() {
        if let clerkUser = Clerk.shared.user {
            state = .authenticated(makeUser(clerkUser))
        }
    }

    func setRestoreHandler(_ handler: @escaping @MainActor (AuthUser) -> Void) {
        restoreHandler = handler
        if case .authenticated(let user) = state { handler(user) }
    }

    /// Clerk restores its session from the Keychain *asynchronously* after `configure`, then
    /// keeps the token fresh. This resolves the initial state once that load reaches a definite
    /// conclusion, then mirrors Clerk's auth lifecycle so `state` is always in sync — the fix for
    /// the app showing "signed in" while Clerk actually had no session.
    private func observeClerkSession() {
        Task { @MainActor [weak self] in
            for _ in 0..<50 {
                if Clerk.shared.user != nil { break }
                if Clerk.shared.isLoaded && Clerk.shared.session == nil { break }
                try? await Task.sleep(for: .milliseconds(100))
            }
            guard let self else { return }

            if let clerkUser = Clerk.shared.user {
                self.state = .authenticated(self.makeUser(clerkUser))
                self.restoreHandler?(self.state.user!)
            } else {
                self.state = .signedOut
            }

            for await event in Clerk.shared.auth.events {
                switch event {
                case .signedOut, .accountDeleted:
                    // A real Clerk sign-out clears the session; keep only a local demo session.
                    if case .localOnly(let user) = self.state, user.provider == .demo { continue }
                    self.state = .signedOut
                default:
                    // A session appeared/refreshed (e.g. token refresh, cross-device) → reflect it.
                    if let clerkUser = Clerk.shared.user {
                        self.state = .authenticated(self.makeUser(clerkUser))
                    }
                }
            }
        }
    }

    // MARK: - Sign in

    func signIn(with provider: AuthProvider) async -> AuthOutcome {
        isWorking = true
        defer { isWorking = false }

        let clerkProvider: OAuthProvider
        switch provider {
        case .google: clerkProvider = .google
        case .apple: clerkProvider = .apple
        case .demo: return .cancelled
        }

        do {
            _ = try await Clerk.shared.auth.signInWithOAuth(provider: clerkProvider)
            if let clerkUser = Clerk.shared.user {
                clerkProviderRaw = provider.rawValue
                let user = makeUser(clerkUser)
                state = .authenticated(user)
                return .success(user)
            }
            logger.error("OAuth \(provider.rawValue, privacy: .public) returned no Clerk session")
            return .failed("no_session")
        } catch {
            if Self.isCancellation(error) { return .cancelled }
            logger.error("OAuth \(provider.rawValue, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            return .failed(error.localizedDescription)
        }
    }

    func completeExternalSignIn(provider: AuthProvider, id: String, displayName: String?) -> AuthUser {
        // Natively authenticated, but no backend exchange → local-only.
        let user = AuthUser(id: id, displayName: displayName, providerRaw: provider.rawValue)
        state = .localOnly(user)
        return user
    }

    /// Exchanges the native Apple identity token for a Clerk session. On success → `.authenticated`
    /// (the mentor works). On failure, Apple already vouched for the user natively, so we still
    /// admit them as `.localOnly` (they can use the local-first app; the mentor stays gated) — we
    /// never fake `.authenticated`, which was the hidden failure behind the mentor 401s.
    func completeAppleSignIn(idToken: String?, appleUserID: String, displayName: String?) async -> AuthOutcome {
        isWorking = true
        defer { isWorking = false }

        if let idToken {
            do {
                _ = try await Clerk.shared.auth.signInWithIdToken(idToken, provider: .apple)
                if let clerkUser = Clerk.shared.user {
                    clerkProviderRaw = AuthProvider.apple.rawValue
                    let user = makeUser(clerkUser)
                    state = .authenticated(user)
                    return .success(user)
                }
            } catch {
                logger.error("Apple→Clerk idToken exchange failed: \(error.localizedDescription, privacy: .public)")
            }
        }

        let user = AuthUser(id: appleUserID, displayName: displayName, providerRaw: AuthProvider.apple.rawValue)
        state = .localOnly(user)
        return .success(user)
    }

    func continueAsReturningUser() -> AuthUser {
        let user = AuthUser(id: "returning-user", displayName: nil, providerRaw: AuthProvider.demo.rawValue)
        state = .localOnly(user)
        return user
    }

    // MARK: - Sign out + delete

    func signOut() async {
        state = .signedOut               // reflected immediately (before the await) → UI updates now
        try? await Clerk.shared.auth.signOut()
    }

    func deleteAccount() async -> Bool {
        do {
            try await Clerk.shared.user?.delete()
            state = .signedOut
            return true
        } catch {
            return false
        }
    }

    // MARK: - Session token

    /// The Clerk session JWT the AI proxy verifies against Clerk's JWKS. In-memory only.
    func sessionToken() async -> String? {
        try? await Clerk.shared.session?.getToken()
    }

    /// The proxy returned 401 (or no token could be minted). Only a real backend session can go
    /// stale: re-check with Clerk, and if a token still can't be produced, drop to `.signedOut` so
    /// the app routes to a clean re-login. A `.localOnly` session (e.g. an Apple sign-in whose Clerk
    /// exchange didn't complete) never had a backend token — leave it be, or we'd loop the user
    /// through Login endlessly; that case is fixed by establishing the Clerk session, not by signing out.
    func handleUnauthorized() async {
        guard case .authenticated = state else { return }
        if (try? await Clerk.shared.session?.getToken()) == nil {
            state = .signedOut
        }
    }

    // MARK: - Helpers

    private func makeUser(_ clerkUser: ClerkKit.User) -> AuthUser {
        AuthUser(id: clerkUser.id, displayName: clerkUser.firstName, providerRaw: clerkProviderRaw)
    }

    /// Classifies a user-cancel of the web auth sheet (rethrown by ClerkKit) so a benign dismissal
    /// isn't reported as a sign-in failure. ClerkKit's own cancel helper is internal.
    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let asError = error as? ASWebAuthenticationSessionError, asError.code == .canceledLogin { return true }
        let ns = error as NSError
        return ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled
    }
}
#endif
