//
//  WorkoutExercise.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Domain Entity representing an exercise template within a workout
///
/// **Difference from SessionExercise:**
/// - `WorkoutExercise` = Template (planned exercise with target values)
/// - `SessionExercise` = Active execution (actual sets with completed status)
struct WorkoutExercise: Identifiable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier for this exercise in the workout
    let id: UUID

    /// Reference to the exercise catalog entry
    let exerciseId: UUID

    /// Target number of sets for this exercise
    var targetSets: Int

    /// Target number of reps per set (nil for time-based exercises)
    var targetReps: Int?

    /// Target time per set in seconds (nil for rep-based exercises)
    var targetTime: TimeInterval?

    /// Target weight in kg (optional - may be bodyweight exercises)
    var targetWeight: Double?

    /// Rest time between sets in seconds (nil = use workout default)
    /// Used when perSetRestTimes is nil (same rest time for all sets)
    var restTime: TimeInterval?

    /// Individual rest times per set (nil = use restTime for all sets)
    /// Array length should match targetSets
    /// Index 0 = rest after set 1, Index 1 = rest after set 2, etc.
    var perSetRestTimes: [TimeInterval]?

    /// Order of this exercise in the workout
    var orderIndex: Int

    /// Optional notes for this specific exercise
    var notes: String?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        targetSets: Int = 3,
        targetReps: Int? = 8,
        targetTime: TimeInterval? = nil,
        targetWeight: Double? = nil,
        restTime: TimeInterval? = nil,
        perSetRestTimes: [TimeInterval]? = nil,
        orderIndex: Int = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetTime = targetTime
        self.targetWeight = targetWeight
        self.restTime = restTime
        self.perSetRestTimes = perSetRestTimes
        self.orderIndex = orderIndex
        self.notes = notes
    }

    // MARK: - Equatable

    static func == (lhs: WorkoutExercise, rhs: WorkoutExercise) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preview Helpers

#if DEBUG
    extension WorkoutExercise {
        static var preview: WorkoutExercise {
            WorkoutExercise(
                exerciseId: UUID(),
                targetSets: 3,
                targetReps: 8,
                targetWeight: 100.0,
                restTime: 90
            )
        }

        static var previewWithNotes: WorkoutExercise {
            WorkoutExercise(
                exerciseId: UUID(),
                targetSets: 4,
                targetReps: 10,
                targetWeight: 80.0,
                notes: "Focus on form, slow eccentric"
            )
        }
    }
#endif
