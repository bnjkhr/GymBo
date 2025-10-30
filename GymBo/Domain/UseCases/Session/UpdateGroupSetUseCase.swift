//
//  UpdateGroupSetUseCase.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V6 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for updating weight/reps of a set within a grouped workout (superset/circuit)
///
/// **Responsibility:**
/// - Update set values within exercise groups
/// - Works with both superset and circuit training
/// - Validates input values
/// - Updates exercise catalog history
///
/// **Business Rules:**
/// - Can only update sets in active sessions
/// - Can update both completed and incomplete sets
/// - Updates are persisted immediately
/// - Invalid values (weight < 0, reps ≤ 0) are rejected
///
/// **Usage:**
/// ```swift
/// try await useCase.execute(
///     sessionId: sessionId,
///     groupIndex: 0,
///     exerciseId: exerciseId,
///     setId: setId,
///     weight: 105.0,
///     reps: 8
/// )
/// ```
protocol UpdateGroupSetUseCase {
    /// Update weight and/or reps of a specific set within a group
    /// - Parameters:
    ///   - sessionId: ID of the active session
    ///   - groupIndex: Index of the group containing the exercise
    ///   - exerciseId: ID of the exercise containing the set
    ///   - setId: ID of the set to update
    ///   - weight: New weight value (optional, nil = keep current)
    ///   - reps: New reps value (optional, nil = keep current)
    /// - Returns: Updated session
    /// - Throws: UseCaseError if operation fails
    func execute(
        sessionId: UUID,
        groupIndex: Int,
        exerciseId: UUID,
        setId: UUID,
        weight: Double?,
        reps: Int?
    ) async throws -> DomainWorkoutSession
}

// MARK: - Implementation

final class DefaultUpdateGroupSetUseCase: UpdateGroupSetUseCase {

    private let repository: SessionRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol

    init(
        repository: SessionRepositoryProtocol,
        exerciseRepository: ExerciseRepositoryProtocol
    ) {
        self.repository = repository
        self.exerciseRepository = exerciseRepository
    }

    func execute(
        sessionId: UUID,
        groupIndex: Int,
        exerciseId: UUID,
        setId: UUID,
        weight: Double? = nil,
        reps: Int? = nil
    ) async throws -> DomainWorkoutSession {

        // 1. Fetch session
        guard var session = try await repository.fetch(id: sessionId) else {
            throw UseCaseError.sessionNotFound(sessionId)
        }

        // 2. Validate group index
        guard let groups = session.exerciseGroups,
            groupIndex < groups.count
        else {
            throw UseCaseError.invalidInput("Invalid group index: \(groupIndex)")
        }

        // 3. Find exercise in group
        guard
            let exerciseIndex = groups[groupIndex].exercises.firstIndex(where: {
                $0.id == exerciseId
            })
        else {
            throw UseCaseError.exerciseNotFound(exerciseId)
        }

        // 4. Find set in exercise
        guard
            let setIndex = groups[groupIndex].exercises[exerciseIndex].sets.firstIndex(where: {
                $0.id == setId
            })
        else {
            throw UseCaseError.setNotFound(setId)
        }

        // Get the exercise's catalog ID (reference to Exercise catalog)
        let catalogExerciseId = groups[groupIndex].exercises[exerciseIndex].exerciseId

        // 5. Update weight if provided
        if let newWeight = weight {
            guard newWeight >= 0 else {  // Allow 0 for bodyweight exercises
                throw UseCaseError.invalidInput("Weight cannot be negative: \(newWeight)")
            }
            session.exerciseGroups![groupIndex].exercises[exerciseIndex].sets[setIndex].weight =
                newWeight
        }

        // 6. Update reps if provided
        if let newReps = reps {
            guard newReps > 0 else {
                throw UseCaseError.invalidInput("Reps must be greater than 0: \(newReps)")
            }
            session.exerciseGroups![groupIndex].exercises[exerciseIndex].sets[setIndex].reps =
                newReps
        }

        // 7. Persist changes to session
        try await repository.update(session)

        // 8. Update exercise history (lastUsedWeight, lastUsedReps)
        let finalWeight =
            session.exerciseGroups![groupIndex].exercises[exerciseIndex].sets[setIndex].weight
        let finalReps =
            session.exerciseGroups![groupIndex].exercises[exerciseIndex].sets[setIndex].reps

        try? await exerciseRepository.updateLastUsed(
            exerciseId: catalogExerciseId,
            weight: finalWeight,
            reps: finalReps,
            date: Date()
        )

        print(
            "✏️ Updated group set \(setId): weight=\(weight?.description ?? "unchanged"), reps=\(reps?.description ?? "unchanged")"
        )

        return session
    }
}
