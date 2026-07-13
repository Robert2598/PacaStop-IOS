//
//  Motion.swift
//  PacaStop
//
//  All motion is subtle and purposeful. Centralized so timing stays consistent.
//

import SwiftUI

enum Motion {
    /// Section / screen entrance: short fade-up.
    static let entrance = Animation.easeOut(duration: 0.45)
    /// Standard springy UI response (selection, toggles, taps).
    static let snappy = Animation.spring(response: 0.32, dampingFraction: 0.82)
    /// Softer spring for sheets / larger movement.
    static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.85)
    /// The live savings counter tick.
    static let counterTick = Animation.easeInOut(duration: 0.9)
    /// Panic button pulse.
    static let pulse = Animation.easeInOut(duration: 1.6).repeatForever(autoreverses: true)
    /// Car gentle float.
    static let float = Animation.easeInOut(duration: 3.2).repeatForever(autoreverses: true)
    /// House-edge simulation bar drain step.
    static let barDrain = Animation.easeOut(duration: 0.09)
    /// Marquee bulb chase step.
    static let bulbChase = Animation.easeInOut(duration: 0.5)
}

/// A reusable fade-up entrance transition for sections.
extension AnyTransition {
    static var fadeUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        )
    }
}

/// Applies a staggered fade-up on appear, keyed by an index so sibling sections
/// enter in sequence.
struct FadeUpOnAppear: ViewModifier {
    let index: Int
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear {
                withAnimation(Motion.entrance.delay(Double(index) * 0.06)) {
                    shown = true
                }
            }
    }
}

extension View {
    func fadeUpOnAppear(index: Int = 0) -> some View {
        modifier(FadeUpOnAppear(index: index))
    }
}
