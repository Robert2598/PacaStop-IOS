//
//  Localization.swift
//  PacaStop
//
//  The typed string contract. Both RomanianStrings and EnglishStrings must satisfy
//  every member — so a string can never exist in one language and not the other.
//  Interpolated copy is expressed as functions; plain copy as properties.
//

import Foundation

protocol Localization {
    // MARK: Common
    var appName: String { get }
    var continueLabel: String { get }
    var closeLabel: String { get }
    var cancelLabel: String { get }
    var backLabel: String { get }
    var tabHome: String { get }
    var tabProgress: String { get }
    var tabMentor: String { get }
    var tabSettings: String { get }

    // MARK: Login
    var loginStat: String { get }
    var loginHeadline: String { get }
    var loginSub: String { get }
    var continueWithApple: String { get }
    var continueWithGoogle: String { get }
    var alreadyHaveAccount: String { get }
    var loginPrivacyNote: String { get }
    var loginTerms: String { get }
    var signInError: String { get }
    var signInErrorBody: String { get }

    // MARK: Onboarding
    func onboardingStep(_ n: Int, of total: Int) -> String
    var step1Title: String { get }
    var step1Sub: String { get }
    func frequencyLabel(_ f: Frequency) -> String
    var step2Title: String { get }
    var step2PerWeek: String { get }
    var step2PerYear: String { get }
    var step3Kicker: String { get }
    var step3Title: String { get }
    var step3Body: String { get }
    func step3Result(start: String, remaining: String) -> String
    var step3Replay: String { get }
    var step4Kicker: String { get }
    func step4YearlyLoss(_ amount: String) -> String
    var step4Flip: String { get }
    var step4CTA: String { get }
    var pledgeTitle: String { get }
    var pledgeBody: String { get }
    var pledgePhrase: String { get }
    var pledgePlaceholder: String { get }
    var pledgeHint: String { get }

    // MARK: Paywall
    var paywallKicker: String { get }
    var paywallTitle: String { get }
    var paywallSubtitle: String { get }
    func paywallBenefit(_ b: PaywallBenefit) -> String
    var paywallBestValue: String { get }
    func paywallSavePercent(_ percent: Int) -> String
    func paywallPlanName(_ period: PlanPeriod) -> String
    /// Loss-anchored marketing line under each plan (price vs. what gambling costs).
    func paywallPlanAnchor(_ period: PlanPeriod) -> String
    var paywallPerYear: String { get }
    var paywallPerMonth: String { get }
    var paywallLifetimePeriod: String { get }
    var paywallLifetimeNote: String { get }
    var paywallMonthlyNote: String { get }
    func paywallPricePerMonthFrom(_ price: String) -> String
    /// A clear price + terms line shown next to the buy button (transparency + conversion).
    func paywallBillingNote(_ period: PlanPeriod, price: String) -> String
    var paywallCTA: String { get }
    var paywallRestore: String { get }
    var paywallRestoreShort: String { get }
    /// Prompt for an existing subscriber who's being shown the paywall (e.g. reinstall / new
    /// sign-in) so they can reclaim access instead of paying again.
    var paywallAlreadySubscribed: String { get }
    var paywallAnchorTheyTake: String { get }
    var paywallAnchorFrom: String { get }
    func paywallChip(_ benefit: PaywallBenefit) -> String
    var paywallLegalTerms: String { get }
    var paywallLegalPrivacy: String { get }
    var paywallLegalCancel: String { get }
    var paywallTerms: String { get }
    var paywallNoCommitment: String { get }
    var paywallLoadingPlans: String { get }
    var paywallRetry: String { get }
    var paywallAnchorBridge: String { get }
    func paywallAnchorBridge(price: String) -> String
    var paywallPurchaseError: String { get }
    var paywallPurchasePending: String { get }
    var paywallNothingToRestore: String { get }

    // MARK: Home
    var homeYourRank: String { get }
    var daysUnit: String { get }
    func nextCarInDays(_ n: Int) -> String
    var topTierReached: String { get }
    var myGarage: String { get }
    var savedLabel: String { get }
    var savedSub: String { get }
    var feelUrgeKicker: String { get }
    var panicButton: String { get }
    func panicButtonSub(seconds: Int) -> String

    // MARK: Panic
    var panicTitle: String { get }
    func panicMessages(saved: String, streak: Int) -> [String]
    var secondsUnit: String { get }
    var panicRealityKicker: String { get }
    func panicRealityLine(liters: Int) -> String
    var panicHelplinePrefix: String { get }
    var panicHelpline: String { get }
    var panicGiveUp: String { get }
    var panicResistedTitle: String { get }
    var panicResistedSub: String { get }
    var panicResistedButton: String { get }

    // MARK: Progress
    var progressTitle: String { get }
    var progressSub: String { get }
    var badgesTitle: String { get }
    func badgeCount(_ unlocked: Int, of total: Int) -> String
    func badgeName(_ b: Badge) -> String
    var calculatorTitle: String { get }
    func calculatorSub(saved: String) -> String
    func savingsItemNoun(_ item: SavingsItem, count: Int) -> String
    var calculatorEmpty: String { get }

    // MARK: Notifications
    var reminderTitle: String { get }
    var reminderBody: String { get }

    // MARK: Settings
    var settingsTitle: String { get }
    var settingsProtectionGroup: String { get }
    var blockTitle: String { get }
    var blockDesc: String { get }
    var blockActive: String { get }
    var blockChooseApps: String { get }
    func blockAppsCount(_ n: Int) -> String
    var blockAuthNeeded: String { get }
    var blockKnownSitesTitle: String { get }
    func blockKnownSitesSub(_ n: Int) -> String
    var settingsStrongestStepGroup: String { get }
    var onjnTitle: String { get }
    var onjnDesc: String { get }
    var onjnEnroll: String { get }
    var onjnEnrolled: String { get }
    var onjnOpenOfficial: String { get }
    var onjnConfirmTitle: String { get }
    var onjnConfirmMessage: String { get }
    var onjnConfirmAction: String { get }
    var settingsPreferencesGroup: String { get }
    var languageLabel: String { get }
    var settingsSubscriptionGroup: String { get }
    var settingsRestoreLabel: String { get }
    var settingsRestoreSub: String { get }
    var settingsRestoreSuccess: String { get }
    var settingsAccountGroup: String { get }
    var relapseLabel: String { get }
    var relapseSub: String { get }
    var relapseConfirmTitle: String { get }
    var relapseConfirmMessage: String { get }
    var relapseConfirmAction: String { get }
    var signOutLabel: String { get }
    var signOutConfirmTitle: String { get }
    var signOutConfirmAction: String { get }
    var deleteAccountLabel: String { get }
    var deleteAccountSub: String { get }
    var deleteAccountConfirmTitle: String { get }
    var deleteAccountConfirmMessage: String { get }
    var deleteAccountConfirmAction: String { get }
    var deleteAccountError: String { get }

    // MARK: Mentor (AI chat)
    var chatTitle: String { get }
    var chatSubtitle: String { get }
    var chatDisclaimer: String { get }
    var chatEmptyTitle: String { get }
    var chatEmptyBody: String { get }
    var chatInputPlaceholder: String { get }
    var chatSendLabel: String { get }
    var chatTyping: String { get }
    var chatSuggestions: [String] { get }
    var chatCrisisTitle: String { get }
    var chatCrisisBody: String { get }
    var chatOpenPanic: String { get }
    var chatUrgeHint: String { get }
    var chatErrorGeneric: String { get }
    var chatErrorSignInAgain: String { get }
    var chatErrorPremium: String { get }
    var chatErrorRateLimited: String { get }
    var chatErrorOffline: String { get }

    // MARK: Garage
    var garageTitle: String { get }
    var garageSub: String { get }
    var garageNowDriving: String { get }
    func garageUnlocksAtDays(_ n: Int) -> String
    func carModel(_ tier: CarTier) -> String
    func rankName(_ tier: CarTier) -> String
}

/// The four paywall value props (kept as an enum so both languages stay in lock-step).
nonisolated enum PaywallBenefit: CaseIterable, Sendable {
    case block
    case savings
    case panic
    case privacy

    var symbol: String {
        switch self {
        case .block: "shield.lefthalf.filled"
        case .savings: "banknote.fill"
        case .panic: "hand.raised.fill"
        case .privacy: "lock.fill"
        }
    }
}
