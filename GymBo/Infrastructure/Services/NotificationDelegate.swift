//
//  NotificationDelegate.swift
//  GymBo
//
//  Created on 2025-10-26.
//  Handles notification presentation when app is in foreground
//

import UserNotifications

/// Delegate to handle notification presentation and user responses
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when a notification arrives while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📬 Notification arrived in foreground: \(notification.request.identifier)")

        // Show notification even when app is in foreground
        // - banner: Shows at top of screen
        // - sound: Plays notification sound
        // - badge: Updates app badge (optional)
        completionHandler([.banner, .sound])
    }

    /// Called when user taps on notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("👆 User tapped notification: \(response.notification.request.identifier)")

        // Handle notification tap (e.g., open app to specific screen)
        // For rest timer, just opening the app is enough

        completionHandler()
    }
}
