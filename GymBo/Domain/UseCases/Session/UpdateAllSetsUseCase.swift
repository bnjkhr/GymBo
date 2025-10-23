//
//  UpdateAllSetsUseCase.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for updating weight/reps of ALL sets in an exercise at once
///
/// **Business Rules:**
/// - Can only update sets in active sessions
/// - Updates all incomplete sets with the same weight/reps values
/// - Updates are persisted immediately
/// - Invalid values (weight ≤ 0, reps ≤ 0) are rejected
///
/// **Usage:**
/// ```swift
/// let useCase = UpdateAllSetsUseCase(repository: sessionRepository)
/// let updatedSession = try await useCase.execute(
///     sessionId: sessionId,
///     exerciseId: exerciseId,
///     weight: 105.0,
///     reps: 8
/// )
/// ```
protocol UpdateAllSetsUseCase {
    /// Update weight and/or reps of all incomplete sets in an exercise
    /// - Parameters:
    ///   - sessionId: ID of the active session
    ///   - exerciseId: ID of the exercise containing the sets
    ///   - weight: New weight value (optional, nil = keep current)
    ///   - reps: New reps value (optional, nil = keep current)
    /// - Returns: Updated session
    /// - Throws: UpdateAllSetsError if operation fails
    func execute(
        sessionId: UUID,
        exerciseId: UUID,
        weight: Double?,
        reps: Int?
    ) async throws -> DomainWorkoutSession
}

// MARK: - Implementation

final class DefaultUpdateAllSetsUseCase: UpdateAllSetsUseCase {

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
        exerciseId: UUID,
        weight: Double? = nil,
        reps: Int? = nil
    ) async throws -> DomainWorkoutSession {

        // 1. Fetch session
        guard var session = try await repository.fetchActiveSession() else {
            throw UpdateAllSetsError.sessionNotFound(sessionId)
        }

        // 2. Verify session ID matches
        guard session.id == sessionId else {
            throw UpdateAllSetsError.sessionNotFound(sessionId)
        }

        // 3. Validate input
        if let newWeight = weight {
            guard newWeight > 0 else {
                throw UpdateAllSetsError.invalidWeight(newWeight)
            }
        }

        if let newReps = reps {
            guard newReps > 0 else {
                throw UpdateAllSetsError.invalidReps(newReps)
            }
        }

        // 4. Find exercise
        guard let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId })
        else {
            throw UpdateAllSetsError.exerciseNotFound(exerciseId)
        }

        // Get the exercise's exerciseId (reference to Exercise catalog)
        let catalogExerciseId = session.exercises[exerciseIndex].exerciseId

        // 5. Update all incomplete sets
        var updatedCount = 0
        for setIndex in session.exercises[exerciseIndex].sets.indices {
            let set = session.exercises[exerciseIndex].sets[setIndex]

            // Only update incomplete sets
            if !set.completed {
                if let newWeight = weight {
                    session.exercises[exerciseIndex].sets[setIndex].weight = newWeight
                }
                if let newReps = reps {
                    session.exercises[exerciseIndex].sets[setIndex].reps = newReps
                }
                updatedCount += 1
            }
        }

        // 6. Persist changes to session
        try await repository.update(session)

        // 7. Update exercise history (lastUsedWeight, lastUsedReps) using the first set's values
        if !session.exercises[exerciseIndex].sets.isEmpty {
            let firstSet = session.exercises[exerciseIndex].sets[0]
            try? await exerciseRepository.updateLastUsed(
                exerciseId: catalogExerciseId,
                weight: firstSet.weight,
                reps: firstSet.reps,
                date: Date()
            )
        }

        print(
            "✏️ Updated \(updatedCount) sets for exercise: weight=\(weight?.description ?? "unchanged"), reps=\(reps?.description ?? "unchanged")"
        )

        return session
    }
}

// MARK: - Errors

enum UpdateAllSetsError: Error, LocalizedError {
    case sessionNotFound(UUID)
    case exerciseNotFound(UUID)
    case invalidWeight(Double)
    case invalidReps(Int)

    var errorDescription: String? {
        switch self {
        case .sessionNotFound(let id):
            return "Session not found: \(id)"
        case .exerciseNotFound(let id):
            return "Exercise not found: \(id)"
        case .invalidWeight(let weight):
            return "Invalid weight: \(weight) kg. Weight must be greater than 0."
        case .invalidReps(let reps):
            return "Invalid reps: \(reps). Reps must be greater than 0."
        }
    }
}
