//
//  FinishExerciseUseCase.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for marking an exercise as finished
///
/// **Responsibility:**
/// - Mark exercise as finished (user moved to next exercise)
/// - Sets remain in their current state (some may be incomplete)
/// - Persist changes to repository
///
/// **Business Rules:**
/// - Exercise can be finished even with incomplete sets
/// - Finished exercises are hidden from main view (shown with eye toggle)
/// - Used for statistics and progress tracking
///
/// **Usage:**
/// ```swift
/// try await useCase.execute(
///     sessionId: session.id,
///     exerciseId: exercise.id
/// )
/// ```
protocol FinishExerciseUseCase {
    /// Mark an exercise as finished
    /// - Parameters:
    ///   - sessionId: ID of the session
    ///   - exerciseId: ID of the exercise to finish
    /// - Throws: UseCaseError if session or exercise not found
    func execute(sessionId: UUID, exerciseId: UUID) async throws
}

// MARK: - Default Implementation

@MainActor
final class DefaultFinishExerciseUseCase: FinishExerciseUseCase {

    // MARK: - Properties

    private let sessionRepository: SessionRepositoryProtocol

    // MARK: - Initialization

    init(sessionRepository: SessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
    }

    // MARK: - Execute

    func execute(sessionId: UUID, exerciseId: UUID) async throws {
        // 1. Fetch session
        guard var session = try await sessionRepository.fetch(id: sessionId) else {
            throw UseCaseError.sessionNotFound(sessionId)
        }

        // 2. Find exercise
        guard let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId })
        else {
            throw UseCaseError.exerciseNotFound(exerciseId)
        }

        // 3. Mark exercise as finished
        session.exercises[exerciseIndex].isFinished = true

        // 4. Persist changes
        try await sessionRepository.update(session)

        print("✅ Exercise finished: \(exerciseId)")
    }
}

// MARK: - Mock Implementation

#if DEBUG
    final class MockFinishExerciseUseCase: FinishExerciseUseCase {
        var shouldThrowError = false
        var executeCalled = false
        var lastExerciseId: UUID?

        func execute(sessionId: UUID, exerciseId: UUID) async throws {
            executeCalled = true
            lastExerciseId = exerciseId

            if shouldThrowError {
                throw UseCaseError.invalidOperation("Mock error for testing")
            }

            print("🧪 Mock: Exercise finished \(exerciseId)")
        }
    }
#endif
