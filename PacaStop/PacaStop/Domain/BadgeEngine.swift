//
//  BadgeEngine.swift
//  PacaStop
//
//  Evaluates which of the 9 badges are unlocked from the live counters (§6.4).
//

import Foundation

/// The counters a badge is evaluated against.
nonisolated struct BadgeContext: Equatable, Sendable {
    var streakDays: Int
    var savedLei: Double
    var cravingsBeaten: Int
}

nonisolated enum BadgeEngine {
    static func isUnlocked(_ badge: Badge, in ctx: BadgeContext) -> Bool {
        switch badge.requirement {
        case .streakDays(let n): ctx.streakDays >= n
        case .savedLei(let n): ctx.savedLei >= n
        case .cravingsBeaten(let n): ctx.cravingsBeaten >= n
        }
    }

    /// All currently-unlocked badges, in display order.
    static func unlockedBadges(in ctx: BadgeContext) -> [Badge] {
        Badge.allCases.filter { isUnlocked($0, in: ctx) }
    }

    static func unlockedCount(in ctx: BadgeContext) -> Int {
        unlockedBadges(in: ctx).count
    }
}
