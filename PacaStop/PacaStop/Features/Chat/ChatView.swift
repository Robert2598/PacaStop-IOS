//
//  ChatView.swift
//  PacaStop
//
//  The AI recovery-mentor chat. Streaming bubbles, an always-visible "not a therapist"
//  note, and crisis routing: when the mentor detects danger it surfaces the helpline and
//  the 60-second panic takeover — reusing the app's existing crisis machinery.
//

import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(LocalizationStore.self) private var loc

    @State private var model: ChatViewModel?
    @State private var showPanic = false
    @FocusState private var inputFocused: Bool

    private var s: any Localization { loc.s }

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear.screenBackground()
            }
        }
        .task {
            guard model == nil else { return }
            let vm = ChatViewModel(
                modelContext: env.modelContainer.mainContext,
                chat: env.chat,
                appModel: env.appModel,
                analytics: env.analytics,
                loc: loc
            )
            vm.load()
            model = vm
            env.analytics.track(.chatOpened)
        }
        .onDisappear { model?.cancel() }
        .fullScreenCover(isPresented: $showPanic) { PanicView() }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ model: ChatViewModel) -> some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(Palette.hairline).frame(height: 1)
            messagesArea(model)
        }
        .screenBackground()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar(model)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.chatTitle)
                        .font(Typo.screenTitle)
                        .foregroundStyle(Palette.textPrimary)
                    Text(s.chatSubtitle)
                        .font(Typo.bodySm)
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer(minLength: 0)
            }
            Text(s.chatDisclaimer)
                .font(Typo.caption)
                .foregroundStyle(Palette.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.md)
    }

    // MARK: - Messages

    @ViewBuilder
    private func messagesArea(_ model: ChatViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.sm) {
                    if model.isEmpty {
                        emptyState(model)
                    } else {
                        ForEach(model.messages) { message in
                            MentorBubble(message: message, typingLabel: s.chatTyping)
                                .id(message.id)
                        }
                    }
                    Color.clear.frame(height: 1).id(Self.bottomAnchor)
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.vertical, Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: model.messages.count) { scrollToBottom(proxy) }
            .onChange(of: model.messages.last?.text) { scrollToBottom(proxy) }
        }
    }

    private static let bottomAnchor = "chat-bottom"

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(Motion.snappy) { proxy.scrollTo(Self.bottomAnchor, anchor: .bottom) }
    }

    // MARK: - Empty state

    @ViewBuilder
    private func emptyState(_ model: ChatViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(s.chatEmptyTitle)
                    .font(Typo.title)
                    .foregroundStyle(Palette.textPrimary)
                Text(s.chatEmptyBody)
                    .font(Typo.bodyMd)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            FlowChips(items: s.chatSuggestions) { model.send($0) }
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: - Bottom (crisis / urge / error / input)

    @ViewBuilder
    private func bottomBar(_ model: ChatViewModel) -> some View {
        VStack(spacing: Spacing.xs) {
            if model.risk == .crisis {
                crisisBanner
            } else if model.risk == .elevated {
                urgeQuickAction
            }
            if let error = model.errorMessage {
                Text(error)
                    .font(Typo.caption)
                    .foregroundStyle(Palette.softRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            inputRow(model)
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.xs)
        .background(Palette.background.ignoresSafeArea(edges: .bottom))
    }

    @ViewBuilder
    private func inputRow(_ model: ChatViewModel) -> some View {
        @Bindable var model = model
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            TextField(s.chatInputPlaceholder, text: $model.input, axis: .vertical)
                .font(Typo.bodyMd)
                .foregroundStyle(Palette.textPrimary)
                .tint(Palette.lime)
                .lineLimit(1...5)
                .focused($inputFocused)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 11)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.field, style: .continuous)
                        .strokeBorder(inputFocused ? Palette.limeSoftBorder : Palette.hairline, lineWidth: 1)
                )

            Button {
                inputFocused = false
                model.send()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Palette.onLime)
                    .frame(width: 44, height: 44)
                    .background(Palette.lime, in: Circle())
                    .opacity(model.canSend ? 1 : 0.4)
            }
            .buttonStyle(PressableScale())
            .disabled(!model.canSend)
            .accessibilityLabel(s.chatSendLabel)
        }
    }

    // MARK: - Crisis + urge

    private var crisisBanner: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Kicker(s.chatCrisisTitle, color: Palette.softRed)
            Text(s.chatCrisisBody)
                .font(Typo.bodySm)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if let tel = URL(string: "tel:0800800099") {
                Link(destination: tel) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "phone.fill")
                        Text(s.panicHelpline)
                    }
                    .font(Typo.label)
                    .foregroundStyle(Palette.softRed)
                }
            }
            PacaButton(title: s.chatOpenPanic, kind: .redOutline, icon: "hand.raised.fill") {
                showPanic = true
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.redSoftFill, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Palette.redSoftBorder, lineWidth: 1)
        )
    }

    private var urgeQuickAction: some View {
        Button { showPanic = true } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "hand.raised.fill")
                Text(s.chatUrgeHint)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
            }
            .font(Typo.label)
            .foregroundStyle(Palette.lime)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(Palette.limeSoftFill, in: RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .strokeBorder(Palette.limeSoftBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PressableScale())
    }
}

// MARK: - Bubble

private struct MentorBubble: View {
    let message: ChatMessage
    let typingLabel: String

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 44) }
            Group {
                if !isUser && message.text.isEmpty && message.isStreaming {
                    TypingDots()
                        .accessibilityLabel(typingLabel)
                } else {
                    Text(message.text)
                        .font(Typo.bodyMd)
                        .foregroundStyle(isUser ? Palette.onLime : Palette.textPrimary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isUser ? Palette.lime : Palette.surface,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isUser ? .clear : Palette.hairline, lineWidth: 1)
            )
            if !isUser { Spacer(minLength: 44) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}

// MARK: - Typing indicator

private struct TypingDots: View {
    @State private var phase = 0.0
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Palette.textTertiary)
                    .frame(width: 7, height: 7)
                    .opacity(0.35 + 0.65 * pulse(i))
            }
        }
        .frame(height: 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }
    private func pulse(_ i: Int) -> Double {
        let shifted = (phase + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
        return abs(sin(shifted * .pi))
    }
}

// MARK: - Suggestion chips

private struct FlowChips: View {
    let items: [String]
    let onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ForEach(items, id: \.self) { item in
                Button { onTap(item) } label: {
                    Text(item)
                        .font(Typo.label)
                        .foregroundStyle(Palette.textPrimary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                                .strokeBorder(Palette.hairline, lineWidth: 1)
                        )
                }
                .buttonStyle(PressableScale())
            }
        }
    }
}

#Preview {
    PreviewEnvironment { MainTabView() }
}
