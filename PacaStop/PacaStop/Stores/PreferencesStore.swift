//
//  PreferencesStore.swift
//  PacaStop
//
//  Lightweight device preferences (daily reminder). Language lives in LocalizationStore.
//  The app is dark-only, so there is no theme preference.
//

import Foundation
import Observation

@Observable
@MainActor
final class PreferencesStore {
    private enum Keys {
        static let dailyReminder = "pacastop.pref.dailyReminder"
    }

    var dailyReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(dailyReminderEnabled, forKey: Keys.dailyReminder) }
    }

    /// Fixed evening slot for the reality-check reminder.
    let reminderHour = 20
    let reminderMinute = 0

    init() {
        let defaults = UserDefaults.standard
        dailyReminderEnabled = defaults.object(forKey: Keys.dailyReminder) as? Bool ?? false
    }
}
