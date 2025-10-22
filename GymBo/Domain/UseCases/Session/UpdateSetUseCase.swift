//
//  UpdateSetUseCase.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for updating weight/reps of a set during an active workout session
///
/// **Business Rules:**
/// - Can only update sets in active sessions
/// - Can update both completed and incomplete sets
/// - Updates are persisted immediately
/// - Invalid values (weight ≤ 0, reps ≤ 0) are rejected
///
/// **Usage:**
/// ```swift
/// let useCase = UpdateSetUseCase(repository: sessionRepository)
/// let updatedSession = try await useCase.execute(
///     sessionId: sessionId,
///     exerciseId: exerciseId,
///     setId: setId,
///     weight: 105.0,
///     reps: 8
/// )
/// ```
protocol UpdateSetUseCase {
    /// Update weight and/or reps of a specific set
    /// - Parameters:
    ///   - sessionId: ID of the active session
    ///   - exerciseId: ID of the exercise containing the set
    ///   - setId: ID of the set to update
    ///   - weight: New weight value (optional, nil = keep current)
    ///   - reps: New reps value (optional, nil = keep current)
    /// - Returns: Updated session
    /// - Throws: UpdateSetError if operation fails
    func execute(
        sessionId: UUID,
        exerciseId: UUID,
        setId: UUID,
        weight: Double?,
        reps: Int?
    ) async throws -> DomainWorkoutSession
}

// MARK: - Implementation

final class DefaultUpdateSetUseCase: UpdateSetUseCase {

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
        setId: UUID,
        weight: Double? = nil,
        reps: Int? = nil
    ) async throws -> DomainWorkoutSession {

        // 1. Fetch session
        guard var session = try await repository.fetchActiveSession() else {
            throw UpdateSetError.sessionNotFound(sessionId)
        }

        // 2. Verify session ID matches
        guard session.id == sessionId else {
            throw UpdateSetError.sessionNotFound(sessionId)
        }

        // 3. Find exercise
        guard let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId })
        else {
            throw UpdateSetError.exerciseNotFound(exerciseId)
        }

        // 4. Find set
        guard
            let setIndex = session.exercises[exerciseIndex].sets.firstIndex(where: {
                $0.id == setId
            })
        else {
            throw UpdateSetError.setNotFound(setId)
        }

        // Get the exercise's exerciseId (reference to Exercise catalog)
        let catalogExerciseId = session.exercises[exerciseIndex].exerciseId

        // 5. Update weight if provided
        if let newWeight = weight {
            guard newWeight > 0 else {
                throw UpdateSetError.invalidWeight(newWeight)
            }
            session.exercises[exerciseIndex].sets[setIndex].weight = newWeight
        }

        // 6. Update reps if provided
        if let newReps = reps {
            guard newReps > 0 else {
                throw UpdateSetError.invalidReps(newReps)
            }
            session.exercises[exerciseIndex].sets[setIndex].reps = newReps
        }

        // 7. Persist changes to session
        try await repository.update(session)

        // 8. Update exercise history (lastUsedWeight, lastUsedReps)
        // Use the final weight/reps values from the set
        let finalWeight = session.exercises[exerciseIndex].sets[setIndex].weight
        let finalReps = session.exercises[exerciseIndex].sets[setIndex].reps

        try? await exerciseRepository.updateLastUsed(
            exerciseId: catalogExerciseId,
            weight: finalWeight,
            reps: finalReps,
            date: Date()
        )

        print(
            "✏️ Updated set \(setId): weight=\(weight?.description ?? "unchanged"), reps=\(reps?.description ?? "unchanged")"
        )

        return session
    }
}

// MARK: - Errors

enum UpdateSetError: Error, LocalizedError {
    case sessionNotFound(UUID)
    case exerciseNotFound(UUID)
    case setNotFound(UUID)
    case invalidWeight(Double)
    case invalidReps(Int)

    var errorDescription: String? {
        switch self {
        case .sessionNotFound(let id):
            return "Session not found: \(id)"
        case .exerciseNotFound(let id):
            return "Exercise not found: \(id)"
        case .setNotFound(let id):
            return "Set not found: \(id)"
        case .invalidWeight(let weight):
            return "Invalid weight: \(weight) kg. Weight must be greater than 0."
        case .invalidReps(let reps):
            return "Invalid reps: \(reps). Reps must be greater than 0."
        }
    }
}
