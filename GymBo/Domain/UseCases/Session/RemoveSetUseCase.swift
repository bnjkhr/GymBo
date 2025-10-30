//
//  RemoveSetUseCase.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for removing a set from an exercise in an active session
///
/// **Business Rules:**
/// - Can only remove sets from active sessions
/// - Cannot remove the last remaining set (exercise must have at least 1 set)
/// - Removing a set permanently deletes it from history
/// - Set order is preserved after removal
///
/// **Usage:**
/// ```swift
/// let useCase = DefaultRemoveSetUseCase(repository: sessionRepository)
/// let updatedSession = try await useCase.execute(
///     sessionId: sessionId,
///     exerciseId: exerciseId,
///     setId: setId
/// )
/// ```
protocol RemoveSetUseCase {
    /// Remove a set from an exercise
    /// - Parameters:
    ///   - sessionId: ID of the active session
    ///   - exerciseId: ID of the exercise containing the set
    ///   - setId: ID of the set to remove
    /// - Returns: Updated session
    /// - Throws: RemoveSetError if operation fails
    func execute(
        sessionId: UUID,
        exerciseId: UUID,
        setId: UUID
    ) async throws -> DomainWorkoutSession
}

// MARK: - Implementation

final class DefaultRemoveSetUseCase: RemoveSetUseCase {

    private let repository: SessionRepositoryProtocol

    init(repository: SessionRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        sessionId: UUID,
        exerciseId: UUID,
        setId: UUID
    ) async throws -> DomainWorkoutSession {

        // 1. Fetch session
        guard var session = try await repository.fetchActiveSession() else {
            throw RemoveSetError.sessionNotFound(sessionId)
        }

        // 2. Verify session ID matches
        guard session.id == sessionId else {
            throw RemoveSetError.sessionNotFound(sessionId)
        }

        // 3. Find exercise
        guard let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId })
        else {
            throw RemoveSetError.exerciseNotFound(exerciseId)
        }

        // 4. Find set index
        guard
            let setIndex = session.exercises[exerciseIndex].sets.firstIndex(where: {
                $0.id == setId
            })
        else {
            throw RemoveSetError.setNotFound(setId)
        }

        // 5. Business rule: Cannot remove last set
        guard session.exercises[exerciseIndex].sets.count > 1 else {
            throw RemoveSetError.cannotRemoveLastSet
        }

        // 6. Remove set
        let removedSet = session.exercises[exerciseIndex].sets[setIndex]
        session.exercises[exerciseIndex].sets.remove(at: setIndex)

        // 7. Re-index remaining sets to maintain correct order
        // ⚠️ CRITICAL: Must preserve warmup → working order
        // Sort by current orderIndex, then reassign sequential indices
        session.exercises[exerciseIndex].sets.sort { $0.orderIndex < $1.orderIndex }
        for (newIndex, _) in session.exercises[exerciseIndex].sets.enumerated() {
            session.exercises[exerciseIndex].sets[newIndex].orderIndex = newIndex
        }

        // 8. Persist changes to session
        try await repository.update(session)

        print(
            "🗑️ Removed set: \(removedSet.weight)kg x \(removedSet.reps) reps (completed: \(removedSet.completed))"
        )

        return session
    }
}

// MARK: - Errors

enum RemoveSetError: Error, LocalizedError {
    case sessionNotFound(UUID)
    case exerciseNotFound(UUID)
    case setNotFound(UUID)
    case cannotRemoveLastSet

    var errorDescription: String? {
        switch self {
        case .sessionNotFound(let id):
            return "Session not found: \(id)"
        case .exerciseNotFound(let id):
            return "Exercise not found: \(id)"
        case .setNotFound(let id):
            return "Set not found: \(id)"
        case .cannotRemoveLastSet:
            return "Cannot remove the last set. Exercise must have at least one set."
        }
    }
}
