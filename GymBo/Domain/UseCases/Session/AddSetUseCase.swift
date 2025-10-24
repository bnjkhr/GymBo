//
//  AddSetUseCase.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for adding a new set to an exercise in an active session
///
/// **Business Rules:**
/// - Can only add sets to active sessions
/// - New set is added at the end of the exercise's sets array
/// - Default values: weight and reps from last set, or 0 if no sets exist
/// - Set is initially incomplete (completed = false)
/// - Updates exercise history (lastUsedWeight/Reps) if provided
///
/// **Usage:**
/// ```swift
/// let useCase = DefaultAddSetUseCase(repository: sessionRepository)
/// let updatedSession = try await useCase.execute(
///     sessionId: sessionId,
///     exerciseId: exerciseId,
///     weight: 100.0,
///     reps: 8
/// )
/// ```
protocol AddSetUseCase {
    /// Add a new set to an exercise
    /// - Parameters:
    ///   - sessionId: ID of the active session
    ///   - exerciseId: ID of the exercise to add the set to
    ///   - weight: Weight for the new set (optional, defaults to last set's weight)
    ///   - reps: Reps for the new set (optional, defaults to last set's reps)
    /// - Returns: Updated session
    /// - Throws: AddSetError if operation fails
    func execute(
        sessionId: UUID,
        exerciseId: UUID,
        weight: Double?,
        reps: Int?
    ) async throws -> DomainWorkoutSession
}

// MARK: - Implementation

final class DefaultAddSetUseCase: AddSetUseCase {

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
        weight: Double?,
        reps: Int?
    ) async throws -> DomainWorkoutSession {

        // 1. Fetch session
        guard var session = try await repository.fetchActiveSession() else {
            throw AddSetError.sessionNotFound(sessionId)
        }

        // 2. Verify session ID matches
        guard session.id == sessionId else {
            throw AddSetError.sessionNotFound(sessionId)
        }

        // 3. Find exercise
        guard let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId })
        else {
            throw AddSetError.exerciseNotFound(exerciseId)
        }

        // 4. Determine weight and reps (use provided values or last set's values)
        let lastSet = session.exercises[exerciseIndex].sets.last
        let finalWeight = weight ?? lastSet?.weight ?? 0.0
        let finalReps = reps ?? lastSet?.reps ?? 0

        // 5. Validate values
        guard finalWeight > 0 else {
            throw AddSetError.invalidWeight(finalWeight)
        }

        guard finalReps > 0 else {
            throw AddSetError.invalidReps(finalReps)
        }

        // 6. Create new set with correct orderIndex
        let currentSetCount = session.exercises[exerciseIndex].sets.count

        let newSet = DomainSessionSet(
            weight: finalWeight,
            reps: finalReps,
            completed: false,
            orderIndex: currentSetCount
        )

        // 7. Add set to exercise
        session.exercises[exerciseIndex].sets.append(newSet)

        // 8. Reset isFinished flag (user is adding more sets, so exercise is not finished)
        session.exercises[exerciseIndex].isFinished = false

        // 9. Persist changes to session
        try await repository.update(session)

        // 9. Update exercise history (lastUsedWeight, lastUsedReps)
        let catalogExerciseId = session.exercises[exerciseIndex].exerciseId
        try? await exerciseRepository.updateLastUsed(
            exerciseId: catalogExerciseId,
            weight: finalWeight,
            reps: finalReps,
            date: Date()
        )

        print("➕ Added set to exercise: \(finalWeight)kg x \(finalReps) reps")

        return session
    }
}

// MARK: - Errors

enum AddSetError: Error, LocalizedError {
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
