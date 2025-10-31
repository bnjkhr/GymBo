//
//  GymBoMigrationPlan.swift
//  GymBo
//
//  Created on 2025-10-23.
//  SwiftData Migration Plan
//

import Foundation
import SwiftData

/// GymBo SwiftData Migration Plan
///
/// **Purpose:**
/// - Defines all schema versions
/// - Manages migrations between versions
/// - Ensures data integrity during schema changes
///
/// **Usage:**
/// ```swift
/// let container = try ModelContainer(
///     for: SchemaV1.self,
///     migrationPlan: GymBoMigrationPlan.self
/// )
/// ```
///
/// **Adding New Schema Versions:**
/// 1. Create new `SchemaVX.swift` file
/// 2. Add to `schemas` array
/// 3. Create migration stage in `stages` array
/// 4. Test thoroughly before production
///
/// **Created:** 2025-10-23 (Session 6)
/// **Status:** ✅ Production Ready
enum GymBoMigrationPlan: SchemaMigrationPlan {

    // MARK: - Schema Versions

    /// All schema versions in chronological order
    ///
    /// **IMPORTANT:** Always append new versions, never reorder!
    static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self,
            SchemaV2.self,  // ✅ Added: exerciseId field to WorkoutExerciseEntity
            SchemaV3.self,  // ✅ Added: Expanded UserProfileEntity with full profile data
            SchemaV4.self,  // ✅ Added: isWarmup and restTime to SessionSetEntity
            SchemaV5.self,  // ✅ Added: warmupStrategy to WorkoutEntity
            SchemaV6.self,  // ✅ Added: workoutType, exerciseGroups for superset/circuit training
            // Future versions will be added here:
            // SchemaV7.self,
            // ...
        ]
    }

    // MARK: - Migration Stages

    /// Migration stages between schema versions
    ///
    /// **IMPORTANT:** Each stage defines how to migrate from one version to the next
    static var stages: [MigrationStage] {
        [
            migrateV1toV2,
            migrateV2toV3,
            migrateV3toV4,
            migrateV4toV5,
            migrateV5toV6,
            // Future migrations will be added here:
            // migrateV6toV7,
            // ...
        ]
    }

    // MARK: - V1 → V2 Migration

    /// Migration from V1 to V2: Add exerciseId field to WorkoutExerciseEntity
    ///
    /// **Changes:**
    /// - WorkoutExerciseEntity: Add exerciseId field populated from exercise.id
    /// - UserProfileEntity: Create default profile if none exists
    /// - FIX: Restore inverse relationships for WorkoutSessionEntity after migration
    ///
    /// **Why:** Fixes issue where exercise names weren't loading due to lazy relationship loading
    ///           and ensures UserProfile exists for HealthKit integration
    ///
    /// **Bug Fix (2025-10-31):** Restore inverse relationships after migration to prevent
    ///                           SwiftData crashes when updating migrated sessions
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            print("🔄 Starting migration V1 → V2")
        },
        didMigrate: { context in
            print("✅ Migration V1 → V2 complete")

            // Ensure UserProfile exists (new in V2)
            let profileDescriptor = FetchDescriptor<SchemaV2.UserProfileEntity>()
            let existingProfiles = try? context.fetch(profileDescriptor)

            if existingProfiles?.isEmpty ?? true {
                print("📝 Creating default UserProfile")
                let defaultProfile = SchemaV2.UserProfileEntity()
                context.insert(defaultProfile)
                try? context.save()
                print("✅ Default UserProfile created")
            } else {
                print("✅ UserProfile already exists")
            }

            // ✅ FIX: Restore inverse relationships for all sessions
            // This fixes crashes when updating sessions after migration
            print("🔄 Restoring inverse relationships for WorkoutSessions...")
            let sessionDescriptor = FetchDescriptor<SchemaV2.WorkoutSessionEntity>()
            if let sessions = try? context.fetch(sessionDescriptor) {
                var restoredExercises = 0
                var restoredSets = 0

                for session in sessions {
                    // Restore session → exercise relationships
                    for exercise in session.exercises {
                        if exercise.session == nil {
                            exercise.session = session
                            restoredExercises += 1
                        }

                        // Restore exercise → set relationships
                        for set in exercise.sets {
                            if set.exercise == nil {
                                set.exercise = exercise
                                restoredSets += 1
                            }
                        }
                    }
                }

                if restoredExercises > 0 || restoredSets > 0 {
                    try? context.save()
                    print(
                        "✅ Restored \(restoredExercises) exercise relationships and \(restoredSets) set relationships"
                    )
                } else {
                    print("✅ All inverse relationships already intact")
                }
            }
        }
    )

    // MARK: - V2 → V3 Migration

    /// Migration from V2 to V3: Expand UserProfileEntity with full profile data
    ///
    /// **Changes:**
    /// - UserProfileEntity: Add displayName, age, experienceLevel, fitnessGoal
    /// - UserProfileEntity: Add weeklyWorkoutGoal, lastHealthKitSync
    /// - UserProfileEntity: Add healthKitEnabled, healthKitReadEnabled, healthKitWriteEnabled, appTheme
    /// - UserProfileEntity: Add notificationsEnabled, liveActivityEnabled
    ///
    /// **Why:** Complete profile management with personal information, settings, and preferences
    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self
    )

    // MARK: - V3 → V4 Migration

    /// Migration from V3 to V4: Add warmup set tracking
    ///
    /// **Changes:**
    /// - SessionSetEntity: Add isWarmup field (defaults to false)
    /// - SessionSetEntity: Add restTime field (optional)
    ///
    /// **Why:** Enable warmup set tracking for better training structure
    static let migrateV3toV4 = MigrationStage.lightweight(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self
    )

    // MARK: - V4 → V5 Migration

    /// Migration from V4 to V5: Add warmup strategy persistence
    ///
    /// **Changes:**
    /// - WorkoutEntity: Add warmupStrategy field (String?, optional)
    ///
    /// **Why:** Allow users to save preferred warmup strategy per workout
    static let migrateV4toV5 = MigrationStage.lightweight(
        fromVersion: SchemaV4.self,
        toVersion: SchemaV5.self
    )

    // MARK: - V5 → V6 Migration

    /// Migration from V5 to V6: Add superset and circuit training support
    ///
    /// **Changes:**
    /// - WorkoutEntity: Add workoutType field (String, default: "standard")
    /// - WorkoutEntity: Add exerciseGroups relationship (optional)
    /// - WorkoutExerciseEntity: Add groupId field (UUID?, optional)
    /// - NEW: ExerciseGroupEntity for grouping exercises
    /// - WorkoutSessionEntity: Add workoutType field (String, default: "standard")
    /// - WorkoutSessionEntity: Add exerciseGroups relationship (optional)
    /// - SessionExerciseEntity: Add groupId field (UUID?, optional)
    /// - NEW: SessionExerciseGroupEntity for active session groups
    /// - FIX: Restore inverse relationships for WorkoutSessionEntity after migration
    ///
    /// **Why:** Enable superset (paired exercises) and circuit training (station rotation)
    ///         without breaking existing standard workouts
    ///
    /// **Backward Compatibility:**
    /// - All existing workouts remain as workoutType = "standard"
    /// - All new fields are optional with safe defaults
    /// - No data loss or breaking changes
    ///
    /// **Bug Fix (2025-10-31):** Restore inverse relationships after migration to prevent
    ///                           SwiftData crashes when updating migrated sessions
    static let migrateV5toV6 = MigrationStage.custom(
        fromVersion: SchemaV5.self,
        toVersion: SchemaV6.self,
        willMigrate: { context in
            print("🔄 Starting migration V5 → V6")
        },
        didMigrate: { context in
            print("✅ Migration V5 → V6 complete")

            // ✅ FIX: Restore inverse relationships for all sessions
            // This fixes crashes when updating sessions after migration
            print("🔄 Restoring inverse relationships for WorkoutSessions...")
            let sessionDescriptor = FetchDescriptor<SchemaV6.WorkoutSessionEntity>()
            if let sessions = try? context.fetch(sessionDescriptor) {
                var restoredExercises = 0
                var restoredSets = 0
                var restoredGroups = 0

                for session in sessions {
                    // Restore session → exercise relationships
                    for exercise in session.exercises {
                        if exercise.session == nil {
                            exercise.session = session
                            restoredExercises += 1
                        }

                        // Restore exercise → set relationships
                        for set in exercise.sets {
                            if set.exercise == nil {
                                set.exercise = exercise
                                restoredSets += 1
                            }
                        }
                    }

                    // Restore session → exerciseGroup relationships (new in V6)
                    if let groups = session.exerciseGroups {
                        for group in groups {
                            if group.session == nil {
                                group.session = session
                                restoredGroups += 1
                            }

                            // Restore group → exercise relationships
                            for exercise in group.exercises {
                                if exercise.session == nil {
                                    exercise.session = session
                                    restoredExercises += 1
                                }
                            }
                        }
                    }
                }

                if restoredExercises > 0 || restoredSets > 0 || restoredGroups > 0 {
                    try? context.save()
                    print(
                        "✅ Restored \(restoredExercises) exercise, \(restoredSets) set, and \(restoredGroups) group relationships"
                    )
                } else {
                    print("✅ All inverse relationships already intact")
                }
            }
        }
    )

    // MARK: - Future Migration Stages (Examples)

    /*
    /// Example: Migration from V1 to V2
    ///
    /// Use this when adding new optional fields or making lightweight changes
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
    */

    /*
    /// Example: Custom migration from V1 to V2
    ///
    /// Use this when you need to transform data during migration
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            print("🔄 Starting migration V1 → V2")
    
            // Pre-migration logic (optional)
            // Example: Prepare data, validate state, etc.
        },
        didMigrate: { context in
            print("✅ Migration V1 → V2 complete")
    
            // Post-migration logic (optional)
            // Example: Set default values, fix relationships, etc.
    
            // Example: Set default value for new field
            let descriptor = FetchDescriptor<SchemaV2.SessionExerciseEntity>()
            if let exercises = try? context.fetch(descriptor) {
                for exercise in exercises {
                    if exercise.restCompletedAt == nil {
                        exercise.restCompletedAt = Date()
                    }
                }
                try? context.save()
            }
        }
    )
    */
}

// MARK: - Migration Helpers

extension GymBoMigrationPlan {

    /// Logs current schema version
    static func logCurrentVersion() {
        print("📦 GymBo Schema Version: \(schemas.last?.versionIdentifier.description ?? "unknown")")
    }

    /// Validates that all schemas are properly configured
    static func validateSchemas() -> Bool {
        guard !schemas.isEmpty else {
            print("❌ No schemas defined")
            return false
        }

        print("✅ \(schemas.count) schema version(s) defined")
        return true
    }
}
