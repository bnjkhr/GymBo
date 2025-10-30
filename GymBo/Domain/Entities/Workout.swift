//
//  Workout.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Workout training type
enum WorkoutType: String, Codable, Equatable, Hashable {
    case standard   // Traditional sequential training
    case superset   // Paired exercises (A1-A2, B1-B2)
    case circuit    // Station rotation (A-B-C-D-E)
}

/// Domain Entity representing a workout template
struct Workout: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var exercises: [WorkoutExercise]
    var defaultRestTime: TimeInterval
    var notes: String?
    let createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool
    var difficultyLevel: String?  // "Anfänger", "Fortgeschritten", "Profi"
    var equipmentType: String?  // "Maschine", "Freie Gewichte", "Gemischt"
    var folderId: UUID?  // Reference to WorkoutFolder
    var orderInFolder: Int
    var warmupStrategy: WarmupCalculator.Strategy?  // Preferred warmup strategy for this workout

    // V6: Superset/Circuit Support
    var workoutType: WorkoutType  // Type of workout (standard, superset, circuit)
    var exerciseGroups: [ExerciseGroup]?  // Exercise groups for superset/circuit (nil for standard)

    var exerciseCount: Int {
        exercises.count
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.targetSets }
    }

    init(
        id: UUID = UUID(),
        name: String,
        exercises: [WorkoutExercise] = [],
        defaultRestTime: TimeInterval = 90,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isFavorite: Bool = false,
        difficultyLevel: String? = nil,
        equipmentType: String? = nil,
        folderId: UUID? = nil,
        orderInFolder: Int = 0,
        warmupStrategy: WarmupCalculator.Strategy? = nil,
        workoutType: WorkoutType = .standard,
        exerciseGroups: [ExerciseGroup]? = nil
    ) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.defaultRestTime = defaultRestTime
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFavorite = isFavorite
        self.difficultyLevel = difficultyLevel
        self.equipmentType = equipmentType
        self.folderId = folderId
        self.orderInFolder = orderInFolder
        self.warmupStrategy = warmupStrategy
        self.workoutType = workoutType
        self.exerciseGroups = exerciseGroups
    }

    static func == (lhs: Workout, rhs: Workout) -> Bool {
        lhs.id == rhs.id
    }
}
