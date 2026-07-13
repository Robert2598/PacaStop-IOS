//
//  Typography.swift
//  PacaStop
//
//  Two faces:
//   • Display — Anton (condensed, heavy, screaming). Big numbers, rank names, titles, jackpot digits.
//   • Body    — Space Grotesk (clean modern grotesque). Everything else.
//  Both bundled fonts are verified to render Romanian diacritics (ă â î ș ț) with the
//  correct comma-below Ș/Ț. If registration ever fails, we fall back to the system font
//  (compressed + heavy for display) which also fully supports diacritics.
//

import SwiftUI
import CoreText
import os

enum FontFamily {
    static let display = "Anton"                 // PostScript: Anton-Regular
    static let bodyRegular = "SpaceGrotesk-Regular"
    static let bodyMedium = "SpaceGrotesk-Medium"
    static let bodySemibold = "SpaceGrotesk-SemiBold"
    static let bodyBold = "SpaceGrotesk-Bold"
}

/// Registers the bundled `.ttf` files with CoreText at launch. Idempotent.
enum FontRegistrar {
    private static let logger = Logger(subsystem: "com.pixelpaw.PacaStop", category: "Fonts")
    private static var didRegister = false

    static let bundledFonts = [
        "Anton-Regular",
        "SpaceGrotesk-Regular",
        "SpaceGrotesk-Medium",
        "SpaceGrotesk-SemiBold",
        "SpaceGrotesk-Bold",
    ]

    static func registerAll() {
        guard !didRegister else { return }
        didRegister = true
        for name in bundledFonts {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                logger.error("Font resource missing from bundle: \(name, privacy: .public).ttf")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                // Already-registered is a benign error we can ignore.
                logger.notice("Font \(name, privacy: .public) not newly registered (may already be registered).")
            }
        }
    }

    /// True if the Anton display face is available (used to pick a fallback). Cached —
    /// availability is fixed once `registerAll()` has run at launch, so a live `UIFont`
    /// lookup on every `Font.display(_:)` call (including the 10 Hz jackpot) is wasteful.
    static let displayFaceAvailable: Bool = UIFont(name: FontFamily.display, size: 12) != nil

    /// Cached per-face availability for the body weights.
    private static let bodyAvailability: [String: Bool] = [
        FontFamily.bodyRegular: UIFont(name: FontFamily.bodyRegular, size: 12) != nil,
        FontFamily.bodyMedium: UIFont(name: FontFamily.bodyMedium, size: 12) != nil,
        FontFamily.bodySemibold: UIFont(name: FontFamily.bodySemibold, size: 12) != nil,
        FontFamily.bodyBold: UIFont(name: FontFamily.bodyBold, size: 12) != nil,
    ]

    static func bodyFaceAvailable(_ name: String) -> Bool {
        bodyAvailability[name] ?? false
    }
}

extension Font {
    /// Display face (Anton) at `size`, scaling relative to a Dynamic Type text style.
    static func display(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .largeTitle) -> Font {
        if FontRegistrar.displayFaceAvailable {
            return .custom(FontFamily.display, size: size, relativeTo: textStyle)
        }
        // Fallback: system heavy + compressed width approximates the condensed display look.
        return .system(size: size, weight: .heavy).width(.compressed)
    }

    /// Body face (Space Grotesk) at `size`/`weight`, scaling relative to a Dynamic Type text style.
    static func body(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .black: name = FontFamily.bodyBold
        case .semibold: name = FontFamily.bodySemibold
        case .medium: name = FontFamily.bodyMedium
        default: name = FontFamily.bodyRegular
        }
        if FontRegistrar.bodyFaceAvailable(name) {
            return .custom(name, size: size, relativeTo: textStyle)
        }
        return .system(size: size, weight: weight)
    }
}

/// Named type ramp so screens stay consistent without repeating point sizes.
enum Typo {
    // Display / Anton
    static let heroHuge = Font.display(64, relativeTo: .largeTitle)      // login headline
    static let hero = Font.display(52, relativeTo: .largeTitle)          // big statements
    static let screenTitle = Font.display(34, relativeTo: .title)        // screen titles
    static let rankName = Font.display(30, relativeTo: .title)           // rank name in header
    static let displayLg = Font.display(44, relativeTo: .title)          // big red loss numbers
    static let displayMd = Font.display(28, relativeTo: .title2)         // section big numbers
    static let displaySm = Font.display(21, relativeTo: .title3)         // streak chip count
    static let countdown = Font.display(78, relativeTo: .largeTitle)     // panic ring seconds

    // Body / Space Grotesk
    static let title = Font.body(20, weight: .bold, relativeTo: .title3)
    static let headline = Font.body(17, weight: .semibold, relativeTo: .headline)
    static let bodyLg = Font.body(16, weight: .medium, relativeTo: .body)
    static let bodyMd = Font.body(15, weight: .regular, relativeTo: .body)
    static let bodySm = Font.body(14, weight: .regular, relativeTo: .subheadline)
    static let button = Font.body(16, weight: .bold, relativeTo: .headline)
    static let label = Font.body(13, weight: .semibold, relativeTo: .footnote)
    static let caption = Font.body(12.5, weight: .regular, relativeTo: .caption)
    static let kicker = Font.body(11, weight: .bold, relativeTo: .caption2)   // uppercase kickers
}
