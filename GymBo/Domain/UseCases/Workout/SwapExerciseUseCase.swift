//
//  SwapExerciseUseCase.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for swapping an exercise with an alternative in a workout
///
/// **Responsibility:**
/// - Replace an exercise with an alternative exercise
/// - Preserve target values (sets, reps, weight, rest time, notes, order)
/// - Validate that both exercises exist
/// - Persist changes to the workout
///
/// **Business Rules:**
/// - Both old and new exercise must exist
/// - Old exercise must be in the workout
/// - New exercise preserves all settings from old exercise
/// - Order index is maintained
///
/// **Usage:**
/// ```swift
/// let updatedWorkout = try await useCase.execute(
///     workoutId: workoutId,
///     oldExerciseId: oldExerciseId,
///     newExerciseId: newExerciseId
/// )
/// ```
protocol SwapExerciseUseCase {
    func execute(
        workoutId: UUID,
        oldExerciseId: UUID,
        newExerciseId: UUID
    ) async throws -> Workout
}

// MARK: - Implementation

final class DefaultSwapExerciseUseCase: SwapExerciseUseCase {

    // MARK: - Properties

    private let workoutRepository: WorkoutRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol

    // MARK: - Initialization

    init(
        workoutRepository: WorkoutRepositoryProtocol,
        exerciseRepository: ExerciseRepositoryProtocol
    ) {
        self.workoutRepository = workoutRepository
        self.exerciseRepository = exerciseRepository
    }

    // MARK: - Use Case Execution

    func execute(
        workoutId: UUID,
        oldExerciseId: UUID,
        newExerciseId: UUID
    ) async throws -> Workout {
        // Validate that new exercise exists in catalog
        guard let newExercise = try await exerciseRepository.fetch(id: newExerciseId) else {
            throw UseCaseError.exerciseNotFound(newExerciseId)
        }

        // Fetch workout
        guard var workout = try await workoutRepository.fetch(id: workoutId) else {
            throw UseCaseError.workoutNotFound(workoutId)
        }

        // Find old exercise in workout
        guard
            let exerciseIndex = workout.exercises.firstIndex(where: {
                $0.exerciseId == oldExerciseId
            })
        else {
            throw UseCaseError.exerciseNotFound(oldExerciseId)
        }

        // Get the old exercise to preserve its settings
        let oldWorkoutExercise = workout.exercises[exerciseIndex]

        // Create new WorkoutExercise with same settings but new exerciseId
        let newWorkoutExercise = WorkoutExercise(
            id: oldWorkoutExercise.id,  // Keep same ID to maintain references
            exerciseId: newExerciseId,  // New exercise from catalog
            targetSets: oldWorkoutExercise.targetSets,
            targetReps: oldWorkoutExercise.targetReps,
            targetTime: oldWorkoutExercise.targetTime,
            targetWeight: oldWorkoutExercise.targetWeight,
            restTime: oldWorkoutExercise.restTime,
            perSetRestTimes: oldWorkoutExercise.perSetRestTimes,
            orderIndex: oldWorkoutExercise.orderIndex,
            notes: oldWorkoutExercise.notes
        )

        // Replace the exercise
        workout.exercises[exerciseIndex] = newWorkoutExercise

        // Save changes
        workout.updatedAt = Date()
        try await workoutRepository.update(workout)

        print("✅ Swapped exercise in workout \(workoutId)")
        print("   - Old: \(oldExerciseId)")
        print("   - New: \(newExercise.name) (\(newExerciseId))")
        print("   - Preserved: \(oldWorkoutExercise.targetSets) sets")

        return workout
    }
}
