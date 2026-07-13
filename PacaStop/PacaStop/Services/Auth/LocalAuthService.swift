//
//  LocalAuthService.swift
//  PacaStop
//
//  The default, always-available auth used when no Clerk publishable key is configured. Real
//  native Sign in with Apple flows through `completeExternalSignIn`; Google is a local stub.
//  Every local session is `.localOnly` — there is no backend session, so the app uses the canned
//  mentor. Sessions persist on-device only. `ClerkAuthService` replaces this when a key is set.
//

import Foundation
import Observation

@Observable
@MainActor
final class LocalAuthService: AuthService {
    private static let storageKey = "pacastop.auth.user"

    private(set) var state: AuthState = .signedOut
    private(set) var isWorking = false

    init() { restoreSession() }

    func restoreSession() {
        guard let data = Keychain.get(Self.storageKey),
              let user = try? JSONDecoder().decode(AuthUser.self, from: data) else {
            state = .signedOut
            return
        }
        state = .localOnly(user)
    }

    func signIn(with provider: AuthProvider) async -> AuthOutcome {
        isWorking = true
        defer { isWorking = false }
        // Small delay so the UI reads as a real handshake.
        try? await Task.sleep(for: .milliseconds(350))
        let user = AuthUser(
            id: provider.rawValue + "-" + UUID().uuidString,
            displayName: nil,
            providerRaw: provider.rawValue
        )
        persist(user)
        return .success(user)
    }

    func completeExternalSignIn(provider: AuthProvider, id: String, displayName: String?) -> AuthUser {
        // Preserve a previously captured name (Apple only sends it on first authorization).
        let name = displayName ?? state.user?.displayName
        let user = AuthUser(id: id, displayName: name, providerRaw: provider.rawValue)
        persist(user)
        return user
    }

    func continueAsReturningUser() -> AuthUser {
        let user = AuthUser(id: "returning-user", displayName: nil, providerRaw: AuthProvider.demo.rawValue)
        persist(user)
        return user
    }

    func signOut() async {
        state = .signedOut
        Keychain.delete(Self.storageKey)
    }

    private func persist(_ user: AuthUser) {
        state = .localOnly(user)
        if let data = try? JSONEncoder().encode(user) {
            Keychain.set(data, for: Self.storageKey)
        }
    }
}

// MARK: - Preview / test double

@Observable
@MainActor
final class PreviewAuthService: AuthService {
    private(set) var state: AuthState
    var isWorking = false

    init(signedIn: Bool = false) {
        state = signedIn
            ? .authenticated(AuthUser(id: "preview", displayName: "Robert", providerRaw: AuthProvider.apple.rawValue))
            : .signedOut
    }

    func restoreSession() {}
    func signIn(with provider: AuthProvider) async -> AuthOutcome {
        let user = AuthUser(id: "preview", displayName: nil, providerRaw: provider.rawValue)
        state = .authenticated(user)
        return .success(user)
    }
    func completeExternalSignIn(provider: AuthProvider, id: String, displayName: String?) -> AuthUser {
        let user = AuthUser(id: id, displayName: displayName, providerRaw: provider.rawValue)
        state = .localOnly(user)
        return user
    }
    func continueAsReturningUser() -> AuthUser {
        let user = AuthUser(id: "returning", displayName: nil, providerRaw: AuthProvider.demo.rawValue)
        state = .localOnly(user)
        return user
    }
    func signOut() async { state = .signedOut }
}
