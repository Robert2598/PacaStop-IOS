//
//  PanicCalculator.swift
//  PacaStop
//
//  The panic reality-check equivalence (§6.6): amount/session ÷ 9 ≈ litres of fuel —
//  a concrete, grammar-safe unit. 9 lei/litre tracks the real Romanian 2026 pump price.
//

import Foundation

nonisolated enum PanicConfig {
    /// Default lockout, configurable in a sensible 15–120s range (§6.6).
    static let defaultSeconds = 60
    static let messageRotationInterval: TimeInterval = 8
}

nonisolated enum PanicCalculator {
    /// Real Romanian 2026 pump price (~9 lei/litre). Used only for the reality-check line.
    static let leiPerLitreFuel: Double = 9

    /// Litres of fuel the about-to-be-spent amount equals (rounded, at least 1).
    static func litresOfFuel(amount: Double) -> Int {
        max(1, Int((amount / leiPerLitreFuel).rounded()))
    }
}
