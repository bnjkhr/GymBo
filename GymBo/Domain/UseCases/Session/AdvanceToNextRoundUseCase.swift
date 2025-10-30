//
//  AdvanceToNextRoundUseCase.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V6 Clean Architecture - Domain Layer
//

import Foundation

/// Use Case for manually advancing to the next round in a circuit/superset session
///
/// **Responsibility:**
/// - Manually advance to next round in a circuit/superset workout
/// - Skip incomplete sets in current round (user decision)
/// - Persist changes to repository
///
/// **Business Rules:**
/// - Can only advance if not already at final round
/// - Works for both superset and circuit workouts
/// - Does not require all sets in current round to be complete (manual override)
/// - Updates currentRound in SessionExerciseGroup
///
/// **Usage:**
/// ```swift
/// let useCase = DefaultAdvanceToNextRoundUseCase(repository: repository)
/// try await useCase.execute(sessionId: sessionId, groupId: groupId)
/// ```
protocol AdvanceToNextRoundUseCase {
    /// Manually advance to next round in a circuit/superset workout
    /// - Parameters:
    ///   - sessionId: ID of the session
    ///   - groupId: ID of the exercise group
    /// - Throws: UseCaseError if cannot advance
    func execute(sessionId: UUID, groupId: UUID) async throws
}

// MARK: - Implementation

/// Default implementation of AdvanceToNextRoundUseCase
final class DefaultAdvanceToNextRoundUseCase: AdvanceToNextRoundUseCase {

    // MARK: - Properties

    private let sessionRepository: SessionRepositoryProtocol

    // MARK: - Initialization

    init(sessionRepository: SessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
    }

    // MARK: - Execute

    func execute(sessionId: UUID, groupId: UUID) async throws {
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

        let currentRound = groups[groupIndex].currentRound
        let totalRounds = groups[groupIndex].totalRounds

        // Check if already at final round
        if currentRound >= totalRounds {
            throw UseCaseError.invalidOperation(
                "Already at final round (\(totalRounds)/\(totalRounds)) - cannot advance further")
        }

        // Advance to next round
        session.exerciseGroups![groupIndex].advanceToNextRound()

        let newRound = session.exerciseGroups![groupIndex].currentRound

        print("🔄 Manually advanced from round \(currentRound) to round \(newRound)")

        // Update session in repository
        do {
            try await sessionRepository.update(session)
        } catch {
            throw UseCaseError.updateFailed(error)
        }
    }
}
