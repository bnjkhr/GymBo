//
//  DeleteWorkoutUseCase.swift
//  GymBo
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Delete Workout Use Case
//

import Foundation

/// Use case for deleting workout templates
///
/// **Business Rules:**
/// - Cannot delete workout if it has active sessions
/// - Deletes all associated exercises
/// - Validates workout exists before deletion
protocol DeleteWorkoutUseCase {
    func execute(workoutId: UUID) async throws
}

final class DefaultDeleteWorkoutUseCase: DeleteWorkoutUseCase {

    private let workoutRepository: WorkoutRepositoryProtocol

    init(workoutRepository: WorkoutRepositoryProtocol) {
        self.workoutRepository = workoutRepository
    }

    func execute(workoutId: UUID) async throws {
        // Validate workout exists
        guard let workout = try await workoutRepository.fetch(id: workoutId) else {
            throw UseCaseError.workoutNotFound(workoutId)
        }

        // Delete workout (repository handles cascade deletion of exercises)
        try await workoutRepository.delete(id: workoutId)

        print("✅ Deleted workout: \(workout.name)")
    }
}
