//
//  Palette.swift
//  PacaStop
//
//  The brand color language. Dark, disciplined, in-your-face.
//  Lime = "you're winning by staying out." Red = "what you're about to lose."
//  Everything else is neutral dark. Do not introduce new hues.
//

import SwiftUI

/// Central color tokens for PăcăStop. Values mirror the design system 1:1.
enum Palette {
    // Backgrounds
    static let background = Color(hex: 0x0D0E11)      // every screen
    static let desk = Color(hex: 0x08090B)           // frame backdrop / deepest insets
    static let surface = Color(hex: 0x16181D)         // standard cards, list groups
    static let surfaceDeep = Color(hex: 0x121317)     // hero cards
    static let surfaceInset = Color(hex: 0x141519)    // jackpot cells
    static let raised = Color(hex: 0x1C1F26)          // inner rows, avatars

    // Text
    static let textPrimary = Color(hex: 0xF4F5F7)
    static let textSecondary = Color(white: 0.957, opacity: 0.55)
    static let textTertiary = Color(white: 0.957, opacity: 0.40)
    static let textFaint = Color(white: 0.957, opacity: 0.28)

    // Accents
    static let lime = Color(hex: 0xC6F03C)            // money / win / progress
    static let red = Color(hex: 0xFF3B30)             // panic / loss / danger
    static let softRed = Color(hex: 0xFF8079)         // panic kickers, sign-out
    static let amber = Color(hex: 0xFFB84D)           // relapse row only

    // Hairlines & fills
    static let hairline = Color(white: 1, opacity: 0.08)
    static let hairlineStrong = Color(white: 1, opacity: 0.12)
    static let limeSoftFill = Color(hex: 0xC6F03C, opacity: 0.10)
    static let limeSoftBorder = Color(hex: 0xC6F03C, opacity: 0.28)
    static let redSoftFill = Color(hex: 0xFF3B30, opacity: 0.08)
    static let redSoftBorder = Color(hex: 0xFF3B30, opacity: 0.28)

    // Panic takeover background (deep oxblood)
    static let panicBackground = Color(hex: 0x2A0806)
    static let panicBackgroundDeep = Color(hex: 0x1A0503)

    // On-lime foreground (for text/icons sitting on a lime fill)
    static let onLime = Color(hex: 0x0D0E11)
}

extension Color {
    /// Hex initializer, e.g. `Color(hex: 0xC6F03C)`.
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
