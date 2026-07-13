//
//  RemoteChatService.swift
//  PacaStop
//
//  Talks to the AI proxy over Server-Sent Events. Attaches the Clerk session token so the
//  proxy can authenticate the user before it ever touches the Anthropic key. Sends only the
//  message, the last few turns, and the non-financial RecoveryContext.
//

import Foundation

@MainActor
final class RemoteChatService: ChatService {
    private let endpoint: URL
    private let auth: any AuthService
    private let session: URLSession

    init(baseURL: URL, auth: any AuthService) {
        self.endpoint = baseURL.appendingPathComponent("v1/chat")
        self.auth = auth
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 60
        cfg.timeoutIntervalForResource = 300
        cfg.waitsForConnectivity = true
        self.session = URLSession(configuration: cfg)
    }

    private struct RequestBody: Encodable {
        let message: String
        let history: [ChatTurn]
        let context: RecoveryContext
    }
    private struct MetaPayload: Decodable { let risk: ChatRisk; let actions: [String] }
    private struct DeltaPayload: Decodable { let text: String }

    func stream(
        message: String,
        context: RecoveryContext,
        history: [ChatTurn]
    ) -> AsyncThrowingStream<ChatChunk, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { [self] in
                do {
                    guard let token = await auth.sessionToken() else {
                        // No session token — the Clerk session lapsed (or never existed). Let auth
                        // confirm/recover so the app routes to a clean re-login instead of a dead end.
                        await auth.handleUnauthorized()
                        throw ChatServiceError.notAuthorized
                    }

                    var req = URLRequest(url: endpoint)
                    req.httpMethod = "POST"
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    req.httpBody = try JSONEncoder().encode(
                        RequestBody(message: message, history: history, context: context)
                    )

                    let (bytes, response) = try await session.bytes(for: req)
                    guard let http = response as? HTTPURLResponse else { throw ChatServiceError.network }
                    guard (200..<300).contains(http.statusCode) else {
                        // A rejected token means the session died server-side — trigger the same recovery.
                        if http.statusCode == 401 { await auth.handleUnauthorized() }
                        throw ChatServiceError.from(status: http.statusCode)
                    }

                    var event = "message"
                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        if line.isEmpty { event = "message"; continue }
                        if line.hasPrefix("event:") {
                            event = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                        } else if line.hasPrefix("data:") {
                            let payload = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                            try emit(event: event, data: payload, to: continuation)
                        }
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func emit(
        event: String,
        data: String,
        to continuation: AsyncThrowingStream<ChatChunk, Error>.Continuation
    ) throws {
        guard let raw = data.data(using: .utf8) else { return }
        switch event {
        case "meta":
            if let m = try? JSONDecoder().decode(MetaPayload.self, from: raw) {
                continuation.yield(.meta(risk: m.risk, actions: m.actions))
            }
        case "delta":
            if let d = try? JSONDecoder().decode(DeltaPayload.self, from: raw) {
                continuation.yield(.delta(d.text))
            }
        case "done":
            continuation.yield(.done)
        case "error":
            throw ChatServiceError.server
        default:
            break
        }
    }
}
