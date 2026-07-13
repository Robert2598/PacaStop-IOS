//
//  Badge.swift
//  PacaStop
//
//  The 9 private achievements (§6.4). Order here IS the display order in the grid.
//

import Foundation

nonisolated enum Badge: String, CaseIterable, Codable, Identifiable, Sendable {
    case firstDay          // Prima zi        — streak ≥ 1
    case cravingBeaten     // Poftă învinsă   — ≥ 1 panic held out
    case oneWeek           // O săptămână     — streak ≥ 7
    case thousandLei       // 1.000 lei       — saved ≥ 1000
    case oneMonth          // O lună          — streak ≥ 30
    case fiveCravings      // 5 pofte învinse — ≥ 5 panic held out
    case fiveThousandLei   // 5.000 lei       — saved ≥ 5000
    case ninetyDays        // 90 de zile      — streak ≥ 90
    case oneYear           // Un an întreg    — streak ≥ 365

    var id: String { rawValue }

    /// SF Symbol shown on the unlocked tile (checkmark is the design default,
    /// but a themed glyph reads faster when scanning).
    var symbol: String {
        switch self {
        case .firstDay: "sunrise.fill"
        case .cravingBeaten: "hand.raised.fill"
        case .oneWeek: "calendar"
        case .thousandLei: "banknote.fill"
        case .oneMonth: "calendar.badge.checkmark"
        case .fiveCravings: "shield.lefthalf.filled"
        case .fiveThousandLei: "wallet.bifold.fill"
        case .ninetyDays: "flame.fill"
        case .oneYear: "trophy.fill"
        }
    }
}

/// The kind of counter a badge is gated on — evaluated by the BadgeEngine.
nonisolated enum BadgeRequirement: Sendable {
    case streakDays(Int)
    case savedLei(Double)
    case cravingsBeaten(Int)
}

extension Badge {
    var requirement: BadgeRequirement {
        switch self {
        case .firstDay: .streakDays(1)
        case .cravingBeaten: .cravingsBeaten(1)
        case .oneWeek: .streakDays(7)
        case .thousandLei: .savedLei(1000)
        case .oneMonth: .streakDays(30)
        case .fiveCravings: .cravingsBeaten(5)
        case .fiveThousandLei: .savedLei(5000)
        case .ninetyDays: .streakDays(90)
        case .oneYear: .streakDays(365)
        }
    }
}
