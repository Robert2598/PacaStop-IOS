//
//  SectionScaffold.swift
//  PacaStop
//
//  Reusable container + header primitives shared by the main screens.
//

import SwiftUI

/// A padded surface card wrapper.
struct SectionCard<Content: View>: View {
    var fill: Color = Palette.surface
    var padding: CGFloat = Spacing.lg
    var radius: CGFloat = Radius.card
    var border: Color = Palette.hairline
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pacaCard(fill, radius: radius, border: border)
    }
}

/// A settings-style group: a small uppercase label above a card.
struct LabeledGroup<Content: View>: View {
    let label: String
    var labelColor: Color = Palette.textTertiary
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label.uppercased())
                .font(Typo.kicker)
                .tracking(1.5)
                .foregroundStyle(labelColor)
                .padding(.horizontal, Spacing.xxs)
            content
        }
    }
}

/// A screen header: an Anton title with an optional back chevron.
struct ScreenHeader: View {
    let title: String
    var showBack: Bool = false
    var onBack: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if showBack {
                Button {
                    onBack?()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Palette.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.hairline, lineWidth: 1))
                }
                .buttonStyle(PressableScale())
            }
            Text(title)
                .font(Typo.screenTitle)
                .foregroundStyle(Palette.textPrimary)
            Spacer(minLength: 0)
        }
    }
}
