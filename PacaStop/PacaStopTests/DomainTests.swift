//
//  DomainTests.swift
//  PacaStopTests
//
//  Unit tests for the pure domain "brain" (§6). These are the load-bearing numbers.
//

import Testing
import Foundation
@testable import PacaStop

struct SavingsTests {
    @Test func weeklyYearlyDaily() {
        let profile = SavingsProfile(frequency: .fewTimesWeek, amountPerSession: 200) // 3/week
        #expect(profile.weeklyLoss == 600)
        #expect(profile.yearlyLoss == 600 * 52)
        #expect(abs(profile.dailyRate - 600.0 / 7) < 0.0001)
    }

    @Test func savedTicksWithTime() {
        let profile = SavingsProfile(frequency: .daily, amountPerSession: 100) // 7/week → 700/week → 100/day
        let quit = Date(timeIntervalSince1970: 0)
        let now = Date(timeIntervalSince1970: 10 * 86_400) // 10 days later
        let saved = SavingsCalculator.saved(profile: profile, since: quit, now: now)
        #expect(abs(saved - 1000) < 0.0001) // 100/day * 10 days
    }

    @Test func savedNeverNegative() {
        let profile = SavingsProfile(frequency: .daily, amountPerSession: 100)
        let quit = Date(timeIntervalSince1970: 100)
        let now = Date(timeIntervalSince1970: 0) // before quit
        #expect(SavingsCalculator.saved(profile: profile, since: quit, now: now) == 0)
    }
}

struct StreakTests {
    @Test func wholeDays() {
        let quit = Date(timeIntervalSince1970: 0)
        #expect(StreakCalculator.days(since: quit, now: Date(timeIntervalSince1970: 0)) == 0)
        #expect(StreakCalculator.days(since: quit, now: Date(timeIntervalSince1970: 86_399)) == 0)
        #expect(StreakCalculator.days(since: quit, now: Date(timeIntervalSince1970: 86_400)) == 1)
        #expect(StreakCalculator.days(since: quit, now: Date(timeIntervalSince1970: 12 * 86_400 + 5)) == 12)
    }
}

struct CarLadderTests {
    @Test func tierThresholds() {
        #expect(CarLadder.currentTier(streakDays: 0) == .rabla)
        #expect(CarLadder.currentTier(streakDays: 1) == .trezit)
        #expect(CarLadder.currentTier(streakDays: 6) == .trezit)
        #expect(CarLadder.currentTier(streakDays: 7) == .viteza)
        #expect(CarLadder.currentTier(streakDays: 29) == .viteza)
        #expect(CarLadder.currentTier(streakDays: 30) == .serios)
        #expect(CarLadder.currentTier(streakDays: 90) == .smecher)
        #expect(CarLadder.currentTier(streakDays: 365) == .legenda)
        #expect(CarLadder.currentTier(streakDays: 999) == .legenda)
    }

    @Test func daysToNextAndProgress() {
        #expect(CarLadder.daysToNext(streakDays: 12) == 18) // to 30
        #expect(CarLadder.daysToNext(streakDays: 365) == nil) // top tier
        let p = CarLadder.progressToNext(streakDays: 7) // start of viteza (7→30)
        #expect(p == 0)
        let mid = CarLadder.progressToNext(streakDays: 18) // 11/23
        #expect(abs(mid - 11.0 / 23.0) < 0.0001)
        #expect(CarLadder.progressToNext(streakDays: 400) == 1) // top tier
    }
}

struct BadgeTests {
    @Test func unlocks() {
        let ctx = BadgeContext(streakDays: 12, savedLei: 1200, cravingsBeaten: 2)
        #expect(BadgeEngine.isUnlocked(.firstDay, in: ctx))
        #expect(BadgeEngine.isUnlocked(.oneWeek, in: ctx))
        #expect(BadgeEngine.isUnlocked(.thousandLei, in: ctx))
        #expect(BadgeEngine.isUnlocked(.cravingBeaten, in: ctx))
        #expect(!BadgeEngine.isUnlocked(.oneMonth, in: ctx))
        #expect(!BadgeEngine.isUnlocked(.fiveCravings, in: ctx))
        #expect(!BadgeEngine.isUnlocked(.fiveThousandLei, in: ctx))
        #expect(BadgeEngine.unlockedCount(in: ctx) == 4)
    }
}

struct MoneyCalculatorTests {
    @Test func affordableRichestFirst() {
        let items = MoneyCalculator.affordable(saved: 1000)
        // 1000 → 2× groceryBasket(300)? no: sorted richest first, count>=1
        // carInstallment 1500 → 0 (excluded); fuelTank 400 → 2; seaside 350 → 2; grocery 300 → 3; phone 250 → 4
        #expect(items.first?.item == .fuelTank)
        #expect(items.first?.count == 2)
        #expect(!items.contains { $0.item == .carInstallment })
        #expect(items.contains { $0.item == .phoneInstallment && $0.count == 4 })
    }

    @Test func emptyWhenBroke() {
        #expect(MoneyCalculator.affordable(saved: 100).isEmpty)
    }
}

struct MoneyFormatterTests {
    @Test func romanianFormat() {
        #expect(MoneyFormatter.number(1131.42, decimals: 2) == "1.131,42")
        #expect(MoneyFormatter.leiWhole(31200) == "31.200 lei")
        #expect(MoneyFormatter.lei(1131.42) == "1.131,42 lei")
    }
}

struct HouseEdgeTests {
    @Test func deterministicPerSeed() {
        let a = HouseEdgeSimulation.run(start: 200, spins: 100, seed: 42)
        let b = HouseEdgeSimulation.run(start: 200, spins: 100, seed: 42)
        #expect(a.trajectory == b.trajectory)
    }

    @Test func drainsDownward() {
        let r = HouseEdgeSimulation.run(start: 200, spins: 100, seed: 7)
        #expect(r.trajectory.count == 101)
        #expect(r.remaining < r.start) // house wins
        #expect(r.remaining >= 0)
        #expect(r.normalizedBars.allSatisfy { $0 >= 0 && $0 <= 1 })
    }
}

struct PanicMathTests {
    @Test func litresOfFuel() {
        #expect(PanicCalculator.litresOfFuel(amount: 200) == 25) // 200/8
        #expect(PanicCalculator.litresOfFuel(amount: 4) == 1)    // floor at 1
    }
}
