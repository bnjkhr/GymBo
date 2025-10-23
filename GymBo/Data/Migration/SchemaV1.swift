//
//  SchemaV1.swift
//  GymBo
//
//  Created on 2025-10-23.
//  SwiftData Migration - Version 1.0.0
//

import Foundation
import SwiftData

/// Schema Version 1.0.0 - Initial Production Schema
///
/// **Purpose:**
/// - Freeze current schema state for future migrations
/// - Establishes baseline for all future schema changes
/// - Production-ready migration support
///
/// **Entities Included:**
/// - ExerciseEntity (exercise catalog)
/// - ExerciseSetEntity (sets in workout templates)
/// - WorkoutExerciseEntity (exercises in workouts)
/// - WorkoutFolderEntity (folder organization)
/// - WorkoutEntity (workout templates)
/// - ExerciseRecordEntity (PR records)
/// - UserProfileEntity (user profile)
/// - WorkoutSessionEntity (active sessions)
/// - SessionExerciseEntity (exercises in sessions)
/// - SessionSetEntity (sets in sessions)
///
/// **Created:** 2025-10-23 (Session 6)
/// **Status:** ✅ Production Ready
enum SchemaV1: VersionedSchema {

    /// Schema version identifier
    static var versionIdentifier = Schema.Version(1, 0, 0)

    /// All persistent model types in this schema version
    static var models: [any PersistentModel.Type] {
        [
            ExerciseEntity.self,
            ExerciseSetEntity.self,
            WorkoutExerciseEntity.self,
            WorkoutFolderEntity.self,
            WorkoutEntity.self,
            ExerciseRecordEntity.self,
            UserProfileEntity.self,
            WorkoutSessionEntity.self,
            SessionExerciseEntity.self,
            SessionSetEntity.self,
        ]
    }

    // MARK: - ExerciseEntity

    @Model
    final class ExerciseEntity {
        @Attribute(.unique) var id: UUID
        var name: String
        var muscleGroupsRaw: [String]
        var equipmentTypeRaw: String
        var difficultyLevelRaw: String
        var descriptionText: String
        var instructions: [String]
        var createdAt: Date

        // Last used values for progressive overload
        var lastUsedWeight: Double?
        var lastUsedReps: Int?
        var lastUsedSetCount: Int?
        var lastUsedDate: Date?
        var lastUsedRestTime: TimeInterval?

        @Relationship(inverse: \WorkoutExerciseEntity.exercise)
        var usages: [WorkoutExerciseEntity] = []

        init(
            id: UUID = UUID(),
            name: String,
            muscleGroupsRaw: [String] = [],
            equipmentTypeRaw: String = "mixed",
            difficultyLevelRaw: String = "Anfänger",
            descriptionText: String = "",
            instructions: [String] = [],
            createdAt: Date = Date(),
            lastUsedWeight: Double? = nil,
            lastUsedReps: Int? = nil,
            lastUsedSetCount: Int? = nil,
            lastUsedDate: Date? = nil,
            lastUsedRestTime: TimeInterval? = nil
        ) {
            self.id = id
            self.name = name
            self.muscleGroupsRaw = muscleGroupsRaw
            self.equipmentTypeRaw = equipmentTypeRaw
            self.difficultyLevelRaw = difficultyLevelRaw
            self.descriptionText = descriptionText
            self.instructions = instructions
            self.createdAt = createdAt
            self.lastUsedWeight = lastUsedWeight
            self.lastUsedReps = lastUsedReps
            self.lastUsedSetCount = lastUsedSetCount
            self.lastUsedDate = lastUsedDate
            self.lastUsedRestTime = lastUsedRestTime
        }
    }

    // MARK: - ExerciseSetEntity

    @Model
    final class ExerciseSetEntity {
        @Attribute(.unique) var id: UUID
        var reps: Int
        var weight: Double
        var restTime: TimeInterval
        var completed: Bool
        var owner: WorkoutExerciseEntity?

        init(
            id: UUID = UUID(),
            reps: Int,
            weight: Double,
            restTime: TimeInterval = 90,
            completed: Bool = false
        ) {
            self.id = id
            self.reps = reps
            self.weight = weight
            self.restTime = restTime
            self.completed = completed
        }
    }

    // MARK: - WorkoutExerciseEntity

    @Model
    final class WorkoutExerciseEntity {
        @Attribute(.unique) var id: UUID
        @Relationship(deleteRule: .nullify) var exercise: ExerciseEntity?
        @Relationship(deleteRule: .cascade, inverse: \ExerciseSetEntity.owner)
        var sets: [ExerciseSetEntity]
        var workout: WorkoutEntity?
        var session: WorkoutSessionEntity?
        var order: Int = 0

        init(
            id: UUID = UUID(),
            exercise: ExerciseEntity? = nil,
            sets: [ExerciseSetEntity] = [],
            workout: WorkoutEntity? = nil,
            session: WorkoutSessionEntity? = nil,
            order: Int = 0
        ) {
            self.id = id
            self.exercise = exercise
            self.sets = sets
            self.workout = workout
            self.session = session
            self.order = order
        }
    }

    // MARK: - WorkoutFolderEntity

    @Model
    final class WorkoutFolderEntity {
        @Attribute(.unique) var id: UUID
        var name: String
        var color: String
        var order: Int
        var createdDate: Date
        @Relationship(deleteRule: .nullify, inverse: \WorkoutEntity.folder)
        var workouts: [WorkoutEntity] = []

        init(
            id: UUID = UUID(),
            name: String,
            color: String = "#8B5CF6",
            order: Int = 0,
            createdDate: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.color = color
            self.order = order
            self.createdDate = createdDate
            self.workouts = []
        }
    }

    // MARK: - WorkoutEntity

    @Model
    final class WorkoutEntity {
        @Attribute(.unique) var id: UUID
        var name: String
        var date: Date
        @Relationship(deleteRule: .cascade, inverse: \WorkoutExerciseEntity.workout)
        var exercises: [WorkoutExerciseEntity]
        var defaultRestTime: TimeInterval
        var duration: TimeInterval?
        var notes: String
        var isFavorite: Bool
        var isSampleWorkout: Bool?
        var exerciseCount: Int = 0
        @Relationship(deleteRule: .nullify) var folder: WorkoutFolderEntity? = nil
        var orderInFolder: Int = 0

        init(
            id: UUID = UUID(),
            name: String,
            date: Date = Date(),
            exercises: [WorkoutExerciseEntity] = [],
            defaultRestTime: TimeInterval = 90,
            duration: TimeInterval? = nil,
            notes: String = "",
            isFavorite: Bool = false,
            isSampleWorkout: Bool? = nil,
            folder: WorkoutFolderEntity? = nil,
            orderInFolder: Int = 0
        ) {
            self.id = id
            self.name = name
            self.date = date
            self.exercises = exercises
            self.defaultRestTime = defaultRestTime
            self.duration = duration
            self.notes = notes
            self.isFavorite = isFavorite
            self.isSampleWorkout = isSampleWorkout
            self.exerciseCount = exercises.count
            self.folder = folder
            self.orderInFolder = orderInFolder
        }
    }

    // MARK: - ExerciseRecordEntity

    @Model
    final class ExerciseRecordEntity {
        @Attribute(.unique) var id: UUID
        var exerciseId: UUID
        var exerciseName: String
        var maxWeight: Double
        var maxWeightReps: Int
        var maxWeightDate: Date
        var maxReps: Int
        var maxRepsWeight: Double
        var maxRepsDate: Date
        var bestEstimatedOneRepMax: Double
        var bestOneRepMaxWeight: Double
        var bestOneRepMaxReps: Int
        var bestOneRepMaxDate: Date
        var createdAt: Date
        var updatedAt: Date

        init(
            id: UUID = UUID(),
            exerciseId: UUID,
            exerciseName: String,
            maxWeight: Double = 0,
            maxWeightReps: Int = 0,
            maxWeightDate: Date = Date(),
            maxReps: Int = 0,
            maxRepsWeight: Double = 0,
            maxRepsDate: Date = Date(),
            bestEstimatedOneRepMax: Double = 0,
            bestOneRepMaxWeight: Double = 0,
            bestOneRepMaxReps: Int = 0,
            bestOneRepMaxDate: Date = Date(),
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.exerciseId = exerciseId
            self.exerciseName = exerciseName
            self.maxWeight = maxWeight
            self.maxWeightReps = maxWeightReps
            self.maxWeightDate = maxWeightDate
            self.maxReps = maxReps
            self.maxRepsWeight = maxRepsWeight
            self.maxRepsDate = maxRepsDate
            self.bestEstimatedOneRepMax = bestEstimatedOneRepMax
            self.bestOneRepMaxWeight = bestOneRepMaxWeight
            self.bestOneRepMaxReps = bestOneRepMaxReps
            self.bestOneRepMaxDate = bestOneRepMaxDate
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    // MARK: - UserProfileEntity

    @Model
    final class UserProfileEntity {
        @Attribute(.unique) var id: UUID
        var name: String
        var birthDate: Date?
        var weight: Double?
        var height: Double?
        var biologicalSexRaw: Int16
        var healthKitSyncEnabled: Bool
        var goalRaw: String
        var experienceRaw: String
        var equipmentRaw: String
        var preferredDurationRaw: Int
        var profileImageData: Data?
        var lockerNumber: String?
        var hasExploredWorkouts: Bool
        var hasCreatedFirstWorkout: Bool
        var hasSetupProfile: Bool
        var createdAt: Date
        var updatedAt: Date

        init(
            id: UUID = UUID(),
            name: String = "",
            birthDate: Date? = nil,
            weight: Double? = nil,
            height: Double? = nil,
            biologicalSexRaw: Int16 = 0,
            healthKitSyncEnabled: Bool = false,
            goalRaw: String = "general",
            experienceRaw: String = "intermediate",
            equipmentRaw: String = "mixed",
            preferredDurationRaw: Int = 45,
            profileImageData: Data? = nil,
            lockerNumber: String? = nil,
            hasExploredWorkouts: Bool = false,
            hasCreatedFirstWorkout: Bool = false,
            hasSetupProfile: Bool = false,
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.birthDate = birthDate
            self.weight = weight
            self.height = height
            self.biologicalSexRaw = biologicalSexRaw
            self.healthKitSyncEnabled = healthKitSyncEnabled
            self.goalRaw = goalRaw
            self.experienceRaw = experienceRaw
            self.equipmentRaw = equipmentRaw
            self.preferredDurationRaw = preferredDurationRaw
            self.profileImageData = profileImageData
            self.lockerNumber = lockerNumber
            self.hasExploredWorkouts = hasExploredWorkouts
            self.hasCreatedFirstWorkout = hasCreatedFirstWorkout
            self.hasSetupProfile = hasSetupProfile
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    // MARK: - WorkoutSessionEntity

    @Model
    final class WorkoutSessionEntity {
        @Attribute(.unique) var id: UUID
        var workoutId: UUID
        var startDate: Date
        var endDate: Date?
        var state: String
        @Relationship(deleteRule: .cascade, inverse: \SessionExerciseEntity.session)
        var exercises: [SessionExerciseEntity]

        init(
            id: UUID = UUID(),
            workoutId: UUID,
            startDate: Date,
            endDate: Date? = nil,
            state: String = "active",
            exercises: [SessionExerciseEntity] = []
        ) {
            self.id = id
            self.workoutId = workoutId
            self.startDate = startDate
            self.endDate = endDate
            self.state = state
            self.exercises = exercises
        }
    }

    // MARK: - SessionExerciseEntity

    @Model
    final class SessionExerciseEntity {
        @Attribute(.unique) var id: UUID
        var exerciseId: UUID
        var notes: String?
        var restTimeToNext: TimeInterval?
        var orderIndex: Int
        var isFinished: Bool = false
        @Relationship(deleteRule: .cascade, inverse: \SessionSetEntity.exercise)
        var sets: [SessionSetEntity]
        var session: WorkoutSessionEntity?

        init(
            id: UUID = UUID(),
            exerciseId: UUID,
            notes: String? = nil,
            restTimeToNext: TimeInterval? = nil,
            orderIndex: Int = 0,
            isFinished: Bool = false,
            sets: [SessionSetEntity] = []
        ) {
            self.id = id
            self.exerciseId = exerciseId
            self.notes = notes
            self.restTimeToNext = restTimeToNext
            self.orderIndex = orderIndex
            self.isFinished = isFinished
            self.sets = sets
        }
    }

    // MARK: - SessionSetEntity

    @Model
    final class SessionSetEntity {
        @Attribute(.unique) var id: UUID
        var weight: Double
        var reps: Int
        var completed: Bool
        var completedAt: Date?
        var orderIndex: Int
        var exercise: SessionExerciseEntity?

        init(
            id: UUID = UUID(),
            weight: Double,
            reps: Int,
            completed: Bool = false,
            completedAt: Date? = nil,
            orderIndex: Int = 0
        ) {
            self.id = id
            self.weight = weight
            self.reps = reps
            self.completed = completed
            self.completedAt = completedAt
            self.orderIndex = orderIndex
        }
    }
}
