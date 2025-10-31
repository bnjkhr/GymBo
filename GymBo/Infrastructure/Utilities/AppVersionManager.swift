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
        static let build5CleanupDone = "build5CleanupDone"  // Build 5 (failed)
        static let build6CleanupDone = "build6CleanupDone"  // Build 6-8 (failed)
        static let build9CleanupDone = "build9CleanupDone"  // ⚠️ EMERGENCY: Track if build 9 cleanup was done
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

    /// ⚠️ EMERGENCY: Whether build 5 cleanup has been performed
    /// This ensures all users get a clean database on their first launch of build 5
    /// Uses static initializer to run BEFORE ModelContainer creation
    var build5CleanupDone: Bool {
        get { userDefaults.bool(forKey: Keys.build5CleanupDone) }
        set { userDefaults.set(newValue, forKey: Keys.build5CleanupDone) }
    }

    /// ⚠️ EMERGENCY: Whether build 6 cleanup has been performed
    /// Build 5 failed - it set the flag but crashed before deleting DB
    /// Build 6 uses a NEW flag to force cleanup
    var build6CleanupDone: Bool {
        get { userDefaults.bool(forKey: Keys.build6CleanupDone) }
        set { userDefaults.set(newValue, forKey: Keys.build6CleanupDone) }
    }

    /// ⚠️ EMERGENCY: Whether build 9 cleanup has been performed
    /// Builds 5-8 all failed for various reasons
    /// Build 9 uses ANOTHER new flag to ensure cleanup
    var build9CleanupDone: Bool {
        get { userDefaults.bool(forKey: Keys.build9CleanupDone) }
        set { userDefaults.set(newValue, forKey: Keys.build9CleanupDone) }
    }

    // MARK: - Migration Detection

    /// Check if database needs to be reset (upgrading from v1.0 to v2.4.0)
    ///
    /// **Returns true if:**
    /// - User has v1.x installed (lastVersion starts with "1.")
    /// - OR database exists but v2 migration has NOT been performed yet (V1 didn't track version)
    /// - AND v2 migration has NOT been performed yet
    ///
    /// **Returns false if:**
    /// - Fresh install (no lastVersion AND no database file)
    /// - Already on v2.x
    /// - Migration already performed
    func needsDatabaseReset() -> Bool {
        // Already performed v2 migration - no reset needed
        if hasPerformedV2Migration {
            print("✅ V2 migration already performed - no database reset needed")
            return false
        }

        // Check if database file exists
        let databaseExists = checkDatabaseExists()

        // Check lastVersion
        if let last = lastVersion {
            // Version tracked - check if upgrading from v1.x
            let isUpgradingFromV1 = last.starts(with: "1.")

            if isUpgradingFromV1 {
                print("⚠️ Upgrading from v\(last) to v\(currentVersion) - database reset required")
                return true
            }

            print("✅ Already on v2.x (\(last)) - no database reset needed")
            return false
        } else if databaseExists {
            // No version tracked BUT database exists - must be V1!
            // V1 never set the lastVersion key, so this is a V1 → V2 upgrade
            print(
                "⚠️ Database exists but no version tracked - V1 detected - database reset required")
            return true
        } else {
            // No version AND no database - fresh install
            print("📱 Fresh install detected - no database reset needed")
            return false
        }
    }

    /// Check if SwiftData database file exists
    private func checkDatabaseExists() -> Bool {
        let fileManager = FileManager.default
        guard
            let storeURL = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first?.appendingPathComponent("default.store")
        else {
            return false
        }

        let exists = fileManager.fileExists(atPath: storeURL.path)
        if exists {
            print("📦 Database file found at: \(storeURL.path)")
        }
        return exists
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
            Needs DB Reset: \(needsDatabaseReset())

            """)
    }
}
