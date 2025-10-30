//
//  ExerciseGroup.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V6 Clean Architecture - Domain Layer
//

import Foundation

/// Domain Entity representing an exercise group for superset/circuit training
///
/// **Purpose:**
/// - Groups multiple exercises that are performed together
/// - Used in superset training (2 exercises alternating)
/// - Used in circuit training (multiple stations in rotation)
///
/// **Design:**
/// - Immutable value type (struct)
/// - Contains multiple WorkoutExercise instances
/// - Defines rest time after completing the full group/round
///
/// **Usage Examples:**
/// ```swift
/// // Superset: Biceps + Triceps
/// let superset = ExerciseGroup(
///     id: UUID(),
///     exercises: [bicepsExercise, tricepsExercise],
///     groupIndex: 0,
///     restAfterGroup: 120
/// )
///
/// // Circuit: 5 stations
/// let circuit = ExerciseGroup(
///     id: UUID(),
///     exercises: [squat, pushup, row, lunge, plank],
///     groupIndex: 0,
///     restAfterGroup: 180
/// )
/// ```
struct ExerciseGroup: Identifiable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier
    let id: UUID

    /// Exercises in this group (2+ for supersets, any number for circuits)
    var exercises: [WorkoutExercise]

    /// Order of this group within the workout (0, 1, 2, ...)
    var groupIndex: Int

    /// Rest time after completing the full group/round (in seconds)
    var restAfterGroup: TimeInterval

    // MARK: - Computed Properties

    /// Number of exercises in this group
    var exerciseCount: Int {
        exercises.count
    }

    /// Total rounds to complete (based on targetSets of first exercise)
    /// Assumes all exercises in group have same targetSets
    var rounds: Int {
        exercises.first?.targetSets ?? 3
    }

    /// Whether this is a superset (exactly 2 exercises)
    var isSuperset: Bool {
        exercises.count == 2
    }

    /// Whether this is a circuit (3+ exercises)
    var isCircuit: Bool {
        exercises.count >= 3
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        exercises: [WorkoutExercise] = [],
        groupIndex: Int = 0,
        restAfterGroup: TimeInterval = 120
    ) {
        self.id = id
        self.exercises = exercises
        self.groupIndex = groupIndex
        self.restAfterGroup = restAfterGroup
    }

    // MARK: - Equatable

    static func == (lhs: ExerciseGroup, rhs: ExerciseGroup) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Validation

extension ExerciseGroup {

    /// Validates that all exercises in the group have the same targetSets
    var hasConsistentRounds: Bool {
        guard let firstTargetSets = exercises.first?.targetSets else {
            return false
        }
        return exercises.allSatisfy { $0.targetSets == firstTargetSets }
    }

    /// Validates that the group has at least 2 exercises
    var isValid: Bool {
        exercises.count >= 2
    }
}
