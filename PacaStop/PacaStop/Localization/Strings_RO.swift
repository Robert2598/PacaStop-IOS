//
//  Strings_RO.swift
//  PacaStop
//
//  Romanian (primary). Firm, blunt, money- and pride-driven — never insulting.
//  Slang is on-brand: fraier, aparate, păcănele, șmecher, cashu'.
//

import Foundation

/// Romanian: a numeral takes the linking word "de" before its noun when its last two
/// digits are 0 or ≥ 20 ("30 de zile", "100 de litri"), but not for 1–19 ("7 zile").
private func roDe(_ n: Int) -> String {
    let m = abs(n) % 100
    return (m == 0 || m >= 20) ? "de " : ""
}

struct RomanianStrings: Localization {
    // MARK: Common
    let appName = "PĂCĂSTOP"
    let continueLabel = "Continuă"
    let closeLabel = "Închide"
    let cancelLabel = "Renunță"
    let backLabel = "Înapoi"
    let tabHome = "Acasă"
    let tabProgress = "Progres"
    let tabMentor = "Mentor"
    let tabSettings = "Setări"

    // MARK: Login
    let loginStat = "Românii pierd 2 miliarde € pe an la aparate."
    let loginHeadline = "Nu fi fraierul aparatelor."
    let loginSub = "Blochezi pariurile, vezi cât strângi și te oprești fix când erai pe cale să faci prostia."
    let continueWithApple = "Continuă cu Apple"
    let continueWithGoogle = "Continuă cu Google"
    let alreadyHaveAccount = "Am deja cont — intră în aplicație"
    let loginPrivacyNote = "Totul rămâne privat, pe telefonul tău."
    let loginTerms = "Continuând, accepți Termenii și Politica de confidențialitate."
    let signInError = "Conectarea nu a reușit"
    let signInErrorBody = "Nu ne-am putut conecta acum. Verifică internetul și mai încearcă o dată."

    // MARK: Onboarding
    func onboardingStep(_ n: Int, of total: Int) -> String { "PASUL \(n) DIN \(total)" }
    let step1Title = "Cât de des joci la păcănele?"
    let step1Sub = "Fii sincer. Nu te vede nimeni."
    func frequencyLabel(_ f: Frequency) -> String {
        switch f {
        case .daily: "Zilnic"
        case .fewTimesWeek: "De câteva ori pe săptămână"
        case .onceWeek: "O dată pe săptămână"
        case .fewTimesMonth: "De câteva ori pe lună"
        }
    }
    let step2Title = "Cât lași, în medie, de fiecare dată?"
    let step2PerWeek = "Pe săptămână"
    let step2PerYear = "Într-un an"
    let step3Kicker = "MATEMATICA SIMPLĂ"
    let step3Title = "Aparatul e reglat să câștige. Mereu."
    let step3Body = "Din fiecare 100 de lei băgați, aparatul îți dă înapoi ~94 și oprește ~6. Câștigi uneori — cât să rămâi acolo — dar bagi totul înapoi, iar casa ia mereu partea ei."
    func step3Result(start: String, remaining: String) -> String { "Ai băgat ~\(start) → ți-au mai rămas ~\(remaining)." }
    let step3Replay = "Apasă ca să rerulezi"
    let step4Kicker = "CU RITMUL TĂU"
    func step4YearlyLoss(_ amount: String) -> String { "Într-un an dai aparatelor \(amount)" }
    let step4Flip = "Gata cu fraierul. De azi banii rămân la tine."
    let step4CTA = "ÎNCEP ACUM"
    let pledgeTitle = "Ești gata să renunți complet la aparate?"
    let pledgeBody = "Scrie exact fraza de mai jos. E jurământul tău, față de tine."
    let pledgePhrase = "Mă jur că mă las de aparate"
    let pledgePlaceholder = "Scrie jurământul aici…"
    let pledgeHint = "Scrie fraza exact ca să continui."

    // MARK: Paywall
    let paywallKicker = "ULTIMUL PAS"
    let paywallTitle = "Ține aparatele departe. Definitiv."
    let paywallSubtitle = "Blocaj real, contor de economii și buton de panică — pornite chiar acum."
    func paywallBenefit(_ b: PaywallBenefit) -> String {
        switch b {
        case .block: "Blochezi toate aplicațiile și site-urile de pariuri"
        case .savings: "Vezi în timp real cât strângi stând deștept"
        case .panic: "Butonul de panică te oprește fix la impuls"
        case .privacy: "Totul rămâne privat, pe telefonul tău"
        }
    }
    let paywallBestValue = "CEL MAI BUN PREȚ"
    func paywallSavePercent(_ percent: Int) -> String { "Economisești \(percent)%" }
    func paywallPlanName(_ period: PlanPeriod) -> String {
        switch period {
        case .yearly: "Anual"
        case .monthly: "Lunar"
        case .lifetime: "Pe viață"
        case .other: ""
        }
    }
    func paywallPlanAnchor(_ period: PlanPeriod) -> String {
        switch period {
        case .monthly: "Mai ieftin decât 2 mâini la aparate"
        case .yearly: "Cât pierzi în 3 minute la aparate"
        case .lifetime: "Muuult mai puțin decât o sesiune de aparate"
        case .other: ""
        }
    }
    let paywallPerYear = "/an"
    let paywallPerMonth = "/lună"
    let paywallLifetimePeriod = "o dată"
    let paywallLifetimeNote = "Plată unică, fără reînnoire"
    let paywallMonthlyNote = "Flexibil, reînnoire lunară"
    func paywallPricePerMonthFrom(_ price: String) -> String { "adică \(price)/lună" }
    func paywallBillingNote(_ period: PlanPeriod, price: String) -> String {
        switch period {
        case .monthly: "\(price) pe lună · se reînnoiește, anulezi oricând"
        case .yearly: "\(price) pe an · se reînnoiește, anulezi oricând"
        case .lifetime: "\(price) · o singură plată, acces pe viață"
        case .other: price
        }
    }
    let paywallCTA = "Vreau să scap de aparate"
    let paywallRestore = "Restaurează achiziția"
    let paywallRestoreShort = "Restaurează"
    let paywallAlreadySubscribed = "Ai deja abonament?"
    let paywallAnchorTheyTake = "APARATELE ÎȚI IAU"
    let paywallAnchorFrom = "PĂCĂSTOP, DE LA"
    func paywallChip(_ benefit: PaywallBenefit) -> String {
        switch benefit {
        case .block: "Blocaj real pariuri"
        case .savings: "Contor de economii"
        case .panic: "Buton de panică"
        case .privacy: "100% privat"
        }
    }
    let paywallLegalTerms = "Termeni"
    let paywallLegalPrivacy = "Confidențialitate"
    let paywallLegalCancel = "Anulezi din App Store"
    let paywallTerms = "Planurile lunar și anual se reînnoiesc automat; Pe viață e o plată unică. Anulezi oricând din App Store."
    let paywallNoCommitment = "Fără date trimise nimănui. Doar tu și banii tăi."
    let paywallLoadingPlans = "Se încarcă planurile…"
    let paywallRetry = "Reîncearcă"
    let paywallAnchorBridge = "PăcăStop costă o fracțiune din atât."
    func paywallAnchorBridge(price: String) -> String { "PăcăStop te costă \(price) pe an. O fracțiune din atât — și le blochezi de tot." }
    let paywallPurchaseError = "Ceva n-a mers. Mai încearcă o dată."
    let paywallPurchasePending = "Plata așteaptă aprobare. Primești acces imediat ce e confirmată."
    let paywallNothingToRestore = "Nu am găsit nicio achiziție de restaurat pe acest cont."

    // MARK: Home
    let homeYourRank = "RANGUL TĂU"
    let daysUnit = "ZILE"
    func nextCarInDays(_ n: Int) -> String {
        n == 1 ? "Următoarea mașină mâine" : "Următoarea mașină în \(n) \(roDe(n))zile"
    }
    let topTierReached = "Ai ajuns în vârf. Ești Legendă."
    let myGarage = "Garajul meu ›"
    let savedLabel = "AI STRÂNS"
    let savedSub = "de când nu mai hrănești aparatul"
    let feelUrgeKicker = "SIMȚI IMPULSUL SĂ JOCI?"
    let panicButton = "BUTON DE PANICĂ"
    func panicButtonSub(seconds: Int) -> String { "Apasă și rezistă \(seconds) de secunde. Atât." }

    // MARK: Panic
    let panicTitle = "STAI. RESPIRĂ."
    func panicMessages(saved: String, streak: Int) -> [String] {
        let streakText = streak == 1 ? "o zi" : "\(streak) \(roDe(streak))zile"
        return [
            "Aparatul câștigă mereu. Tu ești singurul care pleacă cu buzunarele goale.",
            "Te simți norocos? Norocul e povestea pe care ți-o spune casa ca să rebagi.",
            "Peste un minut pofta trece. Banii, dacă îi dai, nu se mai întorc.",
            "Ai strâns \(saved). Nu-i da înapoi într-o singură seară.",
            "Ce zice nevastă-ta când vede iar contul gol?",
            "Ai fost mai deștept \(streakText) la rând. Nu strica totul acum.",
            "Singurul câștig sigur: închizi telefonul acum și pleci cu banii.",
            "Chiar vrei să îmbogățești cazinourile și mai mult?",
            "Ești gata să dai iar cu pumnul în aparat după ce pierzi?",
            "Nu mai bine te liniștești și iei un buchet de flori pentru cineva drag cu banii ăștia?",
            "Alții n-au ce pune pe masă, iar tu vrei să arunci banii la aparate?",
        ]
    }
    let secondsUnit = "secunde"
    let panicRealityKicker = "ERAI PE CALE SĂ DAI"
    func panicRealityLine(liters: Int) -> String {
        "Adică ~\(liters) \(roDe(liters))litri de benzină, aruncați pe un ecran care oricum câștigă."
    }
    let panicHelplinePrefix = "Ai nevoie de ajutor?"
    let panicHelpline = "Joc Responsabil · 0800 800 099"
    let panicGiveUp = "Renunț și deschid aparatul"
    let panicResistedTitle = "AI REZISTAT."
    let panicResistedSub = "Pofta a trecut. Banii au rămas la tine. Seria e intactă."
    let panicResistedButton = "Înapoi, mai puternic"

    // MARK: Progress
    let progressTitle = "Progresul meu"
    let progressSub = "Realizările și economiile tale — private, doar pentru tine."
    let badgesTitle = "Insigne"
    func badgeCount(_ unlocked: Int, of total: Int) -> String { "\(unlocked) / \(total)" }
    func badgeName(_ b: Badge) -> String {
        switch b {
        case .firstDay: "Prima zi"
        case .cravingBeaten: "Poftă învinsă"
        case .oneWeek: "O săptămână"
        case .thousandLei: "1.000 lei"
        case .oneMonth: "O lună"
        case .fiveCravings: "5 pofte învinse"
        case .fiveThousandLei: "5.000 lei"
        case .ninetyDays: "90 de zile"
        case .oneYear: "Un an întreg"
        }
    }
    let calculatorTitle = "Ce-ți luai cu banii ăștia"
    func calculatorSub(saved: String) -> String { "Cu \(saved) strânși până acum:" }
    func savingsItemNoun(_ item: SavingsItem, count: Int) -> String {
        switch item {
        case .restaurantMeal: count == 1 ? "masă bună în oraș" : "mese bune în oraș"
        case .phoneInstallment: count == 1 ? "rată la un telefon nou" : "rate la un telefon nou"
        case .fuelTank: count == 1 ? "plin de benzină" : "plinuri de benzină"
        case .utilitiesMonth: count == 1 ? "lună de facturi" : "luni de facturi"
        case .groceryMonth: count == 1 ? "lună de cumpărături" : "luni de cumpărături"
        case .carInstallment: count == 1 ? "rată la o mașină decentă" : "rate la o mașină decentă"
        case .monthRent: count == 1 ? "lună de chirie" : "luni de chirie"
        case .vacationAbroad: count == 1 ? "vacanță în străinătate" : "vacanțe în străinătate"
        }
    }
    let calculatorEmpty = "Încă strângi. Prima recompensă e aproape — ține-o tot așa."

    let reminderTitle = "Nu fi fraierul aparatelor."
    let reminderBody = "Încă o zi în care banii rămân la tine. Ține seria."

    // MARK: Settings
    let settingsTitle = "Setări"
    let settingsProtectionGroup = "PROTECȚIE"
    let blockTitle = "Blochează pariurile"
    let blockDesc = "Blochezi aplicațiile și site-urile de pariuri pe care le alegi tu."
    let blockActive = "Blocaj activ"
    let blockChooseApps = "Alege aplicațiile de blocat"
    func blockAppsCount(_ n: Int) -> String {
        switch n {
        case 0: "Nicio aplicație selectată"
        case 1: "1 aplicație blocată"
        default: "\(n) aplicații blocate"
        }
    }
    let blockAuthNeeded = "Activează accesul la Timp de Utilizare ca să pornești blocajul."
    let blockKnownSitesTitle = "Blochează site-urile de pariuri cunoscute"
    func blockKnownSitesSub(_ n: Int) -> String {
        "\(n) \(roDe(n))site-uri .ro de cazino și pariuri, din lista oficială ONJN."
    }
    let settingsStrongestStepGroup = "CEL MAI PUTERNIC PAS"
    let onjnTitle = "Autoexcludere ONJN"
    let onjnDesc = "Prin lege, fiecare operator licențiat din România e obligat să nu te mai lase să joci. Cererea se depune oficial la ONJN."
    let onjnEnroll = "Înscrie-mă în autoexcludere"
    let onjnEnrolled = "Ești înscris. Operatorii nu te mai lasă."
    let onjnOpenOfficial = "Deschide pagina oficială ONJN"
    let onjnConfirmTitle = "Ai depus cererea?"
    let onjnConfirmMessage = "Bifează doar după ce ai completat autoexcluderea pe pagina oficială ONJN. Rămâne salvat privat, pe telefonul tău."
    let onjnConfirmAction = "Da, m-am înscris"
    let settingsPreferencesGroup = "PREFERINȚE"
    let languageLabel = "Limbă"
    let settingsSubscriptionGroup = "ABONAMENT"
    let settingsRestoreLabel = "Restaurează achizițiile"
    let settingsRestoreSub = "Recuperează abonamentul cumpărat cu acest ID Apple."
    let settingsRestoreSuccess = "Abonamentul a fost restaurat."
    let settingsAccountGroup = "CONT"
    let relapseLabel = "Am recăzut — resetează seria"
    let relapseSub = "Cinstit e mai bine. Istoricul rămâne, o repornim de la zero."
    let relapseConfirmTitle = "Resetezi seria?"
    let relapseConfirmMessage = "Seria revine la zero și economiile se recalculează de acum. Istoricul rămâne. Cinstit e mai bine."
    let relapseConfirmAction = "Resetează seria"
    let signOutLabel = "Deconectează-te"
    let signOutConfirmTitle = "Te deconectezi?"
    let signOutConfirmAction = "Deconectează-te"
    let deleteAccountLabel = "Șterge contul"
    let deleteAccountSub = "Șterge definitiv contul și toate datele de pe telefon."
    let deleteAccountConfirmTitle = "Ștergi contul definitiv?"
    let deleteAccountConfirmMessage = "Contul tău și toate datele — seria, economiile, insignele, conversațiile cu mentorul — dispar definitiv. Nu se poate anula."
    let deleteAccountConfirmAction = "Șterge definitiv"
    let deleteAccountError = "Nu am putut șterge contul acum. Verifică internetul și mai încearcă."

    // MARK: Mentor (AI chat)
    let chatTitle = "Mentorul tău"
    let chatSubtitle = "Un om de vorbă când te apucă pofta."
    let chatDisclaimer = "Nu e terapeut și nu ține loc de doctor. E aici să te asculte și să te țină pe drum. Nimic despre banii tăi nu pleacă de pe telefon."
    let chatEmptyTitle = "Spune ce ai pe suflet."
    let chatEmptyBody = "Te apucă pofta, ai recăzut, sau vrei doar să-ți limpezești capul? Scrie — te ascult."
    let chatInputPlaceholder = "Scrie ce simți…"
    let chatSendLabel = "Trimite"
    let chatTyping = "Mentorul scrie…"
    let chatSuggestions = ["Am poftă chiar acum", "Am recăzut", "De ce să mă opresc?", "Mă simt tentat"]
    let chatCrisisTitle = "Vorbește cu un om acum"
    let chatCrisisBody = "Dacă te simți în pericol, sună la 112. Pentru sprijin: Joc Responsabil, gratuit și confidențial."
    let chatOpenPanic = "Deschide butonul de panică"
    let chatUrgeHint = "Ține 60 de secunde. Pofta trece."
    let chatErrorGeneric = "Ceva n-a mers. Mai încearcă o dată."
    let chatErrorSignInAgain = "Sesiunea a expirat. Deconectează-te și conectează-te din nou ca să vorbești cu mentorul."
    let chatErrorPremium = "Mentorul face parte din abonament."
    let chatErrorRateLimited = "Prea multe mesaje prea repede. Respiră un pic și revii."
    let chatErrorOffline = "Fără internet acum. Butonul de panică merge oricum."

    // MARK: Garage
    let garageTitle = "Garajul"
    let garageSub = "Fiecare rang, o mașină mai bună. Ține seria."
    let garageNowDriving = "ACUM CONDUCI"
    func garageUnlocksAtDays(_ n: Int) -> String { "Se deblochează la \(n) \(roDe(n))zile" }
    func carModel(_ tier: CarTier) -> String {
        switch tier {
        case .rabla: "Dacie rablă"
        case .trezit: "Dacia"
        case .viteza: "VW Golf"
        case .serios: "BMW"
        case .smecher: "Mercedes"
        case .legenda: "Mercedes-AMG"
        }
    }
    func rankName(_ tier: CarTier) -> String {
        switch tier {
        case .rabla: "Rabla"
        case .trezit: "Te-ai trezit"
        case .viteza: "Ai prins viteză"
        case .serios: "Băiat serios"
        case .smecher: "Șmecher"
        case .legenda: "Legendă"
        }
    }
}
