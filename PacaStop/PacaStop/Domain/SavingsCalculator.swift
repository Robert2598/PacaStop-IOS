//
//  SavingsCalculator.swift
//  PacaStop
//
//  The money math (§6.1). Weekly = sessions × amount; yearly = weekly × 52;
//  daily rate = weekly ÷ 7; saved = daily rate × time elapsed since the quit moment.
//  Pure and deterministic — `now` is injectable for tests and previews.
//

import Foundation

/// The two numbers the user gives us in onboarding, and everything derived from them.
nonisolated struct SavingsProfile: Equatable, Sendable {
    var sessionsPerWeek: Double
    var amountPerSession: Double

    init(sessionsPerWeek: Double, amountPerSession: Double) {
        self.sessionsPerWeek = sessionsPerWeek
        self.amountPerSession = amountPerSession
    }

    init(frequency: Frequency, amountPerSession: Double) {
        self.sessionsPerWeek = frequency.sessionsPerWeek
        self.amountPerSession = amountPerSession
    }

    var weeklyLoss: Double { sessionsPerWeek * amountPerSession }
    var yearlyLoss: Double { weeklyLoss * 52 }
    var dailyRate: Double { weeklyLoss / 7 }
}

nonisolated enum SavingsCalculator {
    static let secondsPerDay: Double = 86_400

    /// Money kept since `quitDate`, ticking continuously (fractional lei included).
    static func saved(profile: SavingsProfile, since quitDate: Date, now: Date = Date()) -> Double {
        let elapsed = max(0, now.timeIntervalSince(quitDate))
        return profile.dailyRate * (elapsed / secondsPerDay)
    }

    /// Fractional lei-per-second, used to drive the live counter smoothly.
    static func ratePerSecond(profile: SavingsProfile) -> Double {
        profile.dailyRate / secondsPerDay
    }
}
