//
//  UpdateWorkoutExerciseUseCase.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for updating exercise details within a workout
///
/// **Responsibility:**
/// - Update target values (sets, reps, weight, rest time, notes) for an exercise in a workout
/// - Validate that the exercise exists in the workout
/// - Persist changes to the workout
///
/// **Business Rules:**
/// - Sets must be >= 1
/// - Reps must be >= 1
/// - Weight must be >= 0 (0 = bodyweight)
/// - Rest time must be >= 0
///
/// **Usage:**
/// ```swift
/// let updatedWorkout = try await useCase.execute(
///     workoutId: workoutId,
///     exerciseId: exerciseId,
///     targetSets: 4,
///     targetReps: 12,
///     targetWeight: 80.0,
///     restTime: 90,
///     notes: "Focus on form"
/// )
/// ```
protocol UpdateWorkoutExerciseUseCase {
    func execute(
        workoutId: UUID,
        exerciseId: UUID,
        targetSets: Int,
        targetReps: Int?,
        targetTime: TimeInterval?,
        targetWeight: Double?,
        restTime: TimeInterval?,
        perSetRestTimes: [TimeInterval]?,
        notes: String?
    ) async throws -> Workout
}

// MARK: - Implementation

final class DefaultUpdateWorkoutExerciseUseCase: UpdateWorkoutExerciseUseCase {

    // MARK: - Properties

    private let workoutRepository: WorkoutRepositoryProtocol

    // MARK: - Initialization

    init(workoutRepository: WorkoutRepositoryProtocol) {
        self.workoutRepository = workoutRepository
    }

    // MARK: - Use Case Execution

    func execute(
        workoutId: UUID,
        exerciseId: UUID,
        targetSets: Int,
        targetReps: Int?,
        targetTime: TimeInterval?,
        targetWeight: Double?,
        restTime: TimeInterval?,
        perSetRestTimes: [TimeInterval]?,
        notes: String?
    ) async throws -> Workout {
        // Validate inputs
        guard targetSets >= 1 else {
            throw UseCaseError.invalidInput("Sets must be at least 1")
        }

        // Must have either reps or time
        guard targetReps != nil || targetTime != nil else {
            throw UseCaseError.invalidInput("Must specify either reps or time")
        }

        // Cannot have both reps and time
        if targetReps != nil && targetTime != nil {
            throw UseCaseError.invalidInput("Cannot specify both reps and time")
        }

        if let reps = targetReps, reps < 1 {
            throw UseCaseError.invalidInput("Reps must be at least 1")
        }
        if let time = targetTime, time < 1 {
            throw UseCaseError.invalidInput("Time must be at least 1 second")
        }
        if let weight = targetWeight, weight < 0 {
            throw UseCaseError.invalidInput("Weight cannot be negative")
        }
        if let rest = restTime, rest < 0 {
            throw UseCaseError.invalidInput("Rest time cannot be negative")
        }

        // Fetch workout
        guard var workout = try await workoutRepository.fetch(id: workoutId) else {
            throw UseCaseError.workoutNotFound(workoutId)
        }

        // Find exercise in workout
        guard let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exerciseId })
        else {
            throw UseCaseError.exerciseNotFound(exerciseId)
        }

        // Update exercise
        workout.exercises[exerciseIndex].targetSets = targetSets
        workout.exercises[exerciseIndex].targetReps = targetReps
        workout.exercises[exerciseIndex].targetTime = targetTime
        workout.exercises[exerciseIndex].targetWeight = targetWeight
        workout.exercises[exerciseIndex].restTime = restTime
        workout.exercises[exerciseIndex].perSetRestTimes = perSetRestTimes
        workout.exercises[exerciseIndex].notes = notes

        // Save changes
        workout.updatedAt = Date()
        try await workoutRepository.update(workout)

        print("✅ Updated exercise \(exerciseId) in workout \(workoutId)")
        if let reps = targetReps {
            print("   - Sets: \(targetSets), Reps: \(reps), Weight: \(targetWeight ?? 0)kg")
        } else if let time = targetTime {
            print("   - Sets: \(targetSets), Time: \(Int(time))s, Weight: \(targetWeight ?? 0)kg")
        }

        return workout
    }
}
