//
//  SessionExerciseGroupEntity.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V6 Schema - Superset/Circuit Training Support
//

import Foundation
import SwiftData

/// SwiftData persistence entity for active workout exercise groups
///
/// **Purpose:**
/// - Represents exercise groups during active workout sessions
/// - Supports superset (2 exercises) and circuit (multiple exercises) training
/// - Tracks round progression and group-specific rest times
///
/// **Design Decisions:**
/// - `@Model` class for SwiftData persistence
/// - Relationship to parent WorkoutSessionEntity
/// - Relationship to child SessionExerciseEntity
/// - Tracks current round and total rounds for progression
///
/// **Usage:**
/// ```swift
/// let group = SessionExerciseGroupEntity(
///     groupIndex: 0,
///     restAfterGroup: 120,
///     currentRound: 1,
///     totalRounds: 3
/// )
/// ```
@Model
final class SessionExerciseGroupEntity {

    // MARK: - Properties

    /// Unique identifier
    @Attribute(.unique) var id: UUID

    /// Order of this group within the session (0, 1, 2, ...)
    var groupIndex: Int

    /// Rest time after completing the full group/round (in seconds)
    var restAfterGroup: TimeInterval

    /// Exercises in this group during active session
    @Relationship(deleteRule: .cascade, inverse: \SessionExerciseEntity.group)
    var exercises: [SessionExerciseEntity]

    /// Current round being performed (1-based: 1, 2, 3, ...)
    var currentRound: Int

    /// Total rounds to complete
    var totalRounds: Int

    /// Parent session (inverse relationship)
    var session: WorkoutSessionEntity?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        groupIndex: Int = 0,
        restAfterGroup: TimeInterval = 120,
        exercises: [SessionExerciseEntity] = [],
        currentRound: Int = 1,
        totalRounds: Int = 3
    ) {
        self.id = id
        self.groupIndex = groupIndex
        self.restAfterGroup = restAfterGroup
        self.exercises = exercises
        self.currentRound = currentRound
        self.totalRounds = totalRounds
    }
}

// MARK: - SwiftData Schema

extension SessionExerciseGroupEntity {
    /// Schema migration version
    static let schemaVersion = 6
}
