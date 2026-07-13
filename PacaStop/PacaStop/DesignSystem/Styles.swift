//
//  Styles.swift
//  PacaStop
//
//  Reusable styling primitives shared across every screen.
//

import SwiftUI

// MARK: - Backgrounds & surfaces

extension View {
    /// The standard dark app background, edge-to-edge.
    func screenBackground(_ color: Color = Palette.background) -> some View {
        background(color.ignoresSafeArea())
    }

    /// A standard surface card: fill + hairline border + rounded corners.
    func pacaCard(
        _ fill: Color = Palette.surface,
        radius: CGFloat = Radius.card,
        border: Color = Palette.hairline,
        borderWidth: CGFloat = 1
    ) -> some View {
        background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(border, lineWidth: borderWidth)
            )
    }
}

// MARK: - Kicker (uppercase, letter-spaced label)

/// The small all-caps kicker used above headlines ("MATEMATICA SIMPLĂ", "PROTECȚIE", …).
struct Kicker: View {
    let text: String
    var color: Color = Palette.lime
    var tracking: CGFloat = 2

    init(_ text: String, color: Color = Palette.lime, tracking: CGFloat = 2) {
        self.text = text
        self.color = color
        self.tracking = tracking
    }

    var body: some View {
        Text(text.uppercased())
            .font(Typo.kicker)
            .tracking(tracking)
            .foregroundStyle(color)
    }
}

// MARK: - Section headers (Anton screen titles etc.)

extension Text {
    /// Applies the display face at a given ramp size.
    func displayStyle(_ font: Font, color: Color = Palette.textPrimary) -> some View {
        self.font(font).foregroundStyle(color)
    }
}

// MARK: - Pressable scale (subtle tactile feedback on custom buttons)

struct PressableScale: ButtonStyle {
    var scale: CGFloat = 0.97
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(Motion.snappy, value: configuration.isPressed)
    }
}
