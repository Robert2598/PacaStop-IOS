//
//  GarageSheet.swift
//  PacaStop
//
//  The full car/rank ladder (§5.7), presented as a bottom sheet over Home.
//

import SwiftUI

struct GarageSheet: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(LocalizationStore.self) private var loc
    @Environment(\.dismiss) private var dismiss

    private var s: any Localization { loc.s }
    private var model: AppModel { env.appModel }

    var body: some View {
        let current = model.currentTier()

        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(s.garageTitle)
                    .font(Typo.screenTitle)
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Palette.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(Palette.raised, in: Circle())
                }
                .buttonStyle(PressableScale())
                .accessibilityLabel(s.closeLabel)
            }

            Text(s.garageSub)
                .font(Typo.bodyMd)
                .foregroundStyle(Palette.textSecondary)

            ScrollView {
                VStack(spacing: Spacing.sm) {
                    ForEach(CarTier.allCases) { tier in
                        GarageRow(tier: tier, current: current, loc: s)
                    }
                }
                .padding(.bottom, Spacing.lg)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surfaceDeep.ignoresSafeArea())
    }
}

private struct GarageRow: View {
    let tier: CarTier
    let current: CarTier
    let loc: any Localization

    private var isCurrent: Bool { tier == current }
    private var isLocked: Bool { tier > current }

    var body: some View {
        HStack(spacing: Spacing.md) {
            CarSilhouette(tier: tier, width: 108)
                .frame(width: 108)

            VStack(alignment: .leading, spacing: 3) {
                Text(loc.carModel(tier))
                    .font(Typo.title)
                    .foregroundStyle(Palette.textPrimary)
                Text(loc.rankName(tier))
                    .font(Typo.bodySm)
                    .foregroundStyle(Palette.textSecondary)
                if isCurrent {
                    Text(loc.garageNowDriving)
                        .font(Typo.kicker)
                        .tracking(1)
                        .foregroundStyle(Palette.lime)
                        .padding(.top, 2)
                } else if isLocked {
                    Text(loc.garageUnlocksAtDays(tier.unlockDay))
                        .font(Typo.caption)
                        .foregroundStyle(Palette.textTertiary)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .pacaCard(
            isCurrent ? Palette.lime.opacity(0.06) : Palette.surface,
            border: isCurrent ? Palette.lime : Palette.hairline,
            borderWidth: isCurrent ? 1.5 : 1
        )
        .opacity(isLocked ? 0.55 : 1)
    }
}

#Preview {
    PreviewEnvironment { GarageSheet() }
}
