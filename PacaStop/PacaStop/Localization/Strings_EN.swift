//
//  Strings_EN.swift
//  PacaStop
//
//  English mirror. Keeps the same bite without literal-translating slang
//  ("fraier" → "the machine's fool", not "sucker").
//

import Foundation

struct EnglishStrings: Localization {
    // MARK: Common
    let appName = "PĂCĂSTOP"
    let continueLabel = "Continue"
    let closeLabel = "Close"
    let cancelLabel = "Cancel"
    let backLabel = "Back"
    let tabHome = "Home"
    let tabProgress = "Progress"
    let tabMentor = "Mentor"
    let tabSettings = "Settings"

    // MARK: Login
    let loginStat = "Romanians lose €2 billion a year to slot machines."
    let loginHeadline = "Don't be the machine's fool."
    let loginSub = "You block the betting apps, watch how much you keep, and stop yourself right before you do something stupid."
    let continueWithApple = "Continue with Apple"
    let continueWithGoogle = "Continue with Google"
    let alreadyHaveAccount = "I already have an account — enter the app"
    let loginPrivacyNote = "Everything stays private, on your phone."
    let loginTerms = "By continuing, you accept the Terms and Privacy Policy."
    let signInError = "Sign-in failed"
    let signInErrorBody = "We couldn't sign you in right now. Check your connection and try again."

    // MARK: Onboarding
    func onboardingStep(_ n: Int, of total: Int) -> String { "STEP \(n) OF \(total)" }
    let step1Title = "How often do you play the slots?"
    let step1Sub = "Be honest. Nobody's watching."
    func frequencyLabel(_ f: Frequency) -> String {
        switch f {
        case .daily: "Every day"
        case .fewTimesWeek: "A few times a week"
        case .onceWeek: "Once a week"
        case .fewTimesMonth: "A few times a month"
        }
    }
    let step2Title = "On average, how much do you leave each time?"
    let step2PerWeek = "Per week"
    let step2PerYear = "In a year"
    let step3Kicker = "SIMPLE MATH"
    let step3Title = "The machine is set to win. Always."
    let step3Body = "For every 100 lei you feed in, the machine gives back ~94 and keeps ~6. You win sometimes — just enough to keep you there — but you feed it all back, and the house always takes its cut."
    func step3Result(start: String, remaining: String) -> String { "You put in ~\(start) → you'd have ~\(remaining) left." }
    let step3Replay = "Tap to replay"
    let step4Kicker = "AT YOUR PACE"
    func step4YearlyLoss(_ amount: String) -> String { "In a year you give the machines \(amount)" }
    let step4Flip = "No more playing the fool. From today the money stays with you."
    let step4CTA = "START NOW"
    let pledgeTitle = "Ready to quit the machines for good?"
    let pledgeBody = "Type the exact phrase below. It's your oath, to yourself."
    let pledgePhrase = "I swear I'm done with the machines"
    let pledgePlaceholder = "Type your oath here…"
    let pledgeHint = "Type the phrase exactly to continue."

    // MARK: Paywall
    let paywallKicker = "LAST STEP"
    let paywallTitle = "Keep the machines away. For good."
    let paywallSubtitle = "Real blocking, a savings counter and a panic button — switched on right now."
    func paywallBenefit(_ b: PaywallBenefit) -> String {
        switch b {
        case .block: "Block every betting app and website"
        case .savings: "Watch, in real time, how much you keep"
        case .panic: "The panic button stops you at the urge"
        case .privacy: "Everything stays private, on your phone"
        }
    }
    let paywallBestValue = "BEST VALUE"
    func paywallSavePercent(_ percent: Int) -> String { "Save \(percent)%" }
    func paywallPlanName(_ period: PlanPeriod) -> String {
        switch period {
        case .yearly: "Yearly"
        case .monthly: "Monthly"
        case .lifetime: "Lifetime"
        case .other: ""
        }
    }
    func paywallPlanAnchor(_ period: PlanPeriod) -> String {
        switch period {
        case .monthly: "Cheaper than two spins at the slots"
        case .yearly: "What you lose in 3 minutes at the slots"
        case .lifetime: "Waaay less than one slots session"
        case .other: ""
        }
    }
    let paywallPerYear = "/year"
    let paywallPerMonth = "/month"
    let paywallLifetimePeriod = "once"
    let paywallLifetimeNote = "One-time payment, no renewal"
    let paywallMonthlyNote = "Flexible, monthly renewal"
    func paywallPricePerMonthFrom(_ price: String) -> String { "that's \(price)/month" }
    func paywallBillingNote(_ period: PlanPeriod, price: String) -> String {
        switch period {
        case .monthly: "\(price) per month · renews, cancel anytime"
        case .yearly: "\(price) per year · renews, cancel anytime"
        case .lifetime: "\(price) · one-time, lifetime access"
        case .other: price
        }
    }
    let paywallCTA = "Get me off the machines"
    let paywallRestore = "Restore purchase"
    let paywallRestoreShort = "Restore"
    let paywallAlreadySubscribed = "Already subscribed?"
    let paywallAnchorTheyTake = "THE MACHINES TAKE"
    let paywallAnchorFrom = "PĂCĂSTOP, FROM"
    func paywallChip(_ benefit: PaywallBenefit) -> String {
        switch benefit {
        case .block: "Real betting block"
        case .savings: "Savings counter"
        case .panic: "Panic button"
        case .privacy: "100% private"
        }
    }
    let paywallLegalTerms = "Terms"
    let paywallLegalPrivacy = "Privacy"
    let paywallLegalCancel = "Cancel in App Store"
    let paywallTerms = "Monthly and yearly plans auto-renew; Lifetime is a one-time payment. Cancel anytime in the App Store."
    let paywallNoCommitment = "No data sent to anyone. Just you and your money."
    let paywallLoadingPlans = "Loading plans…"
    let paywallRetry = "Try again"
    let paywallAnchorBridge = "PăcăStop costs a fraction of that."
    func paywallAnchorBridge(price: String) -> String { "PăcăStop costs you \(price) a year. A fraction of that — and it blocks them for good." }
    let paywallPurchaseError = "Something went wrong. Please try again."
    let paywallPurchasePending = "Your payment is awaiting approval. You'll get access as soon as it's confirmed."
    let paywallNothingToRestore = "We couldn't find a purchase to restore on this account."

    // MARK: Home
    let homeYourRank = "YOUR RANK"
    let daysUnit = "DAYS"
    func nextCarInDays(_ n: Int) -> String {
        n == 1 ? "Next car tomorrow" : "Next car in \(n) days"
    }
    let topTierReached = "You reached the top. You're a Legend."
    let myGarage = "My garage ›"
    let savedLabel = "YOU'VE KEPT"
    let savedSub = "since you stopped feeding the machine"
    let feelUrgeKicker = "FEEL THE URGE TO PLAY?"
    let panicButton = "PANIC BUTTON"
    func panicButtonSub(seconds: Int) -> String { "Press it and hold out \(seconds) seconds. That's all." }

    // MARK: Panic
    let panicTitle = "STOP. BREATHE."
    func panicMessages(saved: String, streak: Int) -> [String] {
        let streakText = streak == 1 ? "one day" : "\(streak) days"
        return [
            "The machine always wins. You're the only one who leaves with empty pockets.",
            "Feeling lucky? Luck is the story the house tells you so you'll put more in.",
            "In a minute the urge passes. The money, once given, never comes back.",
            "You've kept \(saved). Don't hand it back in a single night.",
            "What does your wife say when she sees the account empty again?",
            "You were smarter for \(streakText) straight. Don't ruin it now.",
            "The only sure win: close the phone now and walk away with your money.",
            "Do you really want to make the casinos even richer?",
            "Ready to punch the machine again after it cleans you out?",
            "Wouldn't it be better to calm down and buy flowers for someone you love with this money?",
            "Others can't put food on the table, and you want to throw your money at the machines?",
        ]
    }
    let secondsUnit = "seconds"
    let panicRealityKicker = "YOU WERE ABOUT TO GIVE"
    func panicRealityLine(liters: Int) -> String {
        "That's ~\(liters) litres of fuel, thrown at a screen that wins anyway."
    }
    let panicHelplinePrefix = "Need help?"
    let panicHelpline = "Responsible Gaming · 0800 800 099"
    let panicGiveUp = "I give up and open the app"
    let panicResistedTitle = "YOU HELD OUT."
    let panicResistedSub = "The urge passed. The money stayed with you. Your streak is intact."
    let panicResistedButton = "Back, stronger"

    // MARK: Progress
    let progressTitle = "My progress"
    let progressSub = "Your achievements and savings — private, just for you."
    let badgesTitle = "Badges"
    func badgeCount(_ unlocked: Int, of total: Int) -> String { "\(unlocked) / \(total)" }
    func badgeName(_ b: Badge) -> String {
        switch b {
        case .firstDay: "First day"
        case .cravingBeaten: "Craving beaten"
        case .oneWeek: "One week"
        case .thousandLei: "1,000 lei"
        case .oneMonth: "One month"
        case .fiveCravings: "5 cravings beaten"
        case .fiveThousandLei: "5,000 lei"
        case .ninetyDays: "90 days"
        case .oneYear: "A whole year"
        }
    }
    let calculatorTitle = "What that money buys"
    func calculatorSub(saved: String) -> String { "With \(saved) kept so far:" }
    func savingsItemNoun(_ item: SavingsItem, count: Int) -> String {
        switch item {
        case .restaurantMeal: count == 1 ? "good meal out" : "good meals out"
        case .phoneInstallment: count == 1 ? "payment on a new phone" : "payments on a new phone"
        case .fuelTank: count == 1 ? "full tank of fuel" : "full tanks of fuel"
        case .utilitiesMonth: count == 1 ? "month of utility bills" : "months of utility bills"
        case .groceryMonth: count == 1 ? "month of groceries" : "months of groceries"
        case .carInstallment: count == 1 ? "payment on a decent car" : "payments on a decent car"
        case .monthRent: count == 1 ? "month of rent" : "months of rent"
        case .vacationAbroad: count == 1 ? "holiday abroad" : "holidays abroad"
        }
    }
    let calculatorEmpty = "You're still saving. Your first reward is close — keep it up."

    let reminderTitle = "Don't be the machine's fool."
    let reminderBody = "Another day the money stays with you. Hold the streak."

    // MARK: Settings
    let settingsTitle = "Settings"
    let settingsProtectionGroup = "PROTECTION"
    let blockTitle = "Block betting"
    let blockDesc = "Block the betting apps and websites you choose."
    let blockActive = "Blocking active"
    let blockChooseApps = "Choose apps to block"
    func blockAppsCount(_ n: Int) -> String {
        switch n {
        case 0: "No apps selected"
        case 1: "1 app blocked"
        default: "\(n) apps blocked"
        }
    }
    let blockAuthNeeded = "Allow Screen Time access to switch blocking on."
    let blockKnownSitesTitle = "Block known betting sites"
    func blockKnownSitesSub(_ n: Int) -> String {
        "\(n) Romanian casino & betting sites from the official ONJN list."
    }
    let settingsStrongestStepGroup = "THE STRONGEST STEP"
    let onjnTitle = "ONJN self-exclusion"
    let onjnDesc = "By law, every licensed operator in Romania must stop letting you play. The request is filed officially with ONJN."
    let onjnEnroll = "Enrol me in self-exclusion"
    let onjnEnrolled = "You're enrolled. Operators won't let you in."
    let onjnOpenOfficial = "Open the official ONJN page"
    let onjnConfirmTitle = "Did you file the request?"
    let onjnConfirmMessage = "Only confirm after you've completed self-exclusion on the official ONJN page. It stays saved privately, on your phone."
    let onjnConfirmAction = "Yes, I enrolled"
    let settingsPreferencesGroup = "PREFERENCES"
    let languageLabel = "Language"
    let settingsSubscriptionGroup = "SUBSCRIPTION"
    let settingsRestoreLabel = "Restore purchases"
    let settingsRestoreSub = "Recover a subscription bought with this Apple ID."
    let settingsRestoreSuccess = "Your subscription was restored."
    let settingsAccountGroup = "ACCOUNT"
    let relapseLabel = "I relapsed — reset the streak"
    let relapseSub = "Honesty is better. History stays, we start again from zero."
    let relapseConfirmTitle = "Reset the streak?"
    let relapseConfirmMessage = "The streak goes back to zero and savings recount from now. History stays. Honesty is better."
    let relapseConfirmAction = "Reset streak"
    let signOutLabel = "Sign out"
    let signOutConfirmTitle = "Sign out?"
    let signOutConfirmAction = "Sign out"
    let deleteAccountLabel = "Delete account"
    let deleteAccountSub = "Permanently delete your account and all data on this phone."
    let deleteAccountConfirmTitle = "Delete your account for good?"
    let deleteAccountConfirmMessage = "Your account and all your data — streak, savings, badges, mentor chats — are gone for good. This can't be undone."
    let deleteAccountConfirmAction = "Delete permanently"
    let deleteAccountError = "Couldn't delete your account right now. Check your connection and try again."

    // MARK: Mentor (AI chat)
    let chatTitle = "Your mentor"
    let chatSubtitle = "Someone to talk to when the urge hits."
    let chatDisclaimer = "Not a therapist and not a substitute for a doctor. Here to listen and keep you on track. Nothing about your money ever leaves your phone."
    let chatEmptyTitle = "Say what's on your mind."
    let chatEmptyBody = "Hit by an urge, had a slip, or just need to clear your head? Write it — I'm listening."
    let chatInputPlaceholder = "Write what you feel…"
    let chatSendLabel = "Send"
    let chatTyping = "Mentor is typing…"
    let chatSuggestions = ["I've got an urge right now", "I relapsed", "Why should I stop?", "I feel tempted"]
    let chatCrisisTitle = "Talk to a person now"
    let chatCrisisBody = "If you feel in danger, call 112. For support: Responsible Gaming, free and confidential."
    let chatOpenPanic = "Open the panic button"
    let chatUrgeHint = "Hold out 60 seconds. The urge passes."
    let chatErrorGeneric = "Something went wrong. Try again."
    let chatErrorSignInAgain = "Your session expired. Sign out and back in to talk to the mentor."
    let chatErrorPremium = "The mentor is part of your subscription."
    let chatErrorRateLimited = "Too many messages too fast. Take a breath and come back."
    let chatErrorOffline = "No internet right now. The panic button still works."

    // MARK: Garage
    let garageTitle = "The garage"
    let garageSub = "Each rank, a better car. Hold the streak."
    let garageNowDriving = "NOW DRIVING"
    func garageUnlocksAtDays(_ n: Int) -> String { "Unlocks at \(n) days" }
    func carModel(_ tier: CarTier) -> String {
        switch tier {
        case .rabla: "Old Dacia banger"
        case .trezit: "Dacia"
        case .viteza: "VW Golf"
        case .serios: "BMW"
        case .smecher: "Mercedes"
        case .legenda: "Mercedes-AMG"
        }
    }
    func rankName(_ tier: CarTier) -> String {
        switch tier {
        case .rabla: "The Wreck"
        case .trezit: "You woke up"
        case .viteza: "Picking up speed"
        case .serios: "Serious guy"
        case .smecher: "Big shot"
        case .legenda: "Legend"
        }
    }
}
