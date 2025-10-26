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

    /// SwiftData container with V2 entities only
    let container: ModelContainer

    /// Dependency injection container
    let dependencyContainer: DependencyContainer

    /// Shared session store (initialized in init)
    private let sessionStore: SessionStore

    // MARK: - Initialization

    init() {
        // ✅ Production-Ready: ModelContainer with V2 schema and migration plan
        // Migrates from V1 (no exerciseId) → V2 (with exerciseId in WorkoutExerciseEntity)

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
                ExerciseEntity.self,
                ExerciseSetEntity.self,
                WorkoutExerciseEntity.self,
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
            let schema = Schema(versionedSchema: SchemaV2.self)

            do {
                container = try ModelContainer(
                    for: schema,
                    migrationPlan: GymBoMigrationPlan.self
                )
                AppLogger.app.info("✅ SwiftData container created with V2 schema")
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

        AppLogger.app.info("🚀 GymBo V2.0 initialized")
    }

    // MARK: - App Scene

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(container)
                .environment(sessionStore)
                .environment(\.dependencyContainer, dependencyContainer)
                .task {
                    await performStartupTasks()
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
    }
}
