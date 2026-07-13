//
//  BadgeUnlock.swift
//  PacaStop
//
//  A badge, once earned, is sticky — it survives a relapse (history is preserved, §6.2).
//  We persist an unlock record the first time a badge's condition is met.
//

import Foundation
import SwiftData

@Model
final class BadgeUnlock {
    /// Not globally unique any more: on a shared device two accounts may each earn the same
    /// badge. Per-account uniqueness is enforced in `AppModel.evaluateBadges`, which only inserts
    /// a badge the active user hasn't already earned.
    var badgeRaw: String
    var unlockedAt: Date
    /// Owning account (`UserProfile.authUserID`). `nil` = legacy row, adopted on first sign-in.
    var ownerID: String?

    init(badge: Badge, unlockedAt: Date = Date(), ownerID: String? = nil) {
        self.badgeRaw = badge.rawValue
        self.unlockedAt = unlockedAt
        self.ownerID = ownerID
    }

    var badge: Badge? { Badge(rawValue: badgeRaw) }
}
