//
//  Layout.swift
//  PacaStop
//
//  Spacing rhythm, corner radii and tap-target metrics. Pulled from the design language:
//  cards 20–24, buttons 14–16, pills fully round; screen padding ~20–26; tap targets ≥52.
//

import SwiftUI

enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 26
    static let xxl: CGFloat = 34

    /// Standard horizontal screen padding.
    static let screenH: CGFloat = 22
    /// Vertical rhythm between major blocks.
    static let block: CGFloat = 22
}

enum Radius {
    static let card: CGFloat = 22
    static let cardLarge: CGFloat = 24
    static let button: CGFloat = 15
    static let panicButton: CGFloat = 20
    static let reel: CGFloat = 7
    static let pill: CGFloat = 999
    static let tile: CGFloat = 20
    static let field: CGFloat = 16
}

enum Metrics {
    static let primaryButtonHeight: CGFloat = 54
    static let panicButtonHeight: CGFloat = 64
    static let minTapTarget: CGFloat = 52
    static let toggleWidth: CGFloat = 48
    static let toggleHeight: CGFloat = 28
    static let tabBarHeight: CGFloat = 64
}
