//
//  AddExerciseToSessionUseCase.swift
//  GymBo
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for adding an exercise to an active session
///
/// **Business Rules:**
/// - Session must be active
/// - Exercise must exist
/// - New exercise gets next orderIndex
/// - Creates default sets based on exercise history or defaults
///
/// **Use Cases:**
/// - Session-only: Add exercise to current session only
/// - Permanent: Add exercise to session AND workout template
protocol AddExerciseToSessionUseCase {
    func execute(
        sessionId: UUID,
        exerciseId: UUID
    ) async throws -> DomainWorkoutSession
}

// MARK: - Errors

enum AddExerciseToSessionError: LocalizedError {
    case sessionNotFound(UUID)
    case exerciseNotFound(UUID)
    case sessionAlreadyEnded

    var errorDescription: String? {
        switch self {
        case .sessionNotFound(let id):
            return "Session nicht gefunden: \(id)"
        case .exerciseNotFound(let id):
            return "Übung nicht gefunden: \(id)"
        case .sessionAlreadyEnded:
            return "Session wurde bereits beendet"
        }
    }
}

// MARK: - Default Implementation

final class DefaultAddExerciseToSessionUseCase: AddExerciseToSessionUseCase {

    private let sessionRepository: SessionRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol

    init(
        sessionRepository: SessionRepositoryProtocol,
        exerciseRepository: ExerciseRepositoryProtocol
    ) {
        self.sessionRepository = sessionRepository
        self.exerciseRepository = exerciseRepository
    }

    func execute(
        sessionId: UUID,
        exerciseId: UUID
    ) async throws -> DomainWorkoutSession {
        // 1. Fetch active session
        guard var session = try await sessionRepository.fetchActiveSession(),
            session.id == sessionId
        else {
            throw AddExerciseToSessionError.sessionNotFound(sessionId)
        }

        // 2. Verify session is not ended
        guard session.endDate == nil else {
            throw AddExerciseToSessionError.sessionAlreadyEnded
        }

        // 3. Fetch exercise from catalog
        guard let catalogExercise = try? await exerciseRepository.fetch(id: exerciseId) else {
            throw AddExerciseToSessionError.exerciseNotFound(exerciseId)
        }

        // 4. Determine next orderIndex
        let maxOrderIndex = session.exercises.map { $0.orderIndex }.max() ?? -1
        let newOrderIndex = maxOrderIndex + 1

        // 5. Create default sets (3 sets with last used values or defaults)
        let defaultSets = createDefaultSets(from: catalogExercise)

        // 6. Create new session exercise
        let newSessionExercise = DomainSessionExercise(
            catalogExerciseId: exerciseId,
            sets: defaultSets,
            notes: nil,
            restTimeToNext: catalogExercise.lastUsedRestTime ?? 90.0,
            orderIndex: newOrderIndex,
            isFinished: false
        )

        // 7. Add to session
        session.exercises.append(newSessionExercise)

        // 8. Persist changes
        try await sessionRepository.update(session)

        print("✅ Added exercise to session: \(catalogExercise.name)")

        return session
    }

    // MARK: - Helpers

    private func createDefaultSets(from exercise: ExerciseEntity) -> [DomainSessionSet] {
        let defaultSetCount = exercise.lastUsedSetCount ?? 3
        let defaultWeight = exercise.lastUsedWeight ?? 0.0
        let defaultReps = exercise.lastUsedReps ?? 8

        return (0..<defaultSetCount).map { _ in
            DomainSessionSet(
                weight: defaultWeight,
                reps: defaultReps,
                completed: false
            )
        }
    }
}
