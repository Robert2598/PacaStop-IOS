//
//  UserProfile.swift
//  PacaStop
//
//  The single local account record. Everything is personal and on-device (SwiftData →
//  SQLite). Nothing here ever leaves the phone.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    // Identity / lifecycle
    var createdAt: Date
    var quitDate: Date
    var onboardingCompleted: Bool
    var authProviderRaw: String?
    /// The signed-in account's stable id (Clerk/Apple/demo). Lets the app tell a same-user
    /// re-login (keep the journey) from a different account (start fresh). Optional so existing
    /// installs migrate cleanly — a nil id is adopted by the first user who signs in.
    var authUserID: String?
    var displayName: String?

    // Onboarding answers (drive the savings math)
    var frequencyRaw: String
    var amountPerSession: Double

    // History preservation across relapses (§6.2)
    var relapseCount: Int
    /// Sum of everything saved during previous streaks, so history survives a reset.
    var lifetimeSavedBeforeReset: Double

    // ONJN self-exclusion (self-attested local flag, §6.7)
    var onjnEnrolled: Bool

    // Blocking configuration (§6.7) — the FamilyActivitySelection is stored opaquely as Data.
    var blockingMasterEnabled: Bool
    var blockOnlineCasino: Bool
    var blockSportsBetting: Bool
    var blockPoker: Bool
    var blockBettingAds: Bool
    /// Applies the bundled ONJN casino-domain denylist via the system web-content filter.
    var blockKnownBettingSites: Bool = true
    var blockedSelectionData: Data?

    // Local premium override used by the demo/returning-user shortcut.
    var premiumOverride: Bool

    init(
        createdAt: Date = Date(),
        quitDate: Date = Date(),
        onboardingCompleted: Bool = false,
        authProviderRaw: String? = nil,
        authUserID: String? = nil,
        displayName: String? = nil,
        frequencyRaw: String = Frequency.fewTimesWeek.rawValue,
        amountPerSession: Double = 200,
        relapseCount: Int = 0,
        lifetimeSavedBeforeReset: Double = 0,
        onjnEnrolled: Bool = false,
        blockingMasterEnabled: Bool = false,
        blockOnlineCasino: Bool = true,
        blockSportsBetting: Bool = true,
        blockPoker: Bool = true,
        blockBettingAds: Bool = true,
        blockKnownBettingSites: Bool = true,
        blockedSelectionData: Data? = nil,
        premiumOverride: Bool = false
    ) {
        self.createdAt = createdAt
        self.quitDate = quitDate
        self.onboardingCompleted = onboardingCompleted
        self.authProviderRaw = authProviderRaw
        self.authUserID = authUserID
        self.displayName = displayName
        self.frequencyRaw = frequencyRaw
        self.amountPerSession = amountPerSession
        self.relapseCount = relapseCount
        self.lifetimeSavedBeforeReset = lifetimeSavedBeforeReset
        self.onjnEnrolled = onjnEnrolled
        self.blockingMasterEnabled = blockingMasterEnabled
        self.blockOnlineCasino = blockOnlineCasino
        self.blockSportsBetting = blockSportsBetting
        self.blockPoker = blockPoker
        self.blockBettingAds = blockBettingAds
        self.blockKnownBettingSites = blockKnownBettingSites
        self.blockedSelectionData = blockedSelectionData
        self.premiumOverride = premiumOverride
    }
}

// MARK: - Derived, non-persisted conveniences

extension UserProfile {
    var frequency: Frequency {
        get { Frequency(rawValue: frequencyRaw) ?? .fewTimesWeek }
        set { frequencyRaw = newValue.rawValue }
    }

    var savingsProfile: SavingsProfile {
        SavingsProfile(frequency: frequency, amountPerSession: amountPerSession)
    }
}
