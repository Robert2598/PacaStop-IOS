//
//  ChatMessage.swift
//  PacaStop
//
//  One line of the mentor conversation, persisted on-device via SwiftData (encrypted at
//  rest like everything else). History never leaves the phone except as the last few turns
//  sent to the proxy to give the reply continuity — and never with any financial data.
//

import Foundation
import SwiftData

nonisolated enum ChatRole: String, Codable, Sendable {
    case user
    case mentor
    /// Wire role for the Anthropic proxy (mentor → "assistant").
    var wire: String { self == .user ? "user" : "assistant" }
}

@Model
final class ChatMessage {
    var createdAt: Date
    var roleRaw: String
    var text: String
    /// True while the mentor reply is still streaming in (drives the typing indicator).
    var isStreaming: Bool
    /// Owning account (`UserProfile.authUserID`) so one user never reads another's conversation
    /// on a shared device. `nil` = legacy row, adopted on first sign-in after the upgrade.
    var ownerID: String?

    init(role: ChatRole, text: String, createdAt: Date = Date(), isStreaming: Bool = false, ownerID: String? = nil) {
        self.createdAt = createdAt
        self.roleRaw = role.rawValue
        self.text = text
        self.isStreaming = isStreaming
        self.ownerID = ownerID
    }

    var role: ChatRole { ChatRole(rawValue: roleRaw) ?? .mentor }
}
