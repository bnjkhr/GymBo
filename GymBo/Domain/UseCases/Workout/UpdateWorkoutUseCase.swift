//
//  UpdateWorkoutUseCase.swift
//  GymBo
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Update Workout Use Case
//

import Foundation

/// Use case for updating workout template metadata
///
/// **Business Rules:**
/// - Name cannot be empty
/// - Rest time must be positive
/// - Updates workout name and/or default rest time
protocol UpdateWorkoutUseCase {
    func execute(workoutId: UUID, name: String?, defaultRestTime: TimeInterval?) async throws
        -> Workout
}

final class DefaultUpdateWorkoutUseCase: UpdateWorkoutUseCase {

    private let workoutRepository: WorkoutRepositoryProtocol

    init(workoutRepository: WorkoutRepositoryProtocol) {
        self.workoutRepository = workoutRepository
    }

    func execute(workoutId: UUID, name: String?, defaultRestTime: TimeInterval?) async throws
        -> Workout
    {
        // Fetch existing workout
        guard var workout = try await workoutRepository.fetch(id: workoutId) else {
            throw UseCaseError.workoutNotFound(workoutId)
        }

        // Update name if provided
        if let newName = name {
            let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                throw UseCaseError.invalidInput("Workout name cannot be empty")
            }
            workout.name = trimmedName
        }

        // Update rest time if provided
        if let newRestTime = defaultRestTime {
            guard newRestTime > 0 else {
                throw UseCaseError.invalidInput("Rest time must be greater than 0")
            }
            workout.defaultRestTime = newRestTime
        }

        // Update timestamp
        workout.updatedAt = Date()

        // Save changes
        try await workoutRepository.update(workout)

        print("✅ Updated workout: \(workout.name)")
        return workout
    }
}
