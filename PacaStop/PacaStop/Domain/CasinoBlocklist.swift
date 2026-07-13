//
//  CasinoBlocklist.swift
//  PacaStop
//
//  The bundled denylist of licensed Romanian online gambling domains, taken from the
//  official ONJN operator registry (snapshot: 2026-07). Applied as a system web-content
//  filter (ManagedSettings `.specific(...)`) so the user's browser blocks these sites even
//  if they never picked them in the Screen Time app-picker.
//
//  Domains are base registrable domains (no "www."); the system filter also covers their
//  subdomains (e.g. "betano.com" covers "ro.betano.com"). This is a point-in-time snapshot —
//  operators add domains and licenses change, so this should eventually be made
//  remote-updatable (fetch + cache from the backend) rather than shipped hard-coded.
//

import Foundation

nonisolated enum CasinoBlocklist {
    /// Registrable domains of ONJN-licensed online casino / betting operators.
    static let domains: [String] = [
        // NetBet
        "netbet.ro", "casinoroyale.ro",
        // Level Up Interactive (Winmasters)
        "winmasters.ro", "pariuriplus.ro", "kingcasino.ro", "12xbet.ro",
        // Betfair
        "betfair.ro", "betfair.com",
        // Unibet
        "unibet.ro", "vladcazino.ro", "32rosu.ro",
        // PokerStars (TSG)
        "pokerstars.ro", "pokerstarscasino.ro", "pokerstarssports.ro",
        // MaxBet
        "maxbet.ro",
        // Betano (Kaizen)
        "betano.com",
        // PublicWin (Sea Bet)
        "publicwin.ro",
        // Get's Bet
        "getsbet.ro", "conticazino.ro",
        // WinBet (Global Interactive)
        "winbet.ro",
        // Mozzartbet
        "mozzartbet.ro",
        // Favbet
        "favbet.ro",
        // Superbet
        "superbet.ro", "napoleongames.ro",
        // Megabet International (Stanleybet group)
        "stanleybet.ro", "gameworld.ro", "seven.ro", "admiralbet.ro",
        "redsevens.ro", "777.ro", "gpcasino.ro",
        // Avento (Frank/MrBit)
        "frankcasino.ro", "mrbit.ro", "slotv.ro",
        // Dimsacon
        "lasvegas.ro", "betone.ro",
        // Player Gaming
        "player.ro",
        // Crowd Entertainment (Princess/Cashpot)
        "princesscasino.ro", "cashpot.ro", "luck.com", "magnumbet.ro", "sport.com",
        "excelbet.ro", "spin.ro", "winboss.ro", "royalslots.ro", "betmen.ro", "powerbet.ro",
        // Wintoo Soft
        "win2.ro", "jokercasino.ro", "coolcasino.ro",
        // Deep Games
        "million.ro", "primacasino.ro", "bilion.ro", "wowcasino.ro",
        // Balkanix (Betinia)
        "betinia.ro", "don.ro", "swiper.ro",
        // TotoGaming (TG Malta)
        "totogaming.ro",
        // New Gambling Solutions (Winner / 888)
        "hotspins.ro", "eliteslots.ro", "winner.ro", "winneronline.ro", "bet7.ro",
        "ladycasino.ro", "orientalcasino.ro", "betplaces.ro", "joacagratis.ro",
        "mrplay.ro", "flashwin.ro", "casinofun.ro",
        "888.ro", "pacanele.ro", "888casino.ro", "888sport.ro", "888poker.ro",
        // PlayGG (WindGG)
        "playgg.ro",
        // Viva Games
        "vivabet.ro", "luckyseven.ro", "onecasino.ro", "fortunapalace.ro", "maxwin.ro",
        "ultrabet.ro", "prowin.ro", "cherrybet.ro", "vipbet.ro",
        // V Venture (Victorybet)
        "victorybet.ro", "xbet.ro", "manhattan.ro",
        // Romanix (Zinx/Topbet)
        "zinx.ro", "topbet.ro",
        // Hattrick Online (Casa Pariurilor / eFortuna)
        "casapariurilor.ro", "efortuna.ro",
        // Vista Online (VipCazino)
        "vipcazino.ro",
    ]

    /// De-duplicated, lowercased set — the canonical list to apply.
    static let uniqueDomains: [String] = Array(Set(domains.map { $0.lowercased() })).sorted()

    static var count: Int { uniqueDomains.count }
}
