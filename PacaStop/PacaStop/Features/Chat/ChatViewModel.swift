//
//  ChatViewModel.swift
//  PacaStop
//
//  Drives the mentor conversation: persists turns to SwiftData, streams the reply, and
//  surfaces the crisis/urge signal so the UI can route to the helpline or panic button.
//  Only non-financial context is ever sent (see AppModel.recoveryContext).
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class ChatViewModel {
    @ObservationIgnored private let modelContext: ModelContext
    @ObservationIgnored private let chat: any ChatService
    @ObservationIgnored private let appModel: AppModel
    @ObservationIgnored private let analytics: any AnalyticsService
    @ObservationIgnored private let loc: LocalizationStore

    private(set) var messages: [ChatMessage] = []
    var input: String = ""
    private(set) var isStreaming = false
    /// The latest turn's risk, driving the crisis banner / urge quick-action.
    private(set) var risk: ChatRisk = .none
    private(set) var errorMessage: String?

    @ObservationIgnored private var streamTask: Task<Void, Never>?

    init(
        modelContext: ModelContext,
        chat: any ChatService,
        appModel: AppModel,
        analytics: any AnalyticsService,
        loc: LocalizationStore
    ) {
        self.modelContext = modelContext
        self.chat = chat
        self.appModel = appModel
        self.analytics = analytics
        self.loc = loc
    }

    func load() {
        // Only this account's conversation — never another user's on a shared device.
        let owner = appModel.activeOwner
        let descriptor = FetchDescriptor<ChatMessage>(
            predicate: #Predicate { $0.ownerID == owner },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        messages = (try? modelContext.fetch(descriptor)) ?? []
        // Heal any message left mid-stream by a previous session.
        for m in messages where m.isStreaming { m.isStreaming = false }
    }

    var isEmpty: Bool { messages.isEmpty }
    var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isStreaming
    }

    func send(_ textOverride: String? = nil) {
        let text = (textOverride ?? input).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }
        input = ""
        errorMessage = nil

        // History = prior completed turns (built before inserting the new pair).
        let history = messages
            .filter { !$0.text.isEmpty }
            .suffix(16)
            .map { ChatTurn(role: $0.role.wire, content: $0.text) }

        let owner = appModel.activeOwner
        let userMsg = ChatMessage(role: .user, text: text, ownerID: owner)
        let mentorMsg = ChatMessage(role: .mentor, text: "", isStreaming: true, ownerID: owner)
        modelContext.insert(userMsg)
        modelContext.insert(mentorMsg)
        messages.append(userMsg)
        messages.append(mentorMsg)
        save()

        analytics.track(.chatMessageSent)
        isStreaming = true

        let context = appModel.recoveryContext(language: loc.language)

        streamTask = Task { [weak self] in
            guard let self else { return }
            let stream = chat.stream(message: text, context: context, history: history)
            do {
                for try await chunk in stream {
                    switch chunk {
                    case .meta(let risk, let actions):
                        self.risk = risk
                        if risk == .crisis { analytics.track(.chatCrisisDetected) }
                        if !actions.isEmpty {
                            analytics.track(.chatEscalated(actions.joined(separator: ",")))
                        }
                    case .delta(let t):
                        mentorMsg.text += t
                    case .done:
                        break
                    }
                }
                finish(mentorMsg)
            } catch {
                errorMessage = self.message(for: error)
                finish(mentorMsg)
            }
            isStreaming = false
        }
    }

    /// Stops streaming (e.g. when leaving the screen).
    func cancel() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }

    private func finish(_ mentorMsg: ChatMessage) {
        mentorMsg.isStreaming = false
        // Drop an empty placeholder if the reply produced nothing.
        if mentorMsg.text.isEmpty {
            modelContext.delete(mentorMsg)
            messages.removeAll { $0 === mentorMsg }
        }
        save()
    }

    private func message(for error: Error) -> String {
        let s = loc.s
        if let e = error as? ChatServiceError {
            switch e {
            case .premiumRequired: return s.chatErrorPremium
            case .rateLimited: return s.chatErrorRateLimited
            case .network: return s.chatErrorOffline
            case .notAuthorized: return s.chatErrorSignInAgain
            case .server: return s.chatErrorGeneric
            }
        }
        if error is URLError { return s.chatErrorOffline }
        return s.chatErrorGeneric
    }

    private func save() {
        try? modelContext.save()
    }
}
