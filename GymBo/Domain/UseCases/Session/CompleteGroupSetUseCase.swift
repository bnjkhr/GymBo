//
//  CompleteGroupSetUseCase.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V6 Clean Architecture - Domain Layer
//

import Foundation

/// Use Case for completing a set within a superset/circuit training session
///
/// **Responsibility:**
/// - Mark a specific set as completed in a grouped workout
/// - Track round progression within exercise groups
/// - Auto-advance to next round when group is completed
/// - Persist changes to repository
///
/// **Business Rules:**
/// - Set must exist in session
/// - Set can be toggled between completed/incomplete
/// - Completion timestamp is set automatically
/// - For supersets: Advance between paired exercises (A1 → A2 → A1 ...)
/// - For circuits: Advance through all stations (A → B → C ... → A)
/// - Auto-advance to next round when all exercises in current round are complete
/// - Rest timer starts after set completion (handled by timer service)
///
/// **Usage:**
/// ```swift
/// let useCase = DefaultCompleteGroupSetUseCase(repository: repository)
/// try await useCase.execute(
///     sessionId: sessionId,
///     groupId: groupId,
///     exerciseId: exerciseId,
///     setId: setId
/// )
/// ```
protocol CompleteGroupSetUseCase {
    /// Complete a set in a superset/circuit workout session
    /// - Parameters:
    ///   - sessionId: ID of the session
    ///   - groupId: ID of the exercise group
    ///   - exerciseId: ID of the exercise containing the set
    ///   - setId: ID of the set to complete
    /// - Throws: UseCaseError if set cannot be completed
    func execute(sessionId: UUID, groupId: UUID, exerciseId: UUID, setId: UUID) async throws
}

// MARK: - Implementation

/// Default implementation of CompleteGroupSetUseCase
final class DefaultCompleteGroupSetUseCase: CompleteGroupSetUseCase {

    // MARK: - Properties

    private let sessionRepository: SessionRepositoryProtocol

    // MARK: - Initialization

    init(sessionRepository: SessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
    }

    // MARK: - Execute

    func execute(sessionId: UUID, groupId: UUID, exerciseId: UUID, setId: UUID) async throws {
        // Fetch session
        guard var session = try await sessionRepository.fetch(id: sessionId) else {
            throw UseCaseError.sessionNotFound(sessionId)
        }

        // Validate workout type is superset or circuit
        guard session.workoutType == .superset || session.workoutType == .circuit else {
            throw UseCaseError.invalidOperation(
                "This use case only works with superset/circuit workouts (found: \(session.workoutType.rawValue))"
            )
        }

        // Find group index
        guard
            let groups = session.exerciseGroups,
            let groupIndex = groups.firstIndex(where: { $0.id == groupId })
        else {
            throw UseCaseError.invalidInput("Exercise group not found: \(groupId)")
        }

        // Find exercise within group
        guard
            let exerciseIndexInGroup = groups[groupIndex].exercises.firstIndex(where: {
                $0.id == exerciseId
            })
        else {
            throw UseCaseError.exerciseNotFound(exerciseId)
        }

        // Find set within exercise
        guard
            let setIndex = groups[groupIndex].exercises[exerciseIndexInGroup].sets.firstIndex(
                where: { $0.id == setId })
        else {
            throw UseCaseError.setNotFound(setId)
        }

        // Toggle set completion status
        session.exerciseGroups![groupIndex].exercises[exerciseIndexInGroup].sets[setIndex]
            .toggleCompletion()

        let currentRound = groups[groupIndex].currentRound

        print(
            "✅ Set completed in group \(groupIndex + 1), exercise \(exerciseIndexInGroup + 1), round \(currentRound)"
        )

        // Check if current round is complete for this group
        if session.exerciseGroups![groupIndex].canAdvanceToNextRound {
            // All exercises in current round are done - advance to next round
            session.exerciseGroups![groupIndex].advanceToNextRound()

            let newRound = session.exerciseGroups![groupIndex].currentRound
            let totalRounds = session.exerciseGroups![groupIndex].totalRounds

            if newRound <= totalRounds {
                print("🔄 Round \(currentRound) complete - advancing to round \(newRound)")
            } else {
                print("✅ Group \(groupIndex + 1) completed all \(totalRounds) rounds!")
            }
        }

        // Auto-finish exercise if all sets are completed
        let allSetsCompleted = session.exerciseGroups![groupIndex].exercises[exerciseIndexInGroup]
            .sets.allSatisfy { $0.completed }
        if allSetsCompleted
            && !session.exerciseGroups![groupIndex].exercises[exerciseIndexInGroup].isFinished
        {
            session.exerciseGroups![groupIndex].exercises[exerciseIndexInGroup].isFinished = true
            print("✅ All sets completed - exercise auto-finished")
        }
        // Un-finish exercise if user uncompletes a set
        else if !allSetsCompleted
            && session.exerciseGroups![groupIndex].exercises[exerciseIndexInGroup].isFinished
        {
            session.exerciseGroups![groupIndex].exercises[exerciseIndexInGroup].isFinished = false
            print("⚠️ Set uncompleted - exercise un-finished")
        }

        // Update session in repository
        do {
            try await sessionRepository.update(session)
        } catch {
            throw UseCaseError.updateFailed(error)
        }
    }
}
