//
//  WorkoutSeedData.swift
//  GymBo
//
//  Created on 2025-10-23.
//

import Foundation
import SwiftData

/// Seeds the database with sample workout templates for development
struct WorkoutSeedData {

    /// Seed sample workouts into the database
    static func seedIfNeeded(context: ModelContext) {
        // Check if workouts already exist
        let descriptor = FetchDescriptor<WorkoutEntity>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        if existingCount > 0 {
            print("📊 Workouts already seeded (\(existingCount) workouts)")
            return
        }

        print("🌱 Seeding sample workouts...")

        // Load exercises first
        guard let exercises = try? fetchExercises(context: context) else {
            print("❌ Failed to load exercises for workout seeding")
            return
        }

        // Create sample workouts
        let workouts = createSampleWorkouts(exercises: exercises)

        for workout in workouts {
            context.insert(workout)
        }

        do {
            try context.save()
            print("✅ Seeded \(workouts.count) sample workouts")
        } catch {
            print("❌ Failed to seed workouts: \(error)")
        }
    }

    // MARK: - Private Helpers

    private static func fetchExercises(context: ModelContext) throws -> [String: ExerciseEntity] {
        let descriptor = FetchDescriptor<ExerciseEntity>()
        let allExercises = try context.fetch(descriptor)

        var exerciseMap: [String: ExerciseEntity] = [:]
        for exercise in allExercises {
            exerciseMap[exercise.name] = exercise
        }

        return exerciseMap
    }

    private static func createSampleWorkouts(exercises: [String: ExerciseEntity]) -> [WorkoutEntity]
    {
        var workouts: [WorkoutEntity] = []

        // 1. Push Day (Chest, Shoulders, Triceps)
        if let benchPress = exercises["Bankdrücken"] {
            let pushDay = WorkoutEntity(
                name: "Push Day",
                date: Date(),
                exercises: [],
                defaultRestTime: 90,
                notes: "Fokus auf Brust, Schultern und Trizeps",
                isFavorite: true
            )

            // Bankdrücken: 4x8
            let benchExercise = WorkoutExerciseEntity(
                exercise: benchPress,
                sets: createSets(count: 4, reps: 8, weight: 100.0),
                workout: pushDay,
                order: 0
            )

            pushDay.exercises.append(benchExercise)
            pushDay.exerciseCount = 1

            workouts.append(pushDay)
        }

        // 2. Pull Day (Back, Biceps)
        if let latPulldown = exercises["Lat Pulldown"] {
            let pullDay = WorkoutEntity(
                name: "Pull Day",
                date: Date(),
                exercises: [],
                defaultRestTime: 90,
                notes: "Fokus auf Rücken und Bizeps",
                isFavorite: false
            )

            // Lat Pulldown: 3x10
            let latExercise = WorkoutExerciseEntity(
                exercise: latPulldown,
                sets: createSets(count: 3, reps: 10, weight: 80.0),
                workout: pullDay,
                order: 0
            )

            pullDay.exercises.append(latExercise)
            pullDay.exerciseCount = 1

            workouts.append(pullDay)
        }

        // 3. Leg Day (Legs, Glutes)
        if let squats = exercises["Kniebeugen"] {
            let legDay = WorkoutEntity(
                name: "Leg Day",
                date: Date(),
                exercises: [],
                defaultRestTime: 120,  // Longer rest for legs
                notes: "Fokus auf Beine und Gesäß",
                isFavorite: true
            )

            // Kniebeugen: 4x12
            let squatExercise = WorkoutExerciseEntity(
                exercise: squats,
                sets: createSets(count: 4, reps: 12, weight: 60.0),
                workout: legDay,
                order: 0
            )

            legDay.exercises.append(squatExercise)
            legDay.exerciseCount = 1

            workouts.append(legDay)
        }

        // 4. TEST WORKOUT - Multi-Exercise (for testing drag-and-drop reordering)
        let testWorkout = WorkoutEntity(
            name: "TEST - Multi Exercise",
            date: Date(),
            exercises: [],
            defaultRestTime: 90,
            notes: "Test workout mit 4 Übungen für Drag & Drop Testing",
            isFavorite: false
        )

        var exerciseOrder = 0

        // Exercise 1: Bankdrücken
        if let benchPress = exercises["Bankdrücken"] {
            let ex1 = WorkoutExerciseEntity(
                exercise: benchPress,
                sets: createSets(count: 3, reps: 10, weight: 80.0),
                workout: testWorkout,
                order: exerciseOrder
            )
            testWorkout.exercises.append(ex1)
            exerciseOrder += 1
        }

        // Exercise 2: Kniebeugen
        if let squats = exercises["Kniebeugen"] {
            let ex2 = WorkoutExerciseEntity(
                exercise: squats,
                sets: createSets(count: 3, reps: 12, weight: 60.0),
                workout: testWorkout,
                order: exerciseOrder
            )
            testWorkout.exercises.append(ex2)
            exerciseOrder += 1
        }

        // Exercise 3: Lat Pulldown
        if let latPulldown = exercises["Lat Pulldown"] {
            let ex3 = WorkoutExerciseEntity(
                exercise: latPulldown,
                sets: createSets(count: 3, reps: 10, weight: 70.0),
                workout: testWorkout,
                order: exerciseOrder
            )
            testWorkout.exercises.append(ex3)
            exerciseOrder += 1
        }

        // Exercise 4: Kreuzheben
        if let deadlift = exercises["Kreuzheben"] {
            let ex4 = WorkoutExerciseEntity(
                exercise: deadlift,
                sets: createSets(count: 3, reps: 8, weight: 100.0),
                workout: testWorkout,
                order: exerciseOrder
            )
            testWorkout.exercises.append(ex4)
            exerciseOrder += 1
        }

        testWorkout.exerciseCount = testWorkout.exercises.count
        workouts.append(testWorkout)

        return workouts
    }

    private static func createSets(count: Int, reps: Int, weight: Double) -> [ExerciseSetEntity] {
        var sets: [ExerciseSetEntity] = []

        for _ in 0..<count {
            let set = ExerciseSetEntity(
                reps: reps,
                weight: weight,
                restTime: 90,
                completed: false
            )
            sets.append(set)
        }

        return sets
    }
}
