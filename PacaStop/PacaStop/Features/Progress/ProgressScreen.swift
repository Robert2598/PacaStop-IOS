//
//  ProgressScreen.swift
//  PacaStop
//
//  The private trophy room + money-translation (§5.5). View-only.
//

import SwiftUI

struct ProgressScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(LocalizationStore.self) private var loc

    private var s: any Localization { loc.s }
    private var model: AppModel { env.appModel }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 3)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                titleBlock
                badgesSection
                calculatorSection
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.lg)
        }
        .screenBackground()
        .onAppear { model.evaluateBadges() }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(s.progressTitle)
                .font(Typo.screenTitle)
                .foregroundStyle(Palette.textPrimary)
            Text(s.progressSub)
                .font(Typo.bodyMd)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(s.badgesTitle)
                    .font(Typo.title)
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
                Text(s.badgeCount(model.earnedBadges.count, of: Badge.allCases.count))
                    .font(.body(15, weight: .bold))
                    .foregroundStyle(Palette.lime)
            }
            LazyVGrid(columns: columns, spacing: Spacing.md) {
                ForEach(Badge.allCases) { badge in
                    BadgeTile(
                        badge: badge,
                        name: s.badgeName(badge),
                        isUnlocked: model.earnedBadges.contains(badge)
                    )
                }
            }
        }
    }

    private var calculatorSection: some View {
        // Lifetime savings (survives relapses) so this agrees with the sticky money badges above.
        let saved = model.lifetimeSaved()
        let items = MoneyCalculator.affordable(saved: saved)
        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text(s.calculatorTitle)
                .font(Typo.title)
                .foregroundStyle(Palette.textPrimary)
            Text(s.calculatorSub(saved: MoneyFormatter.leiWhole(saved)))
                .font(Typo.bodySm)
                .foregroundStyle(Palette.textSecondary)

            if items.isEmpty {
                SectionCard(fill: Palette.surfaceDeep) {
                    Text(s.calculatorEmpty)
                        .font(Typo.bodyMd)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(items) { entry in
                        AffordableRow(entry: entry, name: s.savingsItemNoun(entry.item, count: entry.count))
                        if entry.id != items.last?.id {
                            Divider().overlay(Palette.hairline)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .pacaCard(Palette.surface)
            }
        }
    }
}

private struct AffordableRow: View {
    let entry: AffordableItem
    let name: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: entry.item.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.textSecondary)
                .frame(width: 24)
            Text("\(entry.count)×")
                .font(Typo.headline)
                .foregroundStyle(Palette.lime)
            Text(name)
                .font(Typo.bodyMd)
                .foregroundStyle(Palette.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.sm)
    }
}

#Preview {
    PreviewEnvironment { ProgressScreen() }
}
