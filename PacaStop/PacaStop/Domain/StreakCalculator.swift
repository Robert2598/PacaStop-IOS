//
//  StreakCalculator.swift
//  PacaStop
//
//  Streak = whole days since the quit moment (§6.2). Day 0 at the quit moment.
//

import Foundation

nonisolated enum StreakCalculator {
    /// Whole days elapsed since `quitDate` (never negative).
    static func days(since quitDate: Date, now: Date = Date()) -> Int {
        let elapsed = now.timeIntervalSince(quitDate)
        guard elapsed > 0 else { return 0 }
        return Int(elapsed / SavingsCalculator.secondsPerDay)
    }
}
