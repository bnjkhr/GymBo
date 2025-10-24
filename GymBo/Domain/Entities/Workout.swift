//
//  Workout.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

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
        equipmentType: String? = nil
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
    }

    static func == (lhs: Workout, rhs: Workout) -> Bool {
        lhs.id == rhs.id
    }
}
