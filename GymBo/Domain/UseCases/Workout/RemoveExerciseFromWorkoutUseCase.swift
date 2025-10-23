//
//  RemoveExerciseFromWorkoutUseCase.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for removing an exercise from a workout template
///
/// **Responsibility:**
/// - Remove exercise by ID from workout
/// - Reorder remaining exercises (update orderIndex)
/// - Update workout's exerciseCount
/// - Persist changes
///
/// **Business Rules:**
/// - After deletion, remaining exercises maintain sequential order (0, 1, 2...)
/// - Cannot remove last exercise if workout would become empty (optional validation)
protocol RemoveExerciseFromWorkoutUseCase {
    /// Remove exercise from workout
    /// - Parameters:
    ///   - exerciseId: ID of WorkoutExercise to remove
    ///   - workoutId: ID of workout to remove from
    /// - Returns: Updated workout
    /// - Throws: UseCaseError if workout not found or operation fails
    func execute(exerciseId: UUID, from workoutId: UUID) async throws -> Workout
}

final class DefaultRemoveExerciseFromWorkoutUseCase: RemoveExerciseFromWorkoutUseCase {

    private let workoutRepository: WorkoutRepositoryProtocol

    init(workoutRepository: WorkoutRepositoryProtocol) {
        self.workoutRepository = workoutRepository
    }

    func execute(exerciseId: UUID, from workoutId: UUID) async throws -> Workout {
        // Fetch workout
        guard var workout = try await workoutRepository.fetch(id: workoutId) else {
            throw UseCaseError.workoutNotFound(workoutId)
        }

        // Remove exercise
        guard let indexToRemove = workout.exercises.firstIndex(where: { $0.id == exerciseId })
        else {
            throw UseCaseError.exerciseNotFound(exerciseId)
        }

        workout.exercises.remove(at: indexToRemove)

        // Reorder remaining exercises (maintain sequential order)
        for (index, _) in workout.exercises.enumerated() {
            workout.exercises[index].orderIndex = index
        }

        // Update metadata
        workout.updatedAt = Date()

        // Persist changes
        try await workoutRepository.update(workout)

        print(
            "✅ Removed exercise from workout: \(workout.name) (now \(workout.exerciseCount) exercises)"
        )
        return workout
    }
}
