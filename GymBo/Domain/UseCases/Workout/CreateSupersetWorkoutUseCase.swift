//
//  CreateSupersetWorkoutUseCase.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V6 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for creating a new superset workout template
///
/// **Responsibility:**
/// - Validate workout name and exercise groups
/// - Create new superset workout with exercise groups
/// - Ensure all groups have exactly 2 exercises
/// - Persist to repository
///
/// **Business Rules:**
/// - Name cannot be empty
/// - Must have at least one exercise group
/// - Each group must have exactly 2 exercises (superset pair)
/// - Default rest time: 90 seconds (customizable)
/// - Default rest after group: 120 seconds (customizable)
/// - All exercises in a group must have the same targetSets (rounds)
///
/// **Usage:**
/// ```swift
/// let workout = try await useCase.execute(
///     name: "Upper Body Superset",
///     defaultRestTime: 90,
///     exerciseGroups: [bicepsTricepsGroup, chestBackGroup]
/// )
/// ```
protocol CreateSupersetWorkoutUseCase {
    /// Create a new superset workout template
    /// - Parameters:
    ///   - name: Workout name
    ///   - defaultRestTime: Default rest time between sets in seconds
    ///   - exerciseGroups: Array of exercise groups (superset pairs)
    /// - Returns: The created workout
    /// - Throws: UseCaseError if validation fails or save fails
    func execute(
        name: String,
        defaultRestTime: TimeInterval,
        exerciseGroups: [ExerciseGroup]
    ) async throws -> Workout
}

// MARK: - Implementation

final class DefaultCreateSupersetWorkoutUseCase: CreateSupersetWorkoutUseCase {

    // MARK: - Properties

    private let workoutRepository: WorkoutRepositoryProtocol

    // MARK: - Initialization

    init(workoutRepository: WorkoutRepositoryProtocol) {
        self.workoutRepository = workoutRepository
    }

    // MARK: - Execute

    func execute(
        name: String,
        defaultRestTime: TimeInterval = 90,
        exerciseGroups: [ExerciseGroup]
    ) async throws -> Workout {
        // Validate name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw UseCaseError.invalidInput("Workout name cannot be empty")
        }

        // Validate rest time
        guard defaultRestTime > 0 else {
            throw UseCaseError.invalidInput("Rest time must be greater than 0")
        }

        // Validate exercise groups
        guard !exerciseGroups.isEmpty else {
            throw UseCaseError.invalidInput("Superset workout must have at least one exercise group")
        }

        // Validate each group is a valid superset (exactly 2 exercises)
        for (index, group) in exerciseGroups.enumerated() {
            guard group.exercises.count == 2 else {
                throw UseCaseError.invalidInput(
                    "Group \(index + 1) must have exactly 2 exercises for a superset (found \(group.exercises.count))"
                )
            }

            // Validate all exercises in group have same targetSets (rounds)
            guard group.hasConsistentRounds else {
                throw UseCaseError.invalidInput(
                    "Group \(index + 1): All exercises must have the same number of sets (rounds)")
            }
        }

        // Flatten all exercises from groups for the workout.exercises array
        let allExercises = exerciseGroups.flatMap { $0.exercises }

        // Create workout with groups
        let workout = Workout(
            name: trimmedName,
            exercises: allExercises,
            defaultRestTime: defaultRestTime,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date(),
            isFavorite: false,
            workoutType: .superset,  // V6: Superset type
            exerciseGroups: exerciseGroups  // V6: Exercise groups
        )

        // Save to repository
        do {
            try await workoutRepository.save(workout)
            print(
                "✅ Superset workout created: '\(workout.name)' (id: \(workout.id), \(exerciseGroups.count) groups)"
            )
            return workout
        } catch {
            print("❌ Failed to create superset workout: \(error)")
            throw UseCaseError.saveFailed(error)
        }
    }
}
