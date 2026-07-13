//
//  StreakChip.swift
//  PacaStop
//
//  The compact lime streak pill in the Home header: a triangle "flame", the day count
//  in the display face, and the ZILE / DAYS label. Intentionally small.
//

import SwiftUI

struct StreakChip: View {
    let days: Int
    let unitLabel: String

    var body: some View {
        HStack(spacing: 7) {
            UpTriangle()
                .fill(Palette.lime)
                .frame(width: 10, height: 9)
            Text("\(days)")
                .font(Typo.displaySm)
                .foregroundStyle(Palette.lime)
                .contentTransition(.numericText(value: Double(days)))
            Text(unitLabel)
                .font(.body(10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Palette.lime.opacity(0.72))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 13)
        .background(Palette.limeSoftFill, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.limeSoftBorder, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(days) \(unitLabel)")
    }
}

#Preview {
    ZStack {
        Palette.background.ignoresSafeArea()
        StreakChip(days: 12, unitLabel: "ZILE")
    }
}
