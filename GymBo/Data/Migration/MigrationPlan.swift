//
//  MigrationPlan.swift
//  GymBo
//
//  Created on 2025-10-23.
//  SwiftData Migration Plan
//

import Foundation
import SwiftData

/// Migration Plan for GymBo SwiftData Schema
///
/// **Purpose:**
/// - Define all schema versions
/// - Specify migration stages between versions
/// - Handle data transformation during migrations
///
/// **Migration History:**
/// - V1 (1.0.0): Initial production schema
/// - V2 (2.0.0): Add exerciseId to WorkoutExerciseEntity
///
/// **Usage:**
/// ```swift
/// let container = try ModelContainer(
///     for: schema,
///     migrationPlan: GymBoMigrationPlan.self
/// )
/// ```
enum GymBoMigrationPlan: SchemaMigrationPlan {

    /// All schema versions in order
    static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self,
            SchemaV2.self,
        ]
    }

    /// Migration stages between versions
    static var stages: [MigrationStage] {
        [
            migrateV1toV2
        ]
    }

    // MARK: - V1 → V2: Add exerciseId to WorkoutExerciseEntity

    /// Migration from V1 to V2
    ///
    /// **Changes:**
    /// - WorkoutExerciseEntity: Add exerciseId field populated from exercise.id
    ///
    /// **Strategy:**
    /// - Lightweight migration with willMigrate to populate exerciseId
    /// - For existing WorkoutExerciseEntity, copy exercise.id to exerciseId
    /// - If exercise is nil, use a placeholder UUID (these will be cleaned up)
    static var migrateV1toV2: MigrationStage {
        MigrationStage.lightweight(
            fromVersion: SchemaV1.self,
            toVersion: SchemaV2.self
        ) { context in
            print("🔄 Starting migration V1 → V2: Adding exerciseId field...")

            // Fetch all WorkoutExerciseEntity instances
            let descriptor = FetchDescriptor<SchemaV2.WorkoutExerciseEntity>()
            guard let workoutExercises = try? context.fetch(descriptor) else {
                print("❌ Failed to fetch workout exercises for migration")
                return
            }

            print("📊 Found \(workoutExercises.count) workout exercises to migrate")

            var migratedCount = 0
            var missingExerciseCount = 0

            for workoutExercise in workoutExercises {
                // If exercise relationship exists, copy its ID to exerciseId
                if let exercise = workoutExercise.exercise {
                    workoutExercise.exerciseId = exercise.id
                    migratedCount += 1
                } else {
                    // Exercise relationship is nil - use placeholder
                    // These should be cleaned up by the app on next launch
                    print(
                        "⚠️ WorkoutExercise \(workoutExercise.id) has no exercise - using placeholder"
                    )
                    workoutExercise.exerciseId = UUID()  // Placeholder, will be cleaned
                    missingExerciseCount += 1
                }
            }

            print("✅ Migration V1 → V2 complete:")
            print("   - Migrated: \(migratedCount) exercises")
            print("   - Missing exercise: \(missingExerciseCount) (will be cleaned up)")
        }
    }
}
