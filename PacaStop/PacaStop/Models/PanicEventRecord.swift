//
//  PanicEventRecord.swift
//  PacaStop
//
//  One record per panic session. `heldOut == true` means the user ran out the full
//  clock — that's a "craving beaten" (feeds a badge, §6.4).
//

import Foundation
import SwiftData

@Model
final class PanicEventRecord {
    var date: Date
    var heldOut: Bool
    var configuredSeconds: Int
    /// The account this record belongs to (`UserProfile.authUserID`). `nil` marks a legacy row
    /// created before per-account isolation — the first account to sign in after the upgrade
    /// adopts it (see `AppModel.adoptOrphanRecords`).
    var ownerID: String?

    init(date: Date = Date(), heldOut: Bool, configuredSeconds: Int, ownerID: String? = nil) {
        self.date = date
        self.heldOut = heldOut
        self.configuredSeconds = configuredSeconds
        self.ownerID = ownerID
    }
}
