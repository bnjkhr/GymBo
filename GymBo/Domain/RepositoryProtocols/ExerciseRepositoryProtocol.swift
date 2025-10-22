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

    /// Update last used values for an exercise
    /// - Parameters:
    ///   - exerciseId: ID of the exercise
    ///   - weight: Last used weight
    ///   - reps: Last used reps
    ///   - date: When it was last used (defaults to now)
    /// - Throws: Repository errors
    func updateLastUsed(
        exerciseId: UUID,
        weight: Double,
        reps: Int,
        date: Date
    ) async throws

    /// Fetch an exercise by ID
    /// - Parameter id: Exercise ID
    /// - Returns: Exercise details or nil if not found
    /// - Throws: Repository errors
    func fetch(id: UUID) async throws -> ExerciseEntity?
}

// MARK: - Mock Implementation for Testing/Previews

#if DEBUG
    final class MockExerciseRepository: ExerciseRepositoryProtocol {
        func updateLastUsed(
            exerciseId: UUID,
            weight: Double,
            reps: Int,
            date: Date
        ) async throws {
            // Mock - do nothing
            print("📝 Mock: Updated exercise \(exerciseId) lastUsed: \(weight)kg x \(reps) reps")
        }

        func fetch(id: UUID) async throws -> ExerciseEntity? {
            // Mock - return nil
            return nil
        }
    }
#endif
