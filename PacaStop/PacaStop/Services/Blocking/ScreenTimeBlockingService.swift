//
//  ScreenTimeBlockingService.swift
//  PacaStop
//
//  Real app/site blocking via Apple's Screen Time stack:
//   • FamilyControls  — authorization + the app/site picker (used in Settings).
//   • ManagedSettings — the actual shield that blocks the chosen apps/sites.
//
//  Requires the `com.apple.developer.family-controls` entitlement (present) and, for
//  App Store distribution, Apple's approval of that entitlement. On the simulator the
//  frameworks link and the app runs, but authorization is limited — hence the graceful
//  `unavailable`/`denied` handling.
//

import Foundation
import Observation
import FamilyControls
import ManagedSettings
import os

@Observable
@MainActor
final class ScreenTimeBlockingService: BlockingService {
    private let store = ManagedSettingsStore(named: .init("com.pixelpaw.PacaStop.betting"))
    private let logger = Logger(subsystem: "com.pixelpaw.PacaStop", category: "Blocking")

    private(set) var authorizationStatus: BlockingAuthStatus = .notDetermined

    init() { refreshAuthorizationStatus() }

    func refreshAuthorizationStatus() {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .notDetermined: authorizationStatus = .notDetermined
        case .denied: authorizationStatus = .denied
        case .approved: authorizationStatus = .approved
        @unknown default: authorizationStatus = .notDetermined
        }
    }

    func requestAuthorization() async -> BlockingAuthStatus {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = .approved
        } catch {
            logger.error("Screen Time authorization failed: \(error.localizedDescription, privacy: .public)")
            // On simulator / missing entitlement this throws — treat as unavailable so the UI can explain.
            authorizationStatus = .unavailable
        }
        return authorizationStatus
    }

    func apply(selectionData: Data?, categories: BlockingCategories, enabled: Bool) {
        guard enabled, authorizationStatus.isApproved,
              let selection = ScreenTimeSelectionCoder.decode(selectionData) else {
            clearShield()
            return
        }

        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens

        logger.notice("Shield applied: \(selection.applicationTokens.count) apps, \(selection.categoryTokens.count) categories, \(selection.webDomainTokens.count) domains.")
    }

    /// Blocks the bundled ONJN list of known betting/casino domains via the system web-content
    /// filter. `.specific(...)` is the denylist policy ("blocks the specified domains") — not to
    /// be confused with `.all(except:)`, which is an allowlist that would block everything else.
    func applyKnownSitesFilter(enabled: Bool) {
        guard enabled, authorizationStatus.isApproved else {
            store.webContent.blockedByFilter = nil   // unmanage → restores normal browsing
            return
        }
        let domains = Set(CasinoBlocklist.uniqueDomains.map { WebDomain(domain: $0) })
        store.webContent.blockedByFilter = .specific(domains)
        logger.notice("Known-sites web filter applied: \(domains.count) domains.")
    }

    func selectionCount(from data: Data?) -> Int {
        ScreenTimeSelectionCoder.count(data)
    }

    private func clearShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
}

/// Bridges `FamilyActivitySelection` (from the picker) to the opaque `Data` the model stores.
enum ScreenTimeSelectionCoder {
    static func encode(_ selection: FamilyActivitySelection) -> Data? {
        try? JSONEncoder().encode(selection)
    }

    static func decode(_ data: Data?) -> FamilyActivitySelection? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    static func count(_ data: Data?) -> Int {
        guard let selection = decode(data) else { return 0 }
        return selection.applicationTokens.count
            + selection.categoryTokens.count
            + selection.webDomainTokens.count
    }
}
