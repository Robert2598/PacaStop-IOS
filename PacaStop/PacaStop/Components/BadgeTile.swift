//
//  BadgeTile.swift
//  PacaStop
//
//  A single achievement tile (§5.5): unlocked = lime tile with a glyph; locked = dark empty.
//

import SwiftUI

struct BadgeTile: View {
    let badge: Badge
    let name: String
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                .fill(isUnlocked ? Palette.lime : Palette.raised)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                        .strokeBorder(isUnlocked ? .clear : Palette.hairline, lineWidth: 1.5)
                )
                .overlay {
                    if isUnlocked {
                        Image(systemName: badge.symbol)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Palette.onLime)
                    }
                }
                .aspectRatio(1, contentMode: .fit)

            Text(name)
                .font(.body(11.5, weight: .medium))
                .foregroundStyle(isUnlocked ? Palette.textPrimary : Palette.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue(isUnlocked ? "Unlocked" : "Locked")
    }
}

#Preview {
    ZStack {
        Palette.background.ignoresSafeArea()
        HStack(spacing: 14) {
            BadgeTile(badge: .oneWeek, name: "O săptămână", isUnlocked: true)
            BadgeTile(badge: .oneMonth, name: "O lună", isUnlocked: false)
        }
        .frame(width: 240)
    }
}
