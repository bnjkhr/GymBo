//
//  ExerciseRepositoryProtocol.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Repository protocol for exercise operations
///
/// **Responsibility:**
/// - Fetch exercises from catalog
/// - Update last used values (weight, reps, date)
/// - Maintain exercise history for UX improvements
///
/// **Implementation:**
/// SwiftDataExerciseRepository (in Data Layer)
protocol ExerciseRepositoryProtocol {

    /// Fetch exercise by ID
    /// - Parameter id: Exercise ID
    /// - Returns: Exercise entity or nil if not found
    /// - Throws: Repository errors
    nonisolated func fetch(id: UUID) async throws -> ExerciseEntity?

    /// Update last used values for an exercise
    /// - Parameters:
    ///   - exerciseId: ID of the exercise
    ///   - weight: Last used weight
    ///   - reps: Last used reps
    ///   - date: When it was last used (defaults to now)
    /// - Throws: Repository errors
    nonisolated func updateLastUsed(
        exerciseId: UUID,
        weight: Double,
        reps: Int,
        date: Date
    ) async throws

    /// Find exercise by name (for test data)
    /// - Parameter name: Exercise name
    /// - Returns: Exercise ID or nil if not found
    nonisolated func findByName(_ name: String) async throws -> UUID?

    /// Fetch all exercises from catalog
    /// - Returns: Array of all exercises
    /// - Throws: Repository errors
    nonisolated func fetchAll() async throws -> [ExerciseEntity]
}

// MARK: - Mock Implementation for Testing/Previews

#if DEBUG
    final class MockExerciseRepository: ExerciseRepositoryProtocol {
        func fetch(id: UUID) async throws -> ExerciseEntity? {
            // Mock - return basic exercise
            return ExerciseEntity(
                id: id,
                name: "Mock Exercise",
                muscleGroupsRaw: ["chest"],
                equipmentTypeRaw: "barbell"
            )
        }

        func updateLastUsed(
            exerciseId: UUID,
            weight: Double,
            reps: Int,
            date: Date
        ) async throws {
            // Mock - do nothing
            print("📝 Mock: Updated exercise \(exerciseId) lastUsed: \(weight)kg x \(reps) reps")
        }

        func findByName(_ name: String) async throws -> UUID? {
            // Mock - return random UUID
            return UUID()
        }

        func fetchAll() async throws -> [ExerciseEntity] {
            // Mock - return sample exercises
            return [
                ExerciseEntity(
                    name: "Bankdrücken", muscleGroupsRaw: ["Brust"], equipmentTypeRaw: "Langhantel"),
                ExerciseEntity(
                    name: "Kniebeugen", muscleGroupsRaw: ["Beine"], equipmentTypeRaw: "Langhantel"),
                ExerciseEntity(
                    name: "Kreuzheben", muscleGroupsRaw: ["Rücken"], equipmentTypeRaw: "Langhantel"),
            ]
        }
    }
#endif
