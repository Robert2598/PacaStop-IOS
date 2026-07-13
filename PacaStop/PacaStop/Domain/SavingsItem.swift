//
//  SavingsItem.swift
//  PacaStop
//
//  Concrete things the saved money equals — the "Ce-ți luai" calculator (§6.5).
//  count = floor(saved ÷ unit); show items with count ≥ 1, richest first.
//
//  Prices are in RON, anchored to real Romanian 2026 costs (post-inflation) so every
//  equivalence is honest. The fuel tank uses the same 9 lei/litre as the panic reality-check.
//

import Foundation

nonisolated enum SavingsItem: String, CaseIterable, Codable, Identifiable, Sendable {
    case restaurantMeal    // o masă bună în oraș       — 120
    case phoneInstallment  // rată la un telefon nou    — 300
    case fuelTank          // un plin de benzină        — 450  (≈50 L × 9 lei)
    case utilitiesMonth    // facturile pe o lună       — 700
    case groceryMonth      // cumpărăturile pe o lună   — 1100
    case carInstallment    // rată la o mașină decentă  — 1800
    case monthRent         // chiria pe o lună          — 2500
    case vacationAbroad    // o vacanță în străinătate  — 4000

    var id: String { rawValue }

    /// Lei "unit price" of one of this item (RON, 2026).
    var unitPrice: Double {
        switch self {
        case .restaurantMeal: 120
        case .phoneInstallment: 300
        case .fuelTank: 450
        case .utilitiesMonth: 700
        case .groceryMonth: 1100
        case .carInstallment: 1800
        case .monthRent: 2500
        case .vacationAbroad: 4000
        }
    }

    var symbol: String {
        switch self {
        case .restaurantMeal: "fork.knife"
        case .phoneInstallment: "iphone"
        case .fuelTank: "fuelpump.fill"
        case .utilitiesMonth: "bolt.fill"
        case .groceryMonth: "cart.fill"
        case .carInstallment: "car.fill"
        case .monthRent: "house.fill"
        case .vacationAbroad: "airplane"
        }
    }
}
