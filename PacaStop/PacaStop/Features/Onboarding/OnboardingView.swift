//
//  OnboardingView.swift
//  PacaStop
//
//  The persuasion core (§5.2). Five linear steps with a segmented progress bar and a
//  single bottom CTA that's disabled until the step's requirement is met. The emotional
//  turn (steps 3–4) is where the user *sees* he can't win; step 5 is the commitment pledge.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class OnboardingViewModel {
    let totalSteps = 5
    var step = 1
    var frequency: Frequency?
    var amount: Double = 200
    var simulationSeed: UInt64 = 0x1234_5678

    /// The commitment pledge (final step). The user must type the required phrase to advance —
    /// a small self-binding ritual that lifts follow-through into the paywall.
    var pledge = ""
    var requiredPledge = ""
    var pledgeMatches: Bool {
        !requiredPledge.isEmpty && Self.normalizePledge(pledge) == Self.normalizePledge(requiredPledge)
    }

    /// Forgiving comparison: ignores case, diacritics, and extra spacing (typing "ă/â/ă" on a
    /// phone is hard), so "ma jur ca ma las de aparate" matches "Mă jur că mă las de aparate".
    static func normalizePledge(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "ro"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    /// Bankroll the house-edge sim starts from — the user's own session amount (min 100).
    var simulationStart: Double { max(amount, 100) }

    var savingsProfile: SavingsProfile? {
        frequency.map { SavingsProfile(frequency: $0, amountPerSession: amount) }
    }
    var weeklyLoss: Double { savingsProfile?.weeklyLoss ?? 0 }
    var yearlyLoss: Double { savingsProfile?.yearlyLoss ?? 0 }

    var canAdvance: Bool {
        switch step {
        case 1: frequency != nil
        case 5: pledgeMatches
        default: true
        }
    }

    var isLastStep: Bool { step == totalSteps }

    func advance() {
        guard step < totalSteps else { return }
        step += 1
    }

    func back() {
        guard step > 1 else { return }
        step -= 1
    }

    func replaySimulation() {
        simulationSeed = simulationSeed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    }

    func makeSimulation() -> HouseEdgeResult {
        HouseEdgeSimulation.run(start: simulationStart, seed: simulationSeed)
    }
}

struct OnboardingView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(LocalizationStore.self) private var loc
    @State private var vm = OnboardingViewModel()
    @State private var stepEnteredAt = Date()
    @State private var onboardingStartedAt = Date()

    private var s: any Localization { loc.s }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            topBar

            ScrollView {
                stepContent
                    .padding(.horizontal, Spacing.screenH)
                    .padding(.top, Spacing.xs)
                    .padding(.bottom, Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(vm.step)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
            .scrollBounceBehavior(.basedOnSize)

            cta
                .padding(.horizontal, Spacing.screenH)
                .padding(.bottom, Spacing.xs)
        }
        .animation(Motion.smooth, value: vm.step)
        .screenBackground()
        .onAppear {
            let now = Date()
            onboardingStartedAt = now
            stepEnteredAt = now
            env.analytics.track(.onboardingStarted)
            env.analytics.track(.onboardingStepViewed(1))
        }
        .onChange(of: vm.step) { oldStep, newStep in
            env.analytics.track(.onboardingStepCompleted(step: oldStep, seconds: Date().timeIntervalSince(stepEnteredAt)))
            stepEnteredAt = Date()
            env.analytics.track(.onboardingStepViewed(newStep))
        }
    }

    private var topBar: some View {
        HStack(spacing: Spacing.md) {
            Button {
                env.analytics.track(.onboardingBackTapped(fromStep: vm.step))
                vm.back()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(vm.step > 1 ? Palette.textPrimary : Palette.textFaint)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(PressableScale())
            .disabled(vm.step == 1)

            VStack(alignment: .leading, spacing: 6) {
                Text(s.onboardingStep(vm.step, of: vm.totalSteps))
                    .font(Typo.kicker)
                    .tracking(1.5)
                    .foregroundStyle(Palette.textTertiary)
                SegmentedProgressBar(total: vm.totalSteps, current: vm.step,
                                     accessibilityLabelText: s.onboardingStep(vm.step, of: vm.totalSteps))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, Spacing.xs)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch vm.step {
        case 1: OnboardingStepFrequency(vm: vm)
        case 2: OnboardingStepMoney(vm: vm)
        case 3: OnboardingStepReveal(vm: vm)
        case 4: OnboardingStepCommit(vm: vm)
        default: OnboardingStepPledge(vm: vm)
        }
    }

    private var cta: some View {
        PacaButton(
            title: vm.isLastStep ? s.step4CTA : s.continueLabel,
            kind: .lime,
            isEnabled: vm.canAdvance
        ) {
            if vm.isLastStep {
                completeOnboarding()
            } else {
                withAnimation(Motion.smooth) { vm.advance() }
            }
        }
    }

    private func completeOnboarding() {
        guard let frequency = vm.frequency else { return }
        let now = Date()
        env.analytics.track(.onboardingStepCompleted(step: vm.step, seconds: now.timeIntervalSince(stepEnteredAt)))
        env.analytics.track(.onboardingCompleted(seconds: now.timeIntervalSince(onboardingStartedAt)))
        env.appModel.completeOnboarding(frequency: frequency, amount: vm.amount)
    }
}

#Preview {
    PreviewEnvironment(.preview(seedDemo: false, subscribed: false)) { OnboardingView() }
}
