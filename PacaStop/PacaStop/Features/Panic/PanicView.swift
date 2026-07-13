//
//  PanicView.swift
//  PacaStop
//
//  The 60-second lockout (§5.4). Full-screen takeover, deep oxblood red, no navigation.
//  Two states: counting down (rotating firm messages + depleting ring + reality-check) and
//  held-out ("AI REZISTAT"). Leaving early is allowed and does NOT break the streak — the
//  deterrent is the wait itself. It runs with zero dependencies so it never fails to load.
//

import SwiftUI
import Observation

enum PanicState { case counting, resisted }

@Observable
@MainActor
final class PanicViewModel {
    let totalSeconds: Int
    var remaining: Double
    var messageIndex = 0
    var state: PanicState = .counting

    @ObservationIgnored private var ticker: Task<Void, Never>?

    init(totalSeconds: Int = PanicConfig.defaultSeconds) {
        self.totalSeconds = totalSeconds
        self.remaining = Double(totalSeconds)
    }

    var fraction: Double { remaining / Double(totalSeconds) }
    var secondsRemaining: Int { max(0, Int(remaining.rounded(.up))) }
    var secondsElapsed: Int { totalSeconds - secondsRemaining }

    func start(messageCount: Int) {
        guard ticker == nil else { return }
        let tick = 0.1
        ticker = Task { [weak self] in
            var sinceRotation = 0.0
            while let self, self.remaining > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(tick))
                guard !Task.isCancelled else { return }
                self.remaining = max(0, self.remaining - tick)
                sinceRotation += tick
                if sinceRotation >= PanicConfig.messageRotationInterval, messageCount > 0 {
                    sinceRotation = 0
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.messageIndex = (self.messageIndex + 1) % messageCount
                    }
                }
            }
            if let self, self.remaining <= 0, !Task.isCancelled {
                withAnimation(Motion.smooth) { self.state = .resisted }
            }
        }
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
    }
}

struct PanicView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(LocalizationStore.self) private var loc
    @Environment(\.dismiss) private var dismiss

    @State private var vm = PanicViewModel()

    private var s: any Localization { loc.s }
    private var model: AppModel { env.appModel }

    private var messages: [String] {
        s.panicMessages(saved: MoneyFormatter.leiWhole(model.saved()), streak: model.streakDays())
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Palette.panicBackground, Palette.panicBackgroundDeep],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            switch vm.state {
            case .counting: countingView
            case .resisted: resistedView
            }
        }
        .onAppear {
            env.analytics.track(.panicOpened)
            vm.start(messageCount: messages.count)
        }
        .onDisappear { vm.stop() }
        .onChange(of: vm.state) { _, newState in
            if newState == .resisted {
                model.recordPanic(heldOut: true, seconds: vm.totalSeconds)
            }
        }
    }

    // MARK: - Counting

    private var countingView: some View {
        VStack(spacing: Spacing.lg) {
            Text(s.panicTitle)
                .font(Typo.hero)
                .foregroundStyle(.white)
                .padding(.top, Spacing.md)

            Text(messages[min(vm.messageIndex, messages.count - 1)])
                .font(Typo.title)
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .id(vm.messageIndex)
                .transition(.opacity)
                .frame(maxWidth: .infinity, minHeight: 84, alignment: .center)
                .padding(.horizontal, Spacing.md)

            CountdownRing(
                fraction: vm.fraction,
                secondsRemaining: vm.secondsRemaining,
                unitLabel: s.secondsUnit
            )

            realityCard

            Spacer(minLength: 0)

            footer
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.bottom, Spacing.md)
    }

    private var realityCard: some View {
        let amount = model.profile.amountPerSession
        return VStack(spacing: Spacing.xxs) {
            Text(s.panicRealityKicker)
                .font(Typo.kicker)
                .tracking(1)
                .foregroundStyle(Palette.softRed)
            Text(MoneyFormatter.leiWhole(amount))
                .font(Typo.displayMd)
                .foregroundStyle(Palette.red)
            Text(s.panicRealityLine(liters: PanicCalculator.litresOfFuel(amount: amount)))
                .font(Typo.caption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Palette.red.opacity(0.10), in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.field, style: .continuous).strokeBorder(Palette.redSoftBorder, lineWidth: 1))
    }

    private var footer: some View {
        VStack(spacing: Spacing.sm) {
            VStack(spacing: 2) {
                Text(s.panicHelplinePrefix)
                    .font(Typo.caption)
                    .foregroundStyle(.white.opacity(0.45))
                Text(s.panicHelpline)
                    .font(.body(13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            Button {
                giveUp()
            } label: {
                Text(s.panicGiveUp)
                    .font(Typo.caption)
                    .foregroundStyle(.white.opacity(0.35))
                    .underline()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Resisted

    private var resistedView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            CheckBurst()
            Text(s.panicResistedTitle)
                .font(Typo.hero)
                .foregroundStyle(Palette.lime)
            Text(s.panicResistedSub)
                .font(Typo.bodyLg)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.md)
            Spacer()
            PacaButton(title: s.panicResistedButton, kind: .lime) { dismiss() }
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.bottom, Spacing.lg)
    }

    // MARK: - Actions

    private func giveUp() {
        model.recordPanic(heldOut: false, seconds: vm.totalSeconds)
        env.analytics.track(.panicGaveUp(secondsRemaining: vm.secondsRemaining))
        dismiss()
    }
}

/// A lime check-burst shown when the user holds out.
private struct CheckBurst: View {
    @State private var shown = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Palette.lime.opacity(0.15))
                .frame(width: 120, height: 120)
                .scaleEffect(shown ? 1 : 0.4)
            Circle()
                .fill(Palette.lime)
                .frame(width: 82, height: 82)
                .scaleEffect(shown ? 1 : 0.5)
            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .heavy))
                .foregroundStyle(Palette.onLime)
                .scaleEffect(shown ? 1 : 0.3)
        }
        .shadow(color: Palette.lime.opacity(0.5), radius: 20)
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { shown = true } }
        .accessibilityHidden(true)
    }
}

#Preview {
    PreviewEnvironment { PanicView() }
}
