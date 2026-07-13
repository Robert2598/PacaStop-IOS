//
//  AppModel.swift
//  PacaStop
//
//  The single source of truth for the user's journey: wraps the SwiftData store, exposes
//  live derived values from the domain "brain", and orchestrates the services. Injected
//  via @Environment; everything runs on the main actor.
//

import Foundation
import Observation
import SwiftData
import os

@Observable
@MainActor
final class AppModel {
    // Dependencies
    @ObservationIgnored let modelContext: ModelContext
    @ObservationIgnored let analytics: any AnalyticsService
    @ObservationIgnored let blocking: any BlockingService
    @ObservationIgnored let notifications: any NotificationService
    @ObservationIgnored private let logger = Logger(subsystem: "com.pixelpaw.PacaStop", category: "AppModel")

    // Persisted state (the single account record)
    private(set) var profile: UserProfile

    // Cached counters (kept in sync on mutation)
    private(set) var cravingsBeaten: Int = 0
    private(set) var earnedBadges: Set<Badge> = []

    /// A badge freshly unlocked this session, awaiting a celebration in the UI.
    var pendingBadgeCelebration: Badge?

    init(
        modelContext: ModelContext,
        analytics: any AnalyticsService,
        blocking: any BlockingService,
        notifications: any NotificationService
    ) {
        self.modelContext = modelContext
        self.analytics = analytics
        self.blocking = blocking
        self.notifications = notifications
        self.profile = Self.loadOrCreateProfile(in: modelContext)
        refreshCaches()
    }

    // MARK: - Live derived values (the brain)

    var savingsProfile: SavingsProfile { profile.savingsProfile }

    func saved(at now: Date = Date()) -> Double {
        SavingsCalculator.saved(profile: savingsProfile, since: profile.quitDate, now: now)
    }

    /// Lifetime savings including everything kept before relapses (for sticky money badges).
    func lifetimeSaved(at now: Date = Date()) -> Double {
        saved(at: now) + profile.lifetimeSavedBeforeReset
    }

    var ratePerSecond: Double { SavingsCalculator.ratePerSecond(profile: savingsProfile) }

    func streakDays(at now: Date = Date()) -> Int {
        StreakCalculator.days(since: profile.quitDate, now: now)
    }

    func currentTier(at now: Date = Date()) -> CarTier {
        CarLadder.currentTier(streakDays: streakDays(at: now))
    }

    func badgeContext(at now: Date = Date()) -> BadgeContext {
        BadgeContext(
            streakDays: streakDays(at: now),
            savedLei: lifetimeSaved(at: now),
            cravingsBeaten: cravingsBeaten
        )
    }

    var blockingCategories: BlockingCategories {
        BlockingCategories(
            onlineCasino: profile.blockOnlineCasino,
            sportsBetting: profile.blockSportsBetting,
            poker: profile.blockPoker,
            bettingAds: profile.blockBettingAds
        )
    }

    var blockedSelectionCount: Int {
        blocking.selectionCount(from: profile.blockedSelectionData)
    }

    // MARK: - Journey mutations

    /// The account whose journey is currently active (`nil` only before the first sign-in).
    /// Every per-account query keys on this. See [[project-pacastop]].
    var activeOwner: String? { profile.authUserID }

    /// Called on every sign-in — interactive (LoginView) and on a restored session at launch.
    /// Switches to (or creates) the profile that belongs to this account, so a *different*
    /// account on the same device gets its own onboarding/streak/savings/badges, and the SAME
    /// account resumes exactly where it left off. Isolation is real: each account owns a distinct
    /// `UserProfile` row plus the panic/badge/chat records tagged with its `authUserID`.
    func onAuthenticated(_ user: AuthUser) {
        switchToProfile(for: user)
        profile.authProviderRaw = user.providerRaw
        if let name = user.displayName { profile.displayName = name }
        // The demo shortcut grants a local premium override; a real sign-in must never inherit
        // it — real entitlement comes from StoreKit/RevenueCat.
        if user.provider != .demo { profile.premiumOverride = false }
        save()
        registerAnalyticsState()
        analytics.identify(user.id)
    }

    /// Resolves the active profile for a sign-in, in priority order:
    /// 1. An existing profile for this exact account → resume it (same-user re-login).
    /// 2. The unclaimed profile → claim it. This covers the first sign-in on a fresh install AND
    ///    the first sign-in after upgrading from the single-profile era (that lone profile has no
    ///    owner yet). Either way its legacy records are adopted so nothing is lost.
    /// 3. Otherwise a brand-new account on a device that already holds other accounts → fresh slate.
    private func switchToProfile(for user: AuthUser) {
        let uid = user.id

        if let mine = fetchProfile(authUserID: uid) {
            setActiveProfile(mine)
            adoptOrphanRecords(to: uid)   // claim any pre-isolation rows still tagged to no one
            return
        }
        if let unclaimed = fetchProfile(authUserID: nil) {
            unclaimed.authUserID = uid
            setActiveProfile(unclaimed)
            adoptOrphanRecords(to: uid)
            return
        }
        let fresh = UserProfile(authUserID: uid)
        modelContext.insert(fresh)
        setActiveProfile(fresh)
    }

    private func fetchProfile(authUserID uid: String?) -> UserProfile? {
        let descriptor: FetchDescriptor<UserProfile>
        if let uid {
            descriptor = FetchDescriptor(predicate: #Predicate { $0.authUserID == uid })
        } else {
            descriptor = FetchDescriptor(predicate: #Predicate { $0.authUserID == nil })
        }
        return try? modelContext.fetch(descriptor).first
    }

    private func setActiveProfile(_ newProfile: UserProfile) {
        profile = newProfile
        save()
        refreshCaches()             // cached counters follow the now-active account
    }

    /// One-time migration from the single-profile era: panic/badge/chat rows created then have no
    /// owner. The first account to sign in after the upgrade claims them so its history survives.
    /// Runs harmlessly (no-op) on every later sign-in, since there are no orphans left to adopt.
    private func adoptOrphanRecords(to uid: String) {
        var changed = false
        if let rows = try? modelContext.fetch(
            FetchDescriptor<PanicEventRecord>(predicate: #Predicate { $0.ownerID == nil })
        ), !rows.isEmpty {
            rows.forEach { $0.ownerID = uid }; changed = true
        }
        if let rows = try? modelContext.fetch(
            FetchDescriptor<BadgeUnlock>(predicate: #Predicate { $0.ownerID == nil })
        ), !rows.isEmpty {
            rows.forEach { $0.ownerID = uid }; changed = true
        }
        if let rows = try? modelContext.fetch(
            FetchDescriptor<ChatMessage>(predicate: #Predicate { $0.ownerID == nil })
        ), !rows.isEmpty {
            rows.forEach { $0.ownerID = uid }; changed = true
        }
        if changed { save(); refreshCaches() }
    }

    /// Sign-out is reversible: it keeps the on-device journey (streak, onboarding, savings,
    /// badges, blocking selection) so the SAME account resumes exactly where it left off on
    /// re-login. It only drops the demo premium bypass and transient UI state. Screen Time
    /// shields stay applied — protection shouldn't lapse just because the user signed out.
    /// A different account signing in (onAuthenticated) or account deletion is what wipes data.
    func endSession() {
        profile.premiumOverride = false   // real subs restore via RevenueCat; demo bypass never persists
        pendingBadgeCelebration = nil
        save()
        analytics.identify(nil)
    }

    /// Permanently wipes the CURRENT account's on-device records (App Store Guideline 5.1.1(v)) —
    /// never plain sign-out, and never other accounts' data on a shared device. Leaves a fresh
    /// unclaimed profile as the bootstrap for whoever signs in next.
    func wipeAllLocalData() {
        let owner = profile.authUserID
        try? modelContext.delete(model: PanicEventRecord.self, where: #Predicate { $0.ownerID == owner })
        try? modelContext.delete(model: BadgeUnlock.self, where: #Predicate { $0.ownerID == owner })
        try? modelContext.delete(model: ChatMessage.self, where: #Predicate { $0.ownerID == owner })
        modelContext.delete(profile)
        let fresh = UserProfile()
        modelContext.insert(fresh)
        profile = fresh
        save()
        refreshCaches()
        pendingBadgeCelebration = nil
        applyBlocking()          // clears any active Screen Time shields (master now false)
        analytics.identify(nil)
    }

    func completeOnboarding(frequency: Frequency, amount: Double) {
        profile.frequency = frequency
        profile.amountPerSession = amount
        profile.quitDate = Date()
        profile.onboardingCompleted = true
        // Onboarding is the moment the blocker "turns on" (§5.2 step 4).
        profile.blockingMasterEnabled = true
        save()
        applyBlocking()
        // Segmentation (category, not the loss amount) so the paywall funnel is analyzable.
        analytics.register(["frequency": frequency.rawValue])
        evaluateBadges()
    }

    /// Registers non-financial user-state as analytics super-properties for segmentation.
    func registerAnalyticsState() {
        analytics.register([
            "streak_bucket": Self.streakBucket(streakDays()),
            "has_premium": String(profile.premiumOverride),
            "blocking_active": String(profile.blockingMasterEnabled),
            "onjn_enrolled": String(profile.onjnEnrolled),
            "relapses": String(profile.relapseCount),
        ])
    }

    private static func streakBucket(_ days: Int) -> String {
        switch days {
        case 0: "0"
        case 1..<7: "1-6"
        case 7..<30: "7-29"
        case 30..<90: "30-89"
        case 90..<365: "90-364"
        default: "365+"
        }
    }

    func relapse() {
        let now = Date()
        profile.lifetimeSavedBeforeReset += saved(at: now)
        profile.quitDate = now
        profile.relapseCount += 1
        save()
        analytics.track(.relapsed)
    }

    func recordPanic(heldOut: Bool, seconds: Int) {
        let record = PanicEventRecord(heldOut: heldOut, configuredSeconds: seconds, ownerID: profile.authUserID)
        modelContext.insert(record)
        if heldOut { cravingsBeaten += 1 }
        save()
        if heldOut {
            analytics.track(.panicHeldOut(seconds: seconds))
            evaluateBadges()
        }
    }

    func enrollONJN() {
        guard !profile.onjnEnrolled else { return }
        profile.onjnEnrolled = true
        save()
        analytics.track(.onjnEnrolled)
    }

    // MARK: - Blocking

    func setBlockingMaster(_ enabled: Bool) {
        profile.blockingMasterEnabled = enabled
        save()
        applyBlocking()
        analytics.track(.blockingToggled(enabled))
    }

    func setCategory(_ keyPath: ReferenceWritableKeyPath<UserProfile, Bool>, _ value: Bool) {
        profile[keyPath: keyPath] = value
        save()
        applyBlocking()
    }

    func setBlockedSelection(data: Data?) {
        profile.blockedSelectionData = data
        save()
        applyBlocking()
        analytics.track(.blockAppsSelected(blockedSelectionCount))
    }

    func applyBlocking() {
        blocking.apply(
            selectionData: profile.blockedSelectionData,
            categories: blockingCategories,
            enabled: profile.blockingMasterEnabled
        )
        // The ONJN known-sites web filter rides on the master switch + its own toggle.
        blocking.applyKnownSitesFilter(
            enabled: profile.blockingMasterEnabled && profile.blockKnownBettingSites
        )
    }

    func setBlockKnownSites(_ enabled: Bool) {
        profile.blockKnownBettingSites = enabled
        save()
        applyBlocking()
        analytics.track(.blockingToggled(enabled))
    }

    // MARK: - Badges

    @discardableResult
    func evaluateBadges(at now: Date = Date()) -> [Badge] {
        let ctx = badgeContext(at: now)
        var newlyUnlocked: [Badge] = []
        for badge in Badge.allCases where !earnedBadges.contains(badge) {
            if BadgeEngine.isUnlocked(badge, in: ctx) {
                earnedBadges.insert(badge)
                modelContext.insert(BadgeUnlock(badge: badge, unlockedAt: now, ownerID: profile.authUserID))
                analytics.track(.badgeUnlocked(badge))
                newlyUnlocked.append(badge)
            }
        }
        if !newlyUnlocked.isEmpty {
            save()
            pendingBadgeCelebration = newlyUnlocked.last
        }
        return newlyUnlocked
    }

    // MARK: - Lifecycle hooks

    func onBecameActive() {
        blocking.refreshAuthorizationStatus()
        evaluateBadges()
    }

    // MARK: - Demo / returning user

    /// Seeds a populated, premium-unlocked account (~Day 12) so the app looks alive (§6.2).
    func seedDemoAccount() {
        let now = Date()
        profile.quitDate = now.addingTimeInterval(-12 * SavingsCalculator.secondsPerDay)
        profile.frequency = .fewTimesWeek
        profile.amountPerSession = 200
        profile.onboardingCompleted = true
        profile.blockingMasterEnabled = true
        profile.premiumOverride = true
        profile.lifetimeSavedBeforeReset = 0
        // A couple of beaten cravings so the "Poftă învinsă" badge is earned.
        for offset in [1.0, 3.0] {
            let record = PanicEventRecord(
                date: now.addingTimeInterval(-offset * SavingsCalculator.secondsPerDay),
                heldOut: true, configuredSeconds: 60, ownerID: profile.authUserID
            )
            modelContext.insert(record)
        }
        save()
        refreshCaches()
        evaluateBadges()
        applyBlocking()
    }

    /// The demo/returning-user premium bypass is a DEBUG-only convenience for development. In a
    /// release build it is ALWAYS ignored, so the paywall can never be skipped by a leftover
    /// override — premium in production is gated solely by the real StoreKit entitlement.
    var hasPremiumOverride: Bool {
        #if DEBUG
        profile.premiumOverride
        #else
        false
        #endif
    }

    // MARK: - Persistence

    private func save() {
        do { try modelContext.save() }
        catch { logger.error("SwiftData save failed: \(error.localizedDescription, privacy: .public)") }
    }

    private func refreshCaches() {
        // Scope every counter to the active account so a shared device never mixes journeys.
        let owner = profile.authUserID
        cravingsBeaten = (try? modelContext.fetchCount(
            FetchDescriptor<PanicEventRecord>(predicate: #Predicate { $0.heldOut && $0.ownerID == owner })
        )) ?? 0

        let unlocks = (try? modelContext.fetch(
            FetchDescriptor<BadgeUnlock>(predicate: #Predicate { $0.ownerID == owner })
        )) ?? []
        earnedBadges = Set(unlocks.compactMap(\.badge))
    }

    private static func loadOrCreateProfile(in context: ModelContext) -> UserProfile {
        if let existing = try? context.fetch(FetchDescriptor<UserProfile>()).first {
            return existing
        }
        let profile = UserProfile()
        context.insert(profile)
        try? context.save()
        return profile
    }
}
