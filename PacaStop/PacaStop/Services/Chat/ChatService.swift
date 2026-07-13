//
//  ChatService.swift
//  PacaStop
//
//  The seam for the AI recovery mentor. `RemoteChatService` talks to the proxy (which holds
//  the Anthropic key); `PreviewChatService` is a fully-working canned fallback used in
//  previews and whenever no backend URL is configured, so the feature always runs.
//
//  PRIVACY INVARIANT: the mentor only ever receives non-financial recovery signals. No loss
//  amount, no money saved, not even a rounded band, and not the money-threshold badges. This
//  is enforced at the source in `AppModel.recoveryContext(language:)`.
//

import Foundation

nonisolated enum ChatRisk: String, Codable, Sendable {
    case none, elevated, crisis
}

/// One incremental event from the mentor stream.
nonisolated enum ChatChunk: Sendable {
    case meta(risk: ChatRisk, actions: [String])
    case delta(String)
    case done
}

/// A prior turn, in the compact wire shape the proxy expects.
nonisolated struct ChatTurn: Encodable, Sendable {
    let role: String   // "user" | "assistant"
    let content: String
}

/// The strictly non-financial user state sent with each message.
nonisolated struct RecoveryContext: Encodable, Sendable {
    let streakDays: Int
    let cravingsBeaten: Int
    let relapseCount: Int
    let carTier: String
    let badges: [String]
    let language: String
}

@MainActor
protocol ChatService: AnyObject {
    func stream(
        message: String,
        context: RecoveryContext,
        history: [ChatTurn]
    ) -> AsyncThrowingStream<ChatChunk, Error>
}

nonisolated enum ChatServiceError: LocalizedError {
    case notAuthorized
    case premiumRequired
    case rateLimited
    case server
    case network

    /// Maps an HTTP status from the proxy to a typed error.
    static func from(status: Int) -> ChatServiceError {
        switch status {
        case 401: .notAuthorized
        case 403: .premiumRequired
        case 429: .rateLimited
        default: .server
        }
    }
}

// MARK: - Car tier → stable slug the proxy understands

extension CarTier {
    var slug: String {
        switch self {
        case .rabla: "rabla"
        case .trezit: "trezit"
        case .viteza: "viteza"
        case .serios: "serios"
        case .smecher: "smecher"
        case .legenda: "legenda"
        }
    }
}

// MARK: - Context builder (the single place financial data is kept out)

extension AppModel {
    /// Assembles the non-financial context the mentor is allowed to see. Money-threshold
    /// badges (`thousandLei`, `fiveThousandLei`) are dropped because they'd reveal savings.
    func recoveryContext(language: AppLanguage) -> RecoveryContext {
        let financialBadges: Set<Badge> = [.thousandLei, .fiveThousandLei]
        let badges = earnedBadges
            .subtracting(financialBadges)
            .map(\.rawValue)
            .sorted()
        return RecoveryContext(
            streakDays: streakDays(),
            cravingsBeaten: cravingsBeaten,
            relapseCount: profile.relapseCount,
            carTier: currentTier().slug,
            badges: badges,
            language: language.rawValue
        )
    }
}

// MARK: - Canned fallback (works with zero backend; also powers previews)

/// A believable offline mentor. Keyword-aware so the crisis/urge UI can be exercised
/// without the backend. Replaced by `RemoteChatService` once `AI_BACKEND_URL` is set.
@MainActor
final class PreviewChatService: ChatService {
    func stream(
        message: String,
        context: RecoveryContext,
        history: [ChatTurn]
    ) -> AsyncThrowingStream<ChatChunk, Error> {
        let ro = context.language != "en"
        let lower = message.lowercased()

        let risk: ChatRisk
        if Self.matches(lower, Self.crisisWords) { risk = .crisis }
        else if Self.matches(lower, Self.urgeWords) { risk = .elevated }
        else { risk = .none }

        let reply = Self.reply(for: risk, ro: ro, streak: context.streakDays)
        let actions: [String] = risk == .crisis ? ["helpline", "panic"] : (risk == .elevated ? ["panic"] : [])

        return AsyncThrowingStream { continuation in
            let task = Task {
                continuation.yield(.meta(risk: risk, actions: actions))
                // Stream word-by-word so the typing feels real.
                for word in reply.split(separator: " ", omittingEmptySubsequences: false) {
                    if Task.isCancelled { break }
                    try? await Task.sleep(for: .milliseconds(28))
                    continuation.yield(.delta(String(word) + " "))
                }
                continuation.yield(.done)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static let crisisWords = ["sinuci", "mă omor", "nu mai pot", "kill myself", "end it", "no way out", "vreau să mor"]
    private static let urgeWords = ["poftă", "pofta", "impuls", "vreau să joc", "urge", "want to play", "gamble now", "să pariez"]
    private static func matches(_ text: String, _ words: [String]) -> Bool {
        words.contains { text.contains($0) }
    }

    private static func reply(for risk: ChatRisk, ro: Bool, streak: Int) -> String {
        switch risk {
        case .crisis:
            return ro
                ? "Stai cu mine o secundă. Ce simți acum contează și nu ești singur. Te rog sună acum la 112 sau la Joc Responsabil 0800 800 099 și, dacă poți, spune-i unui om apropiat. Eu nu-s doctor, dar un om real lângă tine chiar ajută acum."
                : "Stay with me a second. What you're feeling matters and you're not alone. Please call 112 or Joc Responsabil 0800 800 099 right now, and if you can, tell someone close to you. I'm not a doctor, but a real person beside you truly helps right now."
        case .elevated:
            return ro
                ? "Pofta e un val — urcă, atinge vârful și scade singură în câteva minute. Nu trebuie s-o hrănești. Apasă butonul de panică și ține 60 de secunde, sau ieși din locul ăsta acum. Ce te-a împins spre gând chiar acum?"
                : "The urge is a wave — it rises, peaks, and drops on its own in a few minutes. You don't have to feed it. Hit the panic button and hold 60 seconds, or step away from here now. What pushed you toward it just now?"
        case .none:
            let s = streak == 1 ? (ro ? "o zi" : "one day") : "\(streak) \(ro ? "zile" : "days")"
            return ro
                ? "Bine că vorbești. Ești la \(s) — asta contează. Spune-mi ce-ai pe suflet și ce te-ar ajuta acum."
                : "Good that you're talking. You're at \(s) — that counts. Tell me what's on your mind and what would help right now."
        }
    }
}
