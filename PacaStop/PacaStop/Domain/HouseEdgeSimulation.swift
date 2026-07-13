//
//  HouseEdgeSimulation.swift
//  PacaStop
//
//  The onboarding "reveal" (step 3): a 100-play bankroll that bleeds from full (lime) to
//  ~empty (red). The message is the house edge grinding you down a LITTLE ON EVERY PLAY —
//  a steady, roughly-linear decline to zero, NOT a cliff after a few big bets. You "win
//  sometimes — just enough to stay," so small win-bumps punctuate the fall but never reverse
//  the trend. Seeded so each replay is a fresh-but-reproducible run.
//

import Foundation

/// Tiny deterministic RNG (SplitMix64) so the simulation is reproducible per seed.
nonisolated struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    mutating func unit() -> Double {
        // 53-bit mantissa → (0,1]
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }
}

nonisolated struct HouseEdgeResult: Sendable {
    /// Bankroll trajectory, length `spins + 1`, values in `0...start`.
    var trajectory: [Double]
    /// The starting bankroll.
    var start: Double
    /// What's left at the end (≥ 0).
    var remaining: Double { max(0, trajectory.last ?? 0) }
    /// Normalized bars (0…1) for the drain chart.
    var normalizedBars: [Double] {
        guard start > 0 else { return trajectory.map { _ in 0 } }
        return trajectory.map { min(1, max(0, $0 / start)) }
    }
}

nonisolated enum HouseEdgeSimulation {
    static let rtp = 0.94                 // machine returns ~94, keeps ~6 out of every 100 fed in

    /// A steady, roughly-linear bleed of `start` lei across `spins` plays. The key property vs. a
    /// naive fixed-bet simulation: the bet scales down as the bankroll shrinks, so it NEVER busts
    /// early into a flat red tail — a little is lost on essentially every play, all the way to ~0.
    /// The ~6% edge is applied to the bankroll actually in play each round (recycled winnings), and
    /// the occasional win nudges the line back up a touch without ever reversing the fall.
    static func run(start: Double, spins: Int = 100, seed: UInt64) -> HouseEdgeResult {
        var rng = SeededRNG(seed: seed)
        let winProbability = 0.28

        var trajectory: [Double] = [start]
        for i in 1...spins {
            let progress = Double(i) / Double(spins)

            // Relentless baseline: a little gone every single play, trending straight to zero.
            let baseline = start * (1 - progress)

            // "Câștigi uneori — cât să rămâi acolo." Small win-bumps up, small extra dips down,
            // tapered to nothing at both ends so the run starts full and finishes empty.
            let taper = Foundation.sin(progress * Double.pi)
            let shock = rng.unit() < winProbability
                ? rng.unit() * 0.16 * start          // a win — a little handed back
                : -rng.unit() * 0.05 * start          // a loss — a little extra taken
            trajectory.append(min(start, max(0, baseline + shock * taper)))
        }
        return HouseEdgeResult(trajectory: trajectory, start: start)
    }
}
