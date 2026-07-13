//
//  BlockingService.swift
//  PacaStop
//
//  Abstracts the "block betting apps/sites" mechanism so the UI never depends on the
//  Screen Time frameworks directly. The real implementation shields a user-chosen set of
//  apps/sites; the preview double no-ops so the app runs anywhere.
//

import Foundation
import Observation

nonisolated enum BlockingAuthStatus: Sendable {
    case notDetermined
    case approved
    case denied
    case unavailable      // e.g. simulator or entitlement missing

    var isApproved: Bool { self == .approved }
}

/// The four category toggles surfaced in Settings.
nonisolated struct BlockingCategories: Equatable, Sendable {
    var onlineCasino: Bool
    var sportsBetting: Bool
    var poker: Bool
    var bettingAds: Bool

    static let allOn = BlockingCategories(onlineCasino: true, sportsBetting: true, poker: true, bettingAds: true)
}

@MainActor
protocol BlockingService: AnyObject {
    var authorizationStatus: BlockingAuthStatus { get }

    func refreshAuthorizationStatus()
    func requestAuthorization() async -> BlockingAuthStatus
    /// Applies (or clears) the shield for the given opaque selection.
    func apply(selectionData: Data?, categories: BlockingCategories, enabled: Bool)
    /// Applies (or clears) the system web-content filter that blocks the bundled ONJN list of
    /// known Romanian betting/casino domains. Independent of the user's app-picker shield.
    func applyKnownSitesFilter(enabled: Bool)
    /// Number of apps/categories/domains in an opaque selection (for the UI summary).
    func selectionCount(from data: Data?) -> Int
}

// MARK: - Preview / test double

@Observable
@MainActor
final class PreviewBlockingService: BlockingService {
    var authorizationStatus: BlockingAuthStatus

    init(status: BlockingAuthStatus = .approved) { authorizationStatus = status }

    func refreshAuthorizationStatus() {}
    func requestAuthorization() async -> BlockingAuthStatus {
        authorizationStatus = .approved
        return authorizationStatus
    }
    func apply(selectionData: Data?, categories: BlockingCategories, enabled: Bool) {}
    func applyKnownSitesFilter(enabled: Bool) {}
    func selectionCount(from data: Data?) -> Int { data == nil ? 0 : 3 }
}
