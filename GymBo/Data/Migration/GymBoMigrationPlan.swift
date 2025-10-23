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
            SchemaV1.self
            // Future versions will be added here:
            // SchemaV2.self,
            // SchemaV3.self,
            // ...
        ]
    }

    // MARK: - Migration Stages

    /// Migration stages between schema versions
    ///
    /// **IMPORTANT:** Each stage defines how to migrate from one version to the next
    static var stages: [MigrationStage] {
        [
            // No migrations yet - SchemaV1 is the baseline
            // Future migrations will be added here:
            // migrateV1toV2,
            // migrateV2toV3,
            // ...
        ]
    }

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
