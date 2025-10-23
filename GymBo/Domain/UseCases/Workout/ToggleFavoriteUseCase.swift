//
//  ToggleFavoriteUseCase.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use Case for toggling workout favorite status
///
/// **Responsibility:**
/// - Toggle isFavorite flag on workout
/// - Update workout in repository
///
/// **Business Rules:**
/// - Workout must exist
/// - Only toggles flag, doesn't change other data
protocol ToggleFavoriteUseCase {
    /// Toggle favorite status of a workout
    /// - Parameter workoutId: ID of the workout to toggle
    /// - Returns: Updated workout with toggled favorite status
    /// - Throws: UseCaseError if workout not found or update fails
    func execute(workoutId: UUID) async throws -> Workout
}

// MARK: - Implementation

final class DefaultToggleFavoriteUseCase: ToggleFavoriteUseCase {

    private let repository: WorkoutRepositoryProtocol

    init(repository: WorkoutRepositoryProtocol) {
        self.repository = repository
    }

    func execute(workoutId: UUID) async throws -> Workout {
        // Fetch workout
        guard var workout = try await repository.fetch(id: workoutId) else {
            throw UseCaseError.workoutNotFound(workoutId)
        }

        // Toggle favorite
        workout.isFavorite.toggle()
        workout.updatedAt = Date()

        // Update in repository
        try await repository.update(workout)

        return workout
    }
}
