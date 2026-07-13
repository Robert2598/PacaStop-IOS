//
//  HomeView.swift
//  PacaStop
//
//  The daily hub (§5.3): pride (rank/car), reward (money kept as a jackpot), and the
//  escape hatch (panic). Presents the Garage sheet and the Panic full-screen takeover.
//

import SwiftUI

struct HomeView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(LocalizationStore.self) private var loc

    @State private var showGarage = false
    @State private var showPanic = false

    private var s: any Localization { loc.s }
    private var model: AppModel { env.appModel }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.block) {
                header.fadeUpOnAppear(index: 0)
                carHero.fadeUpOnAppear(index: 1)
                jackpot.fadeUpOnAppear(index: 2)
                panicSection.fadeUpOnAppear(index: 3)
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.lg)
        }
        .screenBackground()
        .overlay(alignment: .top) { badgeCelebration }
        .sheet(isPresented: $showGarage) {
            GarageSheet()
                .presentationDetents([.large, .fraction(0.85)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Palette.surfaceDeep)
        }
        .fullScreenCover(isPresented: $showPanic) {
            PanicView()
        }
        .onAppear { model.evaluateBadges() }
    }

    // MARK: - Header

    private var header: some View {
        let tier = model.currentTier()
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(s.homeYourRank)
                    .font(Typo.kicker)
                    .tracking(1.5)
                    .foregroundStyle(Palette.textTertiary)
                Text(s.rankName(tier))
                    .font(Typo.rankName)
                    .foregroundStyle(Palette.lime)
            }
            Spacer(minLength: Spacing.sm)
            StreakChip(days: model.streakDays(), unitLabel: s.daysUnit)
        }
    }

    // MARK: - Car hero

    private var carHero: some View {
        let tier = model.currentTier()
        let daysToNext = CarLadder.daysToNext(streakDays: model.streakDays())
        return Button {
            showGarage = true
        } label: {
            VStack(spacing: Spacing.sm) {
                ZStack {
                    Ellipse()
                        .fill(Palette.lime.opacity(0.16))
                        .frame(height: 90)
                        .blur(radius: 34)
                    CarSilhouette(tier: tier, width: 230, floating: true)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 130)

                Text(s.carModel(tier))
                    .font(Typo.title)
                    .foregroundStyle(Palette.textPrimary)

                LinearProgressBar(progress: CarLadder.progressToNext(streakDays: model.streakDays()))
                    .padding(.top, Spacing.xxs)

                HStack {
                    Text(daysToNext.map { s.nextCarInDays($0) } ?? s.topTierReached)
                        .font(Typo.caption)
                        .foregroundStyle(Palette.textTertiary)
                    Spacer()
                    Text(s.myGarage)
                        .font(.body(13, weight: .semibold))
                        .foregroundStyle(Palette.lime)
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity)
            .pacaCard(Palette.surfaceDeep)
        }
        .buttonStyle(PressableScale())
    }

    // MARK: - Jackpot (ticks live)

    private var jackpot: some View {
        // 0.5s is plenty: the cents move slower than that for realistic inputs, and the digit
        // roll is a 0.9s animation — faster ticking just burns the main thread.
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            JackpotDisplay(
                amount: model.saved(at: context.date),
                topLabel: s.savedLabel,
                bottomLabel: s.savedSub
            )
        }
    }

    // MARK: - Panic

    private var panicSection: some View {
        VStack(spacing: Spacing.sm) {
            Text(s.feelUrgeKicker)
                .font(Typo.kicker)
                .tracking(1.5)
                .foregroundStyle(Palette.softRed)
            PanicButtonBig(title: s.panicButton) { showPanic = true }
            Text(s.panicButtonSub(seconds: PanicConfig.defaultSeconds))
                .font(Typo.caption)
                .foregroundStyle(Palette.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Badge celebration

    @ViewBuilder
    private var badgeCelebration: some View {
        if let badge = model.pendingBadgeCelebration {
            BadgeCelebrationToast(name: s.badgeName(badge), symbol: badge.symbol)
                .padding(.top, Spacing.xs)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task {
                    try? await Task.sleep(for: .seconds(2.5))
                    withAnimation(Motion.smooth) { model.pendingBadgeCelebration = nil }
                }
        }
    }
}

/// The big, softly-pulsing red panic button.
struct PanicButtonBig: View {
    let title: String
    let action: () -> Void
    @State private var pulsing = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.display(24))
                .tracking(1)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Metrics.panicButtonHeight)
                .background(Palette.red, in: RoundedRectangle(cornerRadius: Radius.panicButton, style: .continuous))
                .shadow(color: Palette.red.opacity(pulsing ? 0.7 : 0.3), radius: pulsing ? 22 : 10)
        }
        .buttonStyle(PressableScale(scale: 0.98))
        .onAppear { withAnimation(Motion.pulse) { pulsing = true } }
        .accessibilityLabel(title)
    }
}

/// Small lime toast shown when a badge unlocks.
struct BadgeCelebrationToast: View {
    let name: String
    let symbol: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
            Text(name)
                .font(.body(14, weight: .bold))
        }
        .foregroundStyle(Palette.onLime)
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.md)
        .background(Palette.lime, in: Capsule())
        .shadow(color: Palette.lime.opacity(0.5), radius: 12)
    }
}

#Preview {
    PreviewEnvironment { HomeView() }
}
