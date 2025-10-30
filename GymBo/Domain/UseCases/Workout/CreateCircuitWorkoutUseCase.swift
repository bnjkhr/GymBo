//
//  CreateCircuitWorkoutUseCase.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V6 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for creating a new circuit training workout template
///
/// **Responsibility:**
/// - Validate workout name and exercise groups
/// - Create new circuit workout with exercise groups
/// - Ensure all groups have 3+ exercises (station rotation)
/// - Persist to repository
///
/// **Business Rules:**
/// - Name cannot be empty
/// - Must have at least one exercise group
/// - Each group must have 3+ exercises (circuit stations)
/// - Default rest time: 30 seconds (shorter for circuits)
/// - Default rest after circuit: 180 seconds (3 minutes)
/// - All exercises in a group must have the same targetSets (rounds)
///
/// **Usage:**
/// ```swift
/// let workout = try await useCase.execute(
///     name: "Full Body Circuit",
///     defaultRestTime: 30,
///     exerciseGroups: [fullBodyCircuitGroup]
/// )
/// ```
protocol CreateCircuitWorkoutUseCase {
    /// Create a new circuit training workout template
    /// - Parameters:
    ///   - name: Workout name
    ///   - defaultRestTime: Default rest time between stations in seconds
    ///   - exerciseGroups: Array of exercise groups (circuit stations)
    /// - Returns: The created workout
    /// - Throws: UseCaseError if validation fails or save fails
    func execute(
        name: String,
        defaultRestTime: TimeInterval,
        exerciseGroups: [ExerciseGroup]
    ) async throws -> Workout
}

// MARK: - Implementation

final class DefaultCreateCircuitWorkoutUseCase: CreateCircuitWorkoutUseCase {

    // MARK: - Properties

    private let workoutRepository: WorkoutRepositoryProtocol

    // MARK: - Initialization

    init(workoutRepository: WorkoutRepositoryProtocol) {
        self.workoutRepository = workoutRepository
    }

    // MARK: - Execute

    func execute(
        name: String,
        defaultRestTime: TimeInterval = 30,
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
            throw UseCaseError.invalidInput(
                "Circuit workout must have at least one exercise group")
        }

        // Validate each group is a valid circuit (3+ exercises)
        for (index, group) in exerciseGroups.enumerated() {
            guard group.exercises.count >= 3 else {
                throw UseCaseError.invalidInput(
                    "Group \(index + 1) must have at least 3 exercises for a circuit (found \(group.exercises.count))"
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
            workoutType: .circuit,  // V6: Circuit type
            exerciseGroups: exerciseGroups  // V6: Exercise groups
        )

        // Save to repository
        do {
            try await workoutRepository.save(workout)
            print(
                "✅ Circuit workout created: '\(workout.name)' (id: \(workout.id), \(allExercises.count) stations, \(exerciseGroups.first?.rounds ?? 0) rounds)"
            )
            return workout
        } catch {
            print("❌ Failed to create circuit workout: \(error)")
            throw UseCaseError.saveFailed(error)
        }
    }
}
