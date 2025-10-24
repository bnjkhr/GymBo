//
//  CreateWorkoutUseCase.swift
//  GymBo
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for creating a new workout template
///
/// **Responsibility:**
/// - Validate workout name
/// - Create new workout with default values
/// - Persist to repository
///
/// **Business Rules:**
/// - Name cannot be empty
/// - Default rest time: 90 seconds (customizable)
/// - New workouts start with empty exercise list
/// - Workouts are not favorited by default
///
/// **Usage:**
/// ```swift
/// let workout = try await useCase.execute(
///     name: "Push Day",
///     defaultRestTime: 90
/// )
/// ```
protocol CreateWorkoutUseCase {
    /// Create a new workout template
    /// - Parameters:
    ///   - name: Workout name
    ///   - defaultRestTime: Default rest time between sets in seconds
    /// - Returns: The created workout
    /// - Throws: UseCaseError if validation fails or save fails
    func execute(name: String, defaultRestTime: TimeInterval) async throws -> Workout
}

// MARK: - Implementation

final class DefaultCreateWorkoutUseCase: CreateWorkoutUseCase {

    // MARK: - Properties

    private let workoutRepository: WorkoutRepositoryProtocol

    // MARK: - Initialization

    init(workoutRepository: WorkoutRepositoryProtocol) {
        self.workoutRepository = workoutRepository
    }

    // MARK: - Execute

    func execute(name: String, defaultRestTime: TimeInterval = 90) async throws -> Workout {
        // Validate name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw UseCaseError.invalidInput("Workout name cannot be empty")
        }

        // Validate rest time
        guard defaultRestTime > 0 else {
            throw UseCaseError.invalidInput("Rest time must be greater than 0")
        }

        // Create workout
        let workout = Workout(
            name: trimmedName,
            exercises: [],  // Start with no exercises
            defaultRestTime: defaultRestTime,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date(),
            isFavorite: false  // Don't favorite by default
        )

        // Save to repository
        do {
            try await workoutRepository.save(workout)
            print("✅ Workout created: '\(workout.name)' (id: \(workout.id))")
            return workout
        } catch {
            print("❌ Failed to create workout: \(error)")
            throw UseCaseError.saveFailed(error)
        }
    }
}
