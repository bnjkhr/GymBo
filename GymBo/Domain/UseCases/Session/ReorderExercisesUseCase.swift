//
//  ReorderExercisesUseCase.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for reordering exercises within an active workout session
///
/// **Responsibility:**
/// - Reorder exercises in a session by updating their orderIndex
/// - Persist changes to repository
/// - Maintain data integrity
///
/// **Business Rules:**
/// - Only active sessions can be reordered
/// - orderIndex must be sequential (0, 1, 2, ...)
/// - All exercises must have unique orderIndex
///
/// **Usage:**
/// ```swift
/// try await useCase.execute(
///     sessionId: session.id,
///     from: IndexSet(integer: 2),
///     to: 0
/// )
/// ```
protocol ReorderExercisesUseCase {
    /// Reorder exercises in a session
    /// - Parameters:
    ///   - sessionId: ID of the session to modify
    ///   - source: Source indices of exercises to move
    ///   - destination: Destination index
    /// - Throws: UseCaseError if session not found or reordering fails
    func execute(sessionId: UUID, from source: IndexSet, to destination: Int) async throws
}

// MARK: - Default Implementation

@MainActor
final class DefaultReorderExercisesUseCase: ReorderExercisesUseCase {

    // MARK: - Properties

    private let sessionRepository: SessionRepositoryProtocol

    // MARK: - Initialization

    init(sessionRepository: SessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
    }

    // MARK: - Execute

    func execute(sessionId: UUID, from source: IndexSet, to destination: Int) async throws {
        // 1. Fetch session
        guard var session = try await sessionRepository.fetch(id: sessionId) else {
            throw UseCaseError.sessionNotFound(sessionId)
        }

        // 2. Sort exercises by orderIndex (to get correct current order)
        var exercises = session.exercises.sorted { $0.orderIndex < $1.orderIndex }

        // 3. Perform the move manually
        // Convert IndexSet to Array for sorting
        let sourceIndices = Array(source).sorted()

        // Collect items to move
        let itemsToMove: [DomainSessionExercise] = sourceIndices.compactMap { index in
            guard exercises.indices.contains(index) else { return nil }
            return exercises[index]
        }

        // Remove items from source positions (in reverse order to maintain indices)
        for index in sourceIndices.reversed() {
            if exercises.indices.contains(index) {
                exercises.remove(at: index)
            }
        }

        // Adjust destination index if needed
        let adjustedDestination: Int
        if let firstSourceIndex = source.min(), firstSourceIndex < destination {
            adjustedDestination = destination - source.count
        } else {
            adjustedDestination = destination
        }

        // Insert items at destination
        exercises.insert(contentsOf: itemsToMove, at: adjustedDestination)

        // 4. Update orderIndex for all exercises
        for (index, var exercise) in exercises.enumerated() {
            exercise.orderIndex = index
            exercises[index] = exercise
        }

        // 5. Update session with reordered exercises
        session.exercises = exercises

        // 6. Persist changes
        try await sessionRepository.update(session)

        print("✅ Reordered exercises: \(source) → \(destination)")
    }
}

// MARK: - Mock Implementation

#if DEBUG
    final class MockReorderExercisesUseCase: ReorderExercisesUseCase {
        var shouldThrowError = false
        var executeCalled = false
        var lastSource: IndexSet?
        var lastDestination: Int?

        func execute(sessionId: UUID, from source: IndexSet, to destination: Int) async throws {
            executeCalled = true
            lastSource = source
            lastDestination = destination

            if shouldThrowError {
                throw UseCaseError.invalidOperation("Mock error for testing")
            }

            print("🧪 Mock: Reordered exercises \(source) → \(destination)")
        }
    }
#endif
