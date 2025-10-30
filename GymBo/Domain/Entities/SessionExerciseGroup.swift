//
//  SessionExerciseGroup.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V6 Clean Architecture - Domain Layer
//

import Foundation

/// Domain Entity representing an exercise group during an active workout session
///
/// **Purpose:**
/// - Tracks exercise groups during superset/circuit training
/// - Manages round progression (e.g., Round 1/3, 2/3, 3/3)
/// - Contains exercises that are performed together in rotation
///
/// **Design:**
/// - Immutable value type (struct)
/// - Contains multiple SessionExercise instances
/// - Tracks current round and total rounds
/// - Defines rest time after completing the full group/round
///
/// **Usage Examples:**
/// ```swift
/// // Superset in progress (Round 2 of 3)
/// let superset = SessionExerciseGroup(
///     id: UUID(),
///     exercises: [bicepsExercise, tricepsExercise],
///     groupIndex: 0,
///     currentRound: 2,
///     totalRounds: 3,
///     restAfterGroup: 120
/// )
///
/// // Circuit training (Round 1 of 4)
/// let circuit = SessionExerciseGroup(
///     id: UUID(),
///     exercises: [squat, pushup, row, lunge, plank],
///     groupIndex: 0,
///     currentRound: 1,
///     totalRounds: 4,
///     restAfterGroup: 180
/// )
/// ```
struct SessionExerciseGroup: Identifiable, Equatable {

    // MARK: - Properties

    /// Unique identifier
    let id: UUID

    /// Exercises in this group during active session
    var exercises: [DomainSessionExercise]

    /// Order of this group within the session (0, 1, 2, ...)
    var groupIndex: Int

    /// Current round being performed (1-based: 1, 2, 3, ...)
    var currentRound: Int

    /// Total rounds to complete
    var totalRounds: Int

    /// Rest time after completing the full group/round (in seconds)
    var restAfterGroup: TimeInterval

    // MARK: - Computed Properties

    /// Number of exercises in this group
    var exerciseCount: Int {
        exercises.count
    }

    /// Whether this is a superset (exactly 2 exercises)
    var isSuperset: Bool {
        exercises.count == 2
    }

    /// Whether this is a circuit (3+ exercises)
    var isCircuit: Bool {
        exercises.count >= 3
    }

    /// Whether all rounds are completed
    var isCompleted: Bool {
        currentRound > totalRounds
    }

    /// Progress percentage for current round (0.0 to 1.0)
    var roundProgress: Double {
        guard !exercises.isEmpty else { return 0.0 }
        let completedInRound = exercises.filter { exercise in
            // Check if current set for this round is completed
            let setIndex = currentRound - 1
            guard setIndex < exercise.sets.count else { return false }
            return exercise.sets[setIndex].completed
        }.count
        return Double(completedInRound) / Double(exercises.count)
    }

    /// Overall progress percentage across all rounds (0.0 to 1.0)
    var overallProgress: Double {
        let completedRounds = currentRound - 1
        let currentRoundProgress = roundProgress
        let totalProgress = Double(completedRounds) + currentRoundProgress
        return min(totalProgress / Double(totalRounds), 1.0)
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        exercises: [DomainSessionExercise] = [],
        groupIndex: Int = 0,
        currentRound: Int = 1,
        totalRounds: Int = 3,
        restAfterGroup: TimeInterval = 120
    ) {
        self.id = id
        self.exercises = exercises
        self.groupIndex = groupIndex
        self.currentRound = currentRound
        self.totalRounds = totalRounds
        self.restAfterGroup = restAfterGroup
    }

    // MARK: - Equatable

    static func == (lhs: SessionExerciseGroup, rhs: SessionExerciseGroup) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Round Management

extension SessionExerciseGroup {

    /// Advances to the next round
    mutating func advanceToNextRound() {
        guard currentRound < totalRounds else { return }
        currentRound += 1
    }

    /// Checks if ready to advance to next round (all exercises in current round completed)
    var canAdvanceToNextRound: Bool {
        guard currentRound <= totalRounds else { return false }
        let setIndex = currentRound - 1
        return exercises.allSatisfy { exercise in
            guard setIndex < exercise.sets.count else { return false }
            return exercise.sets[setIndex].completed
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
    extension SessionExerciseGroup {
        /// Sample superset for previews/testing
        static var previewSuperset: SessionExerciseGroup {
            SessionExerciseGroup(
                exercises: [.preview, .previewWithNotes],
                groupIndex: 0,
                currentRound: 1,
                totalRounds: 3,
                restAfterGroup: 90
            )
        }

        /// Sample circuit for previews/testing
        static var previewCircuit: SessionExerciseGroup {
            SessionExerciseGroup(
                exercises: [.preview, .previewWithNotes, .preview],
                groupIndex: 0,
                currentRound: 2,
                totalRounds: 4,
                restAfterGroup: 180
            )
        }
    }
#endif
