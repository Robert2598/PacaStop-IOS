//
//  CountdownRing.swift
//  PacaStop
//
//  The panic countdown ring (§5.4): a red ring that depletes as time passes, with the
//  seconds remaining big in the center. Purely presentational — timing lives in PanicView.
//

import SwiftUI

struct CountdownRing: View {
    /// Remaining fraction, 1 → 0.
    let fraction: Double
    let secondsRemaining: Int
    let unitLabel: String
    var size: CGFloat = 240
    var lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.red.opacity(0.18), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0, min(1, fraction)))
                .stroke(Palette.red, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: Palette.red.opacity(0.6), radius: 12)
                .animation(.linear(duration: 0.25), value: fraction)

            VStack(spacing: 2) {
                Text("\(secondsRemaining)")
                    .font(Typo.countdown)
                    .foregroundStyle(Palette.textPrimary)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.snappy, value: secondsRemaining)
                Text(unitLabel)
                    .font(Typo.label)
                    .foregroundStyle(Palette.softRed)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(secondsRemaining) \(unitLabel)")
    }
}

#Preview {
    ZStack {
        Palette.panicBackground.ignoresSafeArea()
        CountdownRing(fraction: 0.7, secondsRemaining: 42, unitLabel: "secunde")
    }
}
