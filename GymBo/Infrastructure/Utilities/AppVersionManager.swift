//
//  AppVersionManager.swift
//  GymBo
//
//  Created on 2025-10-27.
//  Version tracking and migration management
//

import Foundation

/// Manages app version tracking and migration state
///
/// **Purpose:**
/// - Detect first launch of v2.4.0
/// - Track if database migration has been performed
/// - Determine if user is upgrading from v1.0
///
/// **Usage:**
/// ```swift
/// if AppVersionManager.shared.needsDatabaseReset() {
///     // Show migration alert
///     // Delete old database
///     // Create fresh v2 database
/// }
/// ```
final class AppVersionManager {

    static let shared = AppVersionManager()

    private let userDefaults = UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let lastAppVersion = "lastAppVersion"
        static let hasPerformedV2Migration = "hasPerformedV2Migration"
        static let isFirstLaunch = "isFirstLaunch"
        static let build15CleanupDone = "build15CleanupDone"  // Force fresh DB for all users
    }

    // MARK: - Current Version

    /// Current app version from Info.plist
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.4.0"
    }

    /// Current build number from Info.plist
    var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Version Tracking

    /// Last recorded app version (nil if first launch ever)
    private(set) var lastVersion: String? {
        get { userDefaults.string(forKey: Keys.lastAppVersion) }
        set { userDefaults.set(newValue, forKey: Keys.lastAppVersion) }
    }

    /// Whether v2 migration has been performed
    private(set) var hasPerformedV2Migration: Bool {
        get { userDefaults.bool(forKey: Keys.hasPerformedV2Migration) }
        set { userDefaults.set(newValue, forKey: Keys.hasPerformedV2Migration) }
    }

    /// Whether this is the very first launch
    private(set) var isFirstLaunch: Bool {
        get {
            // If key doesn't exist, it's first launch
            if userDefaults.object(forKey: Keys.isFirstLaunch) == nil {
                return true
            }
            return userDefaults.bool(forKey: Keys.isFirstLaunch)
        }
        set { userDefaults.set(newValue, forKey: Keys.isFirstLaunch) }
    }

    /// Whether Build 15 cleanup has been performed
    var build15CleanupDone: Bool {
        get { userDefaults.bool(forKey: Keys.build15CleanupDone) }
        set { userDefaults.set(newValue, forKey: Keys.build15CleanupDone) }
    }

    // MARK: - Migration Detection

    /// Check if database needs to be reset (upgrading from v1.0 to v2.4.0)
    ///
    /// **Returns true if:**
    /// - User has v1.x installed (lastVersion starts with "1.")
    /// - AND v2 migration has NOT been performed yet
    ///
    /// **Returns false if:**
    /// - Fresh install (no lastVersion)
    /// - Already on v2.x
    /// - Migration already performed
    func needsDatabaseReset() -> Bool {
        // Fresh install - no reset needed
        guard let last = lastVersion else {
            print("📱 Fresh install detected - no database reset needed")
            return false
        }

        // Already performed v2 migration - no reset needed
        if hasPerformedV2Migration {
            print("✅ V2 migration already performed - no database reset needed")
            return false
        }

        // Check if upgrading from v1.x
        let isUpgradingFromV1 = last.starts(with: "1.")

        if isUpgradingFromV1 {
            print("⚠️ Upgrading from v\(last) to v\(currentVersion) - database reset required")
            return true
        }

        print("✅ Already on v2.x (\(last)) - no database reset needed")
        return false
    }

    /// Mark that v2 migration has been completed
    func markV2MigrationComplete() {
        hasPerformedV2Migration = true
        lastVersion = currentVersion
        isFirstLaunch = false
        userDefaults.synchronize()
        print("✅ V2 migration marked as complete - version \(currentVersion)")
    }

    /// Update stored version (call on every app launch after migration check)
    func updateStoredVersion() {
        let previous = lastVersion
        lastVersion = currentVersion
        isFirstLaunch = false
        userDefaults.synchronize()

        if let prev = previous {
            print("📱 App version updated: \(prev) → \(currentVersion)")
        } else {
            print("📱 App version stored: \(currentVersion) (first launch)")
        }
    }

    // MARK: - Debug Helpers

    /// Reset all version tracking (for testing)
    func resetVersionTracking() {
        userDefaults.removeObject(forKey: Keys.lastAppVersion)
        userDefaults.removeObject(forKey: Keys.hasPerformedV2Migration)
        userDefaults.removeObject(forKey: Keys.isFirstLaunch)
        userDefaults.synchronize()
        print("🔄 Version tracking reset")
    }

    /// Print current version state (for debugging)
    func printVersionInfo() {
        print(
            """

            📱 App Version Info:
            -------------------
            Current Version: \(currentVersion) (\(currentBuild))
            Last Version: \(lastVersion ?? "none")
            First Launch: \(isFirstLaunch)
            V2 Migration Done: \(hasPerformedV2Migration)
            Build 15 Cleanup Done: \(build15CleanupDone)
            Needs DB Reset: \(needsDatabaseReset())

            """)
    }
}
