//
//  GymBoApp.swift
//  GymBo
//
//  Created on 2025-10-22.
//  V2 Clean Architecture - App Entry Point
//

import Foundation
import SwiftData
import SwiftUI
import UserNotifications

// NOTE: AppDelegate removed - cleanup happens in init() before ModelContainer creation

/// GymBo V2.0 - Clean Architecture App Entry Point
///
/// **Architecture:**
/// - Pure V2 implementation (V1 archived)
/// - Clean Architecture: Domain → Data → Presentation → Infrastructure
/// - Dependency Injection via DependencyContainer
/// - SwiftData for persistence
///
/// **What's Different from V1:**
/// - No V1 models, services, coordinators
/// - SessionStore instead of WorkoutStore
/// - Clean layer separation
/// - 100% testable business logic
@main
struct GymBoApp: App {

    // MARK: - Properties

    /// SwiftData container with V4 entities only
    let container: ModelContainer

    /// Dependency injection container
    let dependencyContainer: DependencyContainer

    /// Shared session store (initialized in init)
    private let sessionStore: SessionStore

    /// App-wide settings (theme, etc.)
    @State private var appSettings: AppSettings

    /// Migration state
    @State private var showMigrationAlert = false
    @State private var migrationCompleted = false

    // MARK: - Initialization

    init() {
        // 🔥 CRITICAL: Delete database BEFORE ModelContainer creation if V1 upgrade
        NSLog("🔵 INIT START")
        let versionManager = AppVersionManager.shared
        versionManager.printVersionInfo()

        NSLog("🔵 build9CleanupDone = \(versionManager.build9CleanupDone)")

        // Build 9: Use NEW flag because builds 5-8 all had issues
        if !versionManager.build9CleanupDone {
            NSLog("🔥 BUILD 9 INIT: Deleting database BEFORE ModelContainer creation")
            GymBoApp.deleteDatabase()
            NSLog("✅ BUILD 9 INIT: Database deleted")
            versionManager.build9CleanupDone = true
            versionManager.markV2MigrationComplete()
            _showMigrationAlert = State(initialValue: true)
        } else {
            NSLog("✅ BUILD 9: Database already cleaned up previously")
        }

        // Show migration alert if cleanup was just performed
        if versionManager.build6CleanupDone && versionManager.hasPerformedV2Migration {
            _showMigrationAlert = State(initialValue: true)
        }

        // ✅ Production-Ready: ModelContainer with V6 schema and migration plan
        // Migrates: V1 → V2 (exerciseId) → V3 (expanded UserProfile) → V4 (warmup sets) → V5 (warmup strategy) → V6 (superset/circuit)

        // 🔧 DEVELOPMENT MODE: Database deletion DISABLED to test persistence
        // Previously deleted DB on every start - now commented out to allow testing
        #if DEBUG
            // DISABLED: Database deletion to allow note persistence testing
            // let fileManager = FileManager.default
            // if let storeURL = fileManager.urls(
            //     for: .applicationSupportDirectory, in: .userDomainMask
            // )
            // .first?
            // .appendingPathComponent("default.store") {
            //     AppLogger.app.warning("🔧 DEBUG: Deleting existing database for fresh start...")
            //     try? fileManager.removeItem(at: storeURL)
            //     try? fileManager.removeItem(
            //         at: storeURL.deletingPathExtension().appendingPathExtension("store-shm"))
            //     try? fileManager.removeItem(
            //         at: storeURL.deletingPathExtension().appendingPathExtension("store-wal"))
            // }

            // Use non-versioned schema (direct entities) to avoid type casting issues
            let schema = Schema([
                WorkoutSessionEntity.self,
                SessionExerciseEntity.self,
                SessionSetEntity.self,
                SessionExerciseGroupEntity.self,  // V6: Superset/Circuit groups
                ExerciseEntity.self,
                ExerciseSetEntity.self,
                WorkoutExerciseEntity.self,
                ExerciseGroupEntity.self,  // V6: Exercise groups
                WorkoutEntity.self,
                UserProfileEntity.self,
                ExerciseRecordEntity.self,
                WorkoutFolderEntity.self,
            ])

            do {
                container = try ModelContainer(for: schema)
                AppLogger.app.info("✅ SwiftData container created (DEBUG mode)")
            } catch {
                // If container creation fails, delete old database and try again
                AppLogger.app.error("❌ Failed to create ModelContainer: \(error)")
                AppLogger.app.warning("🔧 Deleting old database and retrying...")

                let fileManager = FileManager.default
                if let storeURL = fileManager.urls(
                    for: .applicationSupportDirectory, in: .userDomainMask
                )
                .first?
                .appendingPathComponent("default.store") {
                    try? fileManager.removeItem(at: storeURL)
                    try? fileManager.removeItem(
                        at: storeURL.deletingPathExtension().appendingPathExtension("store-shm"))
                    try? fileManager.removeItem(
                        at: storeURL.deletingPathExtension().appendingPathExtension("store-wal"))
                    AppLogger.app.info("🗑️ Old database deleted")
                }

                // Retry container creation
                container = try! ModelContainer(for: schema)
                AppLogger.app.info("✅ SwiftData container created after cleanup")
            }

        #else
            // PRODUCTION: Use versioned schema with migration plan
            let schema = Schema(versionedSchema: SchemaV6.self)

            do {
                container = try ModelContainer(
                    for: schema,
                    migrationPlan: GymBoMigrationPlan.self
                )
                AppLogger.app.info("✅ SwiftData container created with V6 schema")
            } catch {
                // If container creation fails, delete old database and try again
                AppLogger.app.error("❌ Failed to create ModelContainer: \(error)")
                AppLogger.app.warning("🔧 Deleting old database and retrying...")

                let fileManager = FileManager.default
                if let storeURL = fileManager.urls(
                    for: .applicationSupportDirectory, in: .userDomainMask
                )
                .first?
                .appendingPathComponent("default.store") {
                    try? fileManager.removeItem(at: storeURL)
                    try? fileManager.removeItem(
                        at: storeURL.deletingPathExtension().appendingPathExtension("store-shm"))
                    try? fileManager.removeItem(
                        at: storeURL.deletingPathExtension().appendingPathExtension("store-wal"))
                    AppLogger.app.info("🗑️ Old database deleted")
                }

                // Retry container creation
                container = try! ModelContainer(
                    for: schema,
                    migrationPlan: GymBoMigrationPlan.self
                )
                AppLogger.app.info("✅ SwiftData container created after cleanup")
            }
        #endif

        // Initialize dependency injection
        dependencyContainer = DependencyContainer(
            modelContext: container.mainContext
        )

        // Initialize session store (must be after dependencyContainer)
        sessionStore = dependencyContainer.makeSessionStore()

        // Initialize app settings
        _appSettings = State(
            initialValue: AppSettings(
                userProfileRepository: dependencyContainer.makeUserProfileRepository(),
                featureFlagService: dependencyContainer.makeFeatureFlagService()
            ))

        AppLogger.app.info("🚀 GymBo V2.0 initialized")
    }

    // MARK: - App Scene

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .modelContainer(container)
                    .environment(sessionStore)
                    .environment(appSettings)
                    .environment(\.dependencyContainer, dependencyContainer)
                    .preferredColorScheme(appSettings.colorScheme)
                    .task {
                        await performStartupTasks()
                    }

                // Migration alert overlay
                if showMigrationAlert {
                    MigrationAlertView {
                        // User confirmed - mark migration complete and dismiss
                        showMigrationAlert = false
                        migrationCompleted = true
                        AppVersionManager.shared.markV2MigrationComplete()
                        AppLogger.app.info("✅ User confirmed v2.4.0 migration")
                    }
                    .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Startup Tasks

    @MainActor
    private func performStartupTasks() async {
        AppLogger.app.info("✅ App gestartet")

        // Register notification delegate for foreground notifications
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        print("📬 Notification delegate registered")

        // Seed test exercises if database is empty
        ExerciseSeedData.seedIfNeeded(context: container.mainContext)

        // Seed sample workouts if database is empty
        WorkoutSeedData.seedIfNeeded(context: container.mainContext)

        print("🔵 performStartupTasks: About to load session")

        // Load any active session from previous app run
        await sessionStore.loadActiveSession()

        print("🔵 performStartupTasks: After loadActiveSession")
        print("   - hasActiveSession: \(sessionStore.hasActiveSession)")
        print("   - currentSession: \(sessionStore.currentSession?.id.uuidString ?? "nil")")

        if sessionStore.hasActiveSession {
            AppLogger.app.info("🔄 Aktive Session gefunden - wird wiederhergestellt")
        } else {
            print("⚠️ performStartupTasks: No active session found")
        }

        // Update version after startup (for next launch)
        if migrationCompleted || !showMigrationAlert {
            AppVersionManager.shared.updateStoredVersion()
        }
    }

    // MARK: - Database Management

    /// Delete the entire SwiftData database
    ///
    /// **Use cases:**
    /// - v1.0 → v2.4.0 migration (clean slate)
    /// - Unrecoverable migration errors
    ///
    /// **Warning:** This deletes ALL user data!
    static func deleteDatabase() {
        let fileManager = FileManager.default

        // Try MULTIPLE possible locations where SwiftData might store the database
        let possibleLocations = [
            // Location 1: Application Support (what we've been using)
            fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("default.store"),
            // Location 2: Documents directory
            fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?
                .appendingPathComponent("default.store"),
            // Location 3: Library directory
            fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first?
                .appendingPathComponent("default.store"),
            // Location 4: Caches directory
            fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
                .appendingPathComponent("default.store"),
        ]

        var deletedAny = false

        for (index, storeURL) in possibleLocations.enumerated() {
            guard let url = storeURL else { continue }

            NSLog("🔍 Checking location \(index + 1): \(url.path)")

            if fileManager.fileExists(atPath: url.path) {
                NSLog("✅ FOUND database at location \(index + 1): \(url.path)")

                // Delete main store file
                try? fileManager.removeItem(at: url)

                // Delete Write-Ahead Logging files
                try? fileManager.removeItem(
                    at: url.deletingPathExtension().appendingPathExtension("store-shm")
                )
                try? fileManager.removeItem(
                    at: url.deletingPathExtension().appendingPathExtension("store-wal")
                )

                NSLog("🗑️ Deleted database at location \(index + 1)")
                deletedAny = true
            } else {
                NSLog("❌ No database at location \(index + 1)")
            }
        }

        if deletedAny {
            NSLog("✅ Database deletion completed - deleted from at least one location")
        } else {
            NSLog("⚠️ No database found in ANY of the checked locations!")
        }
    }
}
