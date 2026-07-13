//
//  OnboardingSteps.swift
//  PacaStop
//
//  The five onboarding step bodies + the animated house-edge simulation chart.
//

import SwiftUI

// MARK: - Step 1 · Frequency

struct OnboardingStepFrequency: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(AppEnvironment.self) private var env
    @Environment(LocalizationStore.self) private var loc
    private var s: any Localization { loc.s }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            StepHeader(title: s.step1Title, subtitle: s.step1Sub)
            VStack(spacing: Spacing.sm) {
                ForEach(Frequency.allCases) { freq in
                    SelectableRow(title: s.frequencyLabel(freq), isSelected: vm.frequency == freq) {
                        withAnimation(Motion.snappy) { vm.frequency = freq }
                        env.analytics.track(.frequencySelected(freq))
                    }
                }
            }
            .padding(.top, Spacing.xs)
        }
    }
}

// MARK: - Step 2 · Money

struct OnboardingStepMoney: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(AppEnvironment.self) private var env
    @Environment(LocalizationStore.self) private var loc
    private var s: any Localization { loc.s }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            StepHeader(title: s.step2Title, subtitle: nil)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(MoneyFormatter.number(vm.amount, decimals: 0))
                    .font(.display(66))
                    .foregroundStyle(Palette.lime)
                    .contentTransition(.numericText(value: vm.amount))
                Text("lei")
                    .font(.display(24))
                    .foregroundStyle(Palette.lime.opacity(0.7))
            }
            .frame(maxWidth: .infinity)

            Slider(value: $vm.amount, in: 50...2000, step: 10) { editing in
                if !editing { env.analytics.track(.amountChanged(vm.amount)) }
            }
            .tint(Palette.lime)

            projection
        }
    }

    private var projection: some View {
        SectionCard {
            VStack(spacing: Spacing.sm) {
                projectionRow(label: s.step2PerWeek,
                              value: MoneyFormatter.leiWhole(vm.weeklyLoss),
                              color: Palette.textPrimary, big: false)
                Divider().overlay(Palette.hairline)
                projectionRow(label: s.step2PerYear,
                              value: MoneyFormatter.leiWhole(vm.yearlyLoss),
                              color: Palette.red, big: true)
            }
        }
    }

    private func projectionRow(label: String, value: String, color: Color, big: Bool) -> some View {
        HStack {
            Text(label)
                .font(Typo.bodyMd)
                .foregroundStyle(Palette.textSecondary)
            Spacer()
            Text(value)
                .font(big ? Typo.displayMd : Typo.title)
                .foregroundStyle(color)
                .contentTransition(.numericText(value: big ? vm.yearlyLoss : vm.weeklyLoss))
        }
    }
}

// MARK: - Step 3 · House-edge reveal

struct OnboardingStepReveal: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(AppEnvironment.self) private var env
    @Environment(LocalizationStore.self) private var loc
    private var s: any Localization { loc.s }

    @State private var result: HouseEdgeResult?
    @State private var revealFinished = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Kicker(s.step3Kicker)
            Text(s.step3Title)
                .font(Typo.hero)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(s.step3Body)
                .font(Typo.bodyMd)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                replay()
            } label: {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    if let result {
                        HouseEdgeChart(bars: result.normalizedBars) {
                            withAnimation(.easeIn(duration: 0.35)) { revealFinished = true }
                        }
                        .id(vm.simulationSeed)
                        if revealFinished {
                            HStack {
                                Text(s.step3Result(
                                    start: MoneyFormatter.leiWhole(vm.simulationStart),
                                    remaining: MoneyFormatter.leiWhole(result.remaining)
                                ))
                                .font(Typo.headline)
                                .foregroundStyle(Palette.softRed)
                                .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                                Label(s.step3Replay, systemImage: "arrow.clockwise")
                                    .font(Typo.caption)
                                    .foregroundStyle(Palette.textTertiary)
                            }
                            .transition(.opacity)
                        }
                    }
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity)
                .pacaCard(Palette.surfaceDeep)
            }
            .buttonStyle(PressableScale())
        }
        .onAppear { if result == nil { result = vm.makeSimulation() } }
    }

    private func replay() {
        revealFinished = false
        vm.replaySimulation()
        result = vm.makeSimulation()
        env.analytics.track(.houseEdgeReplayed)
    }
}

// MARK: - Step 4 · Commit

struct OnboardingStepCommit: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(LocalizationStore.self) private var loc
    private var s: any Localization { loc.s }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Kicker(s.step4Kicker)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(s.step4YearlyLoss(""))
                    .font(Typo.title)
                    .foregroundStyle(Palette.textSecondary)
                Text(MoneyFormatter.leiWhole(vm.yearlyLoss))
                    .font(Typo.displayLg)
                    .foregroundStyle(Palette.red)
            }
            .padding(.vertical, Spacing.md)

            Text(s.step4Flip)
                .font(Typo.hero)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Step 5 · Commitment pledge

struct OnboardingStepPledge: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(LocalizationStore.self) private var loc
    private var s: any Localization { loc.s }
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            StepHeader(title: s.pledgeTitle, subtitle: s.pledgeBody)

            // The exact phrase to copy.
            Text("„\(s.pledgePhrase)”")
                .font(Typo.headline)
                .foregroundStyle(Palette.lime)
                .fixedSize(horizontal: false, vertical: true)
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .pacaCard(Palette.surfaceDeep)

            // The pledge input.
            TextField(s.pledgePlaceholder, text: $vm.pledge, axis: .vertical)
                .font(Typo.bodyLg)
                .foregroundStyle(Palette.textPrimary)
                .tint(Palette.lime)
                .focused($focused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .pacaCard(Palette.surface,
                          border: vm.pledgeMatches ? Palette.lime : Palette.hairline,
                          borderWidth: vm.pledgeMatches ? 1.5 : 1)
                .overlay(alignment: .topTrailing) {
                    if vm.pledgeMatches {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Palette.lime)
                            .padding(Spacing.md)
                    }
                }

            if !vm.pledge.isEmpty && !vm.pledgeMatches {
                Text(s.pledgeHint)
                    .font(Typo.caption)
                    .foregroundStyle(Palette.softRed)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            vm.requiredPledge = s.pledgePhrase
            focused = true
        }
    }
}

// MARK: - Shared step pieces

struct StepHeader: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(Typo.screenTitle)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(Typo.bodyMd)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }
}

struct SelectableRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Text(title)
                    .font(Typo.bodyLg)
                    .foregroundStyle(isSelected ? Palette.textPrimary : Palette.textSecondary)
                Spacer()
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Palette.lime : Palette.textTertiary, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(Palette.lime).frame(width: 12, height: 12)
                    }
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
            .pacaCard(Palette.surface, border: isSelected ? Palette.lime : Palette.hairline,
                      borderWidth: isSelected ? 1.5 : 1)
        }
        .buttonStyle(PressableScale())
    }
}

/// The 100-spin bankroll bars, draining left→right from full lime to almost-nothing red.
struct HouseEdgeChart: View {
    let bars: [Double]
    var onComplete: () -> Void = {}
    @State private var revealed = false

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 1) {
                ForEach(bars.indices, id: \.self) { i in
                    let v = bars[i]
                    Capsule(style: .continuous)
                        .fill(barColor(v))
                        .frame(height: max(2, (revealed ? v : 1) * geo.size.height))
                        .animation(.easeOut(duration: 0.5).delay(Double(i) * 0.012), value: revealed)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 150)
        .onAppear { revealed = true }
        .task {
            // Fire once the last bar has finished draining, so the result reveals after.
            let total = 0.5 + Double(bars.count) * 0.012
            try? await Task.sleep(for: .seconds(total))
            onComplete()
        }
    }

    private func barColor(_ v: Double) -> Color {
        Color.blend(Palette.red, Palette.lime, t: v)
    }
}

extension Color {
    /// Linear blend between two colors; `t = 0` → `a`, `t = 1` → `b`.
    static func blend(_ a: Color, _ b: Color, t: Double) -> Color {
        let ua = UIColor(a), ub = UIColor(b)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab_: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        ua.getRed(&ar, green: &ag, blue: &ab_, alpha: &aa)
        ub.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        let clamped = max(0, min(1, t))
        return Color(
            red: ar + (br - ar) * clamped,
            green: ag + (bg - ag) * clamped,
            blue: ab_ + (bb - ab_) * clamped
        )
    }
}
