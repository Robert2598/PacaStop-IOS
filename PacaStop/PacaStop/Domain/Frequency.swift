//
//  Frequency.swift
//  PacaStop
//
//  How often the user plays — chosen in onboarding step 1. Each maps to a
//  sessions-per-week number used by the savings math (§6.1).
//

import Foundation

nonisolated enum Frequency: String, CaseIterable, Codable, Identifiable, Sendable {
    case daily            // Zilnic
    case fewTimesWeek     // De câteva ori pe săptămână
    case onceWeek         // O dată pe săptămână
    case fewTimesMonth    // De câteva ori pe lună

    var id: String { rawValue }

    /// Sessions per week (mapping from the reference prototype, §6.1).
    var sessionsPerWeek: Double {
        switch self {
        case .daily: 7
        case .fewTimesWeek: 3
        case .onceWeek: 1
        case .fewTimesMonth: 0.5
        }
    }
}
