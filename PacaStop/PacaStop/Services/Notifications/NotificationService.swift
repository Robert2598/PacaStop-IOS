//
//  NotificationService.swift
//  PacaStop
//
//  Optional, opt-in, private local notifications (a daily reality-check reminder).
//  Never networked — scheduled entirely on-device.
//

import Foundation
import UserNotifications
import os

@MainActor
protocol NotificationService: AnyObject {
    func authorizationGranted() async -> Bool
    func requestAuthorization() async -> Bool
    func scheduleDailyReminder(title: String, body: String, hour: Int, minute: Int) async
    func cancelDailyReminder()
}

@MainActor
final class LocalNotificationService: NotificationService {
    private let center = UNUserNotificationCenter.current()
    private let reminderID = "pacastop.daily.reminder"
    private let logger = Logger(subsystem: "com.pixelpaw.PacaStop", category: "Notifications")

    func authorizationGranted() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            logger.error("Notification auth failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func scheduleDailyReminder(title: String, body: String, hour: Int, minute: Int) async {
        cancelDailyReminder()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: reminderID, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [reminderID])
    }
}
