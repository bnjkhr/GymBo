//
//  RestTimerStateManager.swift
//  GymBo
//
//  Created on 2025-10-22.
//  Rest Timer State Management
//

import Combine
import Foundation
import UserNotifications

/// State representing an active rest timer
struct RestTimerState: Codable {
    let duration: TimeInterval
    let endDate: Date

    var isExpired: Bool {
        Date() >= endDate
    }
}

/// Manager for rest timer state
///
/// **Features:**
/// - Start/stop rest timers
/// - Persist state across app restarts
/// - Observable for UI updates
///
/// **Usage:**
/// ```swift
/// let manager = RestTimerStateManager()
/// manager.startRest(duration: 90) // 90 seconds
/// if let state = manager.currentState {
///     print("Time remaining: \(state.endDate.timeIntervalSinceNow)")
/// }
/// ```
class RestTimerStateManager: ObservableObject {

    // MARK: - Properties

    @Published var currentState: RestTimerState?

    private let userDefaults = UserDefaults.standard
    private let stateKey = "restTimerState"
    private let notificationCenter = UNUserNotificationCenter.current()
    private let notificationId = "gymbo.restTimer"

    // MARK: - Initialization

    init() {
        loadState()
        requestNotificationPermissions()
    }

    // MARK: - Public Methods

    /// Start a new rest timer
    /// - Parameter duration: Duration in seconds
    func startRest(duration: TimeInterval) {
        let endDate = Date().addingTimeInterval(duration)
        currentState = RestTimerState(duration: duration, endDate: endDate)
        saveState()
        scheduleNotification(for: duration)
    }

    /// Cancel the current rest timer
    func cancelRest() {
        currentState = nil
        clearState()
        cancelNotification()
    }

    /// Check if timer has expired and auto-clear
    func checkExpiration() {
        guard let state = currentState, state.isExpired else { return }
        cancelRest()
    }

    // MARK: - Persistence

    func saveState() {
        guard let state = currentState,
            let data = try? JSONEncoder().encode(state)
        else {
            return
        }
        userDefaults.set(data, forKey: stateKey)
    }

    private func loadState() {
        guard let data = userDefaults.data(forKey: stateKey),
            let state = try? JSONDecoder().decode(RestTimerState.self, from: data)
        else {
            return
        }

        // Only load if not expired AND was saved recently (within 10 minutes)
        // This prevents old timers from auto-starting on new workout
        let tenMinutesAgo = Date().addingTimeInterval(-600)
        let wasRecentlySaved = state.endDate > tenMinutesAgo

        if !state.isExpired && wasRecentlySaved {
            currentState = state
        } else {
            clearState()
        }
    }

    private func clearState() {
        userDefaults.removeObject(forKey: stateKey)
    }

    // MARK: - Notifications

    /// Request notification permissions (silent, once)
    private func requestNotificationPermissions() {
        Task {
            // Check current status first
            let settings = await notificationCenter.notificationSettings()
            print("📱 Current notification status: \(settings.authorizationStatus.rawValue)")

            // If not determined, request
            if settings.authorizationStatus == .notDetermined {
                do {
                    let granted = try await notificationCenter.requestAuthorization(options: [
                        .alert, .sound, .badge,
                    ])
                    print(
                        granted
                            ? "✅ Notification permission GRANTED"
                            : "❌ Notification permission DENIED")
                } catch {
                    print("⚠️ Failed to request notification permissions: \(error)")
                }
            } else if settings.authorizationStatus == .denied {
                print("⚠️ Notifications are DENIED. User needs to enable in Settings.")
            } else if settings.authorizationStatus == .authorized {
                print("✅ Notifications already AUTHORIZED")
            }
        }
    }

    /// Schedule notification for when timer expires
    private func scheduleNotification(for duration: TimeInterval) {
        Task {
            // Check permission status first
            let settings = await notificationCenter.notificationSettings()
            guard settings.authorizationStatus == .authorized else {
                print(
                    "⚠️ Cannot schedule notification - permission status: \(settings.authorizationStatus.rawValue)"
                )
                return
            }

            // Cancel any existing notification first
            cancelNotification()

            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "Pause vorbei! ⏰"
            content.body = "Zeit für den nächsten Satz"
            content.sound = .default
            content.categoryIdentifier = "restTimer"

            // Create trigger (time interval from now)
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: duration,
                repeats: false
            )

            // Create request
            let request = UNNotificationRequest(
                identifier: notificationId,
                content: content,
                trigger: trigger
            )

            // Schedule notification
            do {
                try await notificationCenter.add(request)
                print("✅ Rest timer notification scheduled for \(Int(duration))s")

                // Verify it was added
                let pending = await notificationCenter.pendingNotificationRequests()
                print("📋 Pending notifications: \(pending.count)")
            } catch {
                print("⚠️ Failed to schedule notification: \(error)")
            }
        }
    }

    /// Cancel pending notification
    private func cancelNotification() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
    }
}
