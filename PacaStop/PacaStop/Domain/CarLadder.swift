//
//  CarLadder.swift
//  PacaStop
//
//  Maps a streak (in days) to the current car tier and progress toward the next (§6.3).
//

import Foundation

nonisolated enum CarLadder {
    /// Highest tier whose unlock day the streak has reached.
    static func currentTier(streakDays: Int) -> CarTier {
        CarTier.allCases.last { streakDays >= $0.unlockDay } ?? .rabla
    }

    /// Days remaining until the next tier, or `nil` at the top tier.
    static func daysToNext(streakDays: Int) -> Int? {
        guard let next = currentTier(streakDays: streakDays).next else { return nil }
        return max(0, next.unlockDay - streakDays)
    }

    /// Fraction (0…1) of the way from the current tier's threshold to the next.
    static func progressToNext(streakDays: Int) -> Double {
        let current = currentTier(streakDays: streakDays)
        guard let next = current.next else { return 1 }
        let span = Double(next.unlockDay - current.unlockDay)
        guard span > 0 else { return 1 }
        let done = Double(streakDays - current.unlockDay)
        return min(1, max(0, done / span))
    }
}
