//
//  CarTier.swift
//  PacaStop
//
//  The status ladder (§6.3). Each rank is a better car, unlocked by streak days.
//  Dull broken junker → sleek premium.
//

import Foundation

nonisolated enum CarTier: Int, CaseIterable, Codable, Identifiable, Sendable, Comparable {
    case rabla = 0        // day 0   — Dacie rablă   — "Rabla"
    case trezit = 1       // day 1   — Dacia         — "Te-ai trezit"
    case viteza = 2       // day 7   — VW Golf        — "Ai prins viteză"
    case serios = 3       // day 30  — BMW            — "Băiat serios"
    case smecher = 4      // day 90  — Mercedes        — "Șmecher"
    case legenda = 5      // day 365 — Mercedes-AMG    — "Legendă"

    var id: Int { rawValue }

    static func < (lhs: CarTier, rhs: CarTier) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Streak day at which this tier unlocks.
    var unlockDay: Int {
        switch self {
        case .rabla: 0
        case .trezit: 1
        case .viteza: 7
        case .serios: 30
        case .smecher: 90
        case .legenda: 365
        }
    }

    /// The tier immediately above this one, or `nil` at the top.
    var next: CarTier? {
        CarTier(rawValue: rawValue + 1)
    }

    var isTop: Bool { next == nil }
}
