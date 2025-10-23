//
//  AddExerciseToWorkoutUseCase.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for adding an exercise to a workout template
///
/// **Responsibility:**
/// - Add new exercise to workout
/// - Set default values (sets, reps, weight)
/// - Update workout's exerciseCount
/// - Maintain proper order
///
/// **Business Rules:**
/// - New exercise added at end (highest orderIndex)
/// - Default: 3 sets, 10 reps, no weight
/// - If exercise has lastUsed values, use those as defaults
protocol AddExerciseToWorkoutUseCase {
    /// Add exercise to workout
    /// - Parameters:
    ///   - exerciseId: ID of exercise from catalog
    ///   - workoutId: ID of workout to add to
    /// - Returns: Updated workout
    /// - Throws: UseCaseError if workout not found or operation fails
    func execute(exerciseId: UUID, workoutId: UUID) async throws -> Workout
}

final class DefaultAddExerciseToWorkoutUseCase: AddExerciseToWorkoutUseCase {

    private let workoutRepository: WorkoutRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol

    init(
        workoutRepository: WorkoutRepositoryProtocol,
        exerciseRepository: ExerciseRepositoryProtocol
    ) {
        self.workoutRepository = workoutRepository
        self.exerciseRepository = exerciseRepository
    }

    func execute(exerciseId: UUID, workoutId: UUID) async throws -> Workout {
        // Fetch workout
        guard var workout = try await workoutRepository.fetch(id: workoutId) else {
            throw UseCaseError.workoutNotFound(workoutId)
        }

        // Fetch exercise for default values
        let exercise = try await exerciseRepository.fetch(id: exerciseId)

        // Calculate next order index
        let nextOrderIndex = workout.exercises.map { $0.orderIndex }.max().map { $0 + 1 } ?? 0

        // Create new workout exercise with smart defaults
        let newExercise = WorkoutExercise(
            exerciseId: exerciseId,
            targetSets: exercise?.lastUsedSetCount ?? 3,
            targetReps: exercise?.lastUsedReps ?? 10,
            targetWeight: exercise?.lastUsedWeight,
            restTime: exercise?.lastUsedRestTime ?? workout.defaultRestTime,
            orderIndex: nextOrderIndex
        )

        // Add to workout
        workout.exercises.append(newExercise)
        workout.updatedAt = Date()

        // Update in repository
        try await workoutRepository.update(workout)

        print("✅ Added exercise to workout: \(workout.name)")
        return workout
    }
}
