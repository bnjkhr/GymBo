//
//  SessionExerciseEntity.swift
//  GymTracker
//
//  Created on 2025-10-22.
//  V2 Clean Architecture - Data Layer
//

import Foundation
import SwiftData

/// SwiftData persistence entity for DomainSessionExercise
///
/// **Design Decisions:**
/// - `@Model` class for SwiftData persistence
/// - Relationship to parent WorkoutSessionEntity
/// - Relationship to child SessionSetEntity
/// - Optional notes and restTimeToNext
@Model
final class SessionExerciseEntity {

    // MARK: - Properties

    /// Unique identifier
    @Attribute(.unique) var id: UUID

    /// Reference to exercise template
    var exerciseId: UUID

    /// Cached exercise name for display (loaded from exercise repository)
    var exerciseName: String = "Übung"

    /// Optional user notes
    var notes: String?

    /// Optional rest time in seconds before next exercise
    var restTimeToNext: TimeInterval?

    /// Order index for maintaining exercise sequence (CRITICAL for correct display order)
    var orderIndex: Int

    /// Whether the user has finished this exercise (moved to next exercise)
    var isFinished: Bool = false

    /// Sets for this exercise
    @Relationship(deleteRule: .cascade, inverse: \SessionSetEntity.exercise)
    var sets: [SessionSetEntity]

    /// Parent session (inverse relationship)
    var session: WorkoutSessionEntity?

    /// V6: Reference to session exercise group (for superset/circuit workouts)
    var groupId: UUID?
    var group: SessionExerciseGroupEntity?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        exerciseName: String = "Übung",
        notes: String? = nil,
        restTimeToNext: TimeInterval? = nil,
        orderIndex: Int = 0,
        isFinished: Bool = false,
        sets: [SessionSetEntity] = [],
        groupId: UUID? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.notes = notes
        self.restTimeToNext = restTimeToNext
        self.orderIndex = orderIndex
        self.isFinished = isFinished
        self.sets = sets
        self.groupId = groupId
    }
}
