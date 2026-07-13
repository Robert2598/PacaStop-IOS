//
//  AppLanguage.swift
//  PacaStop
//
//  The app ships Romanian (primary) + English, switchable live from Settings.
//  Switching retranslates the entire UI instantly — no restart — because every
//  view reads strings through the injected LocalizationStore.
//

import SwiftUI
import Observation

nonisolated enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case ro
    case en

    /// The language's own endonym, shown in Settings.
    var displayName: String {
        switch self {
        case .ro: "Română"
        case .en: "English"
        }
    }

    var other: AppLanguage { self == .ro ? .en : .ro }
}

/// Holds the active language and vends the matching string table. Injected via
/// `@Environment`; any view reading `loc.s.…` re-renders when the language flips.
@Observable
final class LocalizationStore {
    private static let storageKey = "pacastop.language"

    var language: AppLanguage {
        didSet {
            guard language != oldValue else { return }
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
        }
    }

    /// The active string table.
    var s: any Localization {
        switch language {
        case .ro: Self.ro
        case .en: Self.en
        }
    }

    private static let ro = RomanianStrings()
    private static let en = EnglishStrings()

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let saved = AppLanguage(rawValue: raw) {
            language = saved
        } else {
            language = .ro   // Romanian is primary.
        }
    }

    func toggleLanguage() {
        withAnimation(Motion.snappy) { language = language.other }
    }
}
