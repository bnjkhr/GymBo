//
//  ReorderWorkoutExercisesUseCase.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for reordering exercises in a workout template
///
/// **Responsibility:**
/// - Update exercise order in workout
/// - Maintain sequential orderIndex (0, 1, 2...)
/// - Persist changes
///
/// **Business Rules:**
/// - Exercise order must be sequential starting from 0
/// - All exercise IDs in newOrder must exist in workout
protocol ReorderWorkoutExercisesUseCase {
    /// Reorder exercises in workout
    /// - Parameters:
    ///   - workoutId: ID of workout
    ///   - exerciseIds: Array of exercise IDs in desired new order
    /// - Returns: Updated workout
    /// - Throws: UseCaseError if workout not found or invalid order
    func execute(workoutId: UUID, exerciseIds: [UUID]) async throws -> Workout
}

final class DefaultReorderWorkoutExercisesUseCase: ReorderWorkoutExercisesUseCase {

    private let workoutRepository: WorkoutRepositoryProtocol

    init(workoutRepository: WorkoutRepositoryProtocol) {
        self.workoutRepository = workoutRepository
    }

    func execute(workoutId: UUID, exerciseIds: [UUID]) async throws -> Workout {
        // Fetch workout
        guard var workout = try await workoutRepository.fetch(id: workoutId) else {
            throw UseCaseError.workoutNotFound(workoutId)
        }

        // Validate: all IDs must exist in workout
        let existingIds = Set(workout.exercises.map { $0.id })
        let newOrderIds = Set(exerciseIds)
        guard existingIds == newOrderIds else {
            throw UseCaseError.invalidExerciseOrder
        }

        // Reorder exercises
        var reorderedExercises: [WorkoutExercise] = []
        for (newIndex, exerciseId) in exerciseIds.enumerated() {
            if var exercise = workout.exercises.first(where: { $0.id == exerciseId }) {
                exercise.orderIndex = newIndex
                reorderedExercises.append(exercise)
            }
        }

        workout.exercises = reorderedExercises
        workout.updatedAt = Date()

        // Persist using repository's updateExerciseOrder
        try await workoutRepository.updateExerciseOrder(
            workoutId: workoutId,
            exerciseOrder: exerciseIds
        )

        print("✅ Reordered exercises in workout: \(workout.name)")
        return workout
    }
}
