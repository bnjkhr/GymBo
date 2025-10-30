//
//  WorkoutSeedData.swift
//  GymBo
//
//  Created on 2025-10-23.
//  Updated on 2025-10-30 - 6 comprehensive Ganzkörper workouts from CSV
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
        // Exercise ID to Name mapping from exercises_with_ids.csv
        let exerciseIdToName: [Int: String] = [
            1: "Kniebeugen",
            2: "Kreuzheben",
            3: "Bankdrücken",
            4: "Schulterdrücken",
            5: "Vorgebeugtes Rudern",
            6: "Hip Thrust",
            9: "Bizeps-Curls",
            10: "Stirndrücken",
            12: "Rumänisches Kreuzheben",
            24: "Kurzhantel-Bankdrücken",
            27: "Seitheben",
            30: "Kurzhantelrudern",
            31: "Goblet Squat",
            33: "Hammer-Curls",
            36: "Wadenheben",
            39: "Überkopf-Trizepsdrücken",
            47: "Klimmzüge",
            48: "Dips",
            87: "Beinpresse",
            88: "Beinstrecker",
            89: "Beinbeuger",
            90: "Latzug zur Brust",
            91: "Rudern am Kabel",
            92: "Brustpresse-Maschine",
            94: "Schulterdrücken Maschine",
            96: "Bizeps-Curl Maschine",
            97: "Trizepsdrücken Maschine",
            102: "Smith-Maschine Bankdrücken",
            103: "Kabelzug Crossover",
            104: "Trizepsdrücken am Kabel",
            106: "Hackenschmidt-Kniebeuge",
            108: "Bauchpresse",
            110: "Reverse Butterfly",
            112: "Face Pulls",
            113: "Kabel-Holzhacken",
            114: "Beinbeuger sitzend",
            115: "Wadenheben stehend",
        ]

        var workouts: [WorkoutEntity] = []

        // ========================================
        // 1. Ganzkörper Maschinen Anfänger
        // ========================================
        let workout1 = WorkoutEntity(
            name: "Ganzkörper Maschinen Anfänger",
            date: Date(),
            exercises: [],
            defaultRestTime: 90,
            notes: "Ganzkörper-Muskelaufbau nur mit Maschinen für Einsteiger",
            isFavorite: true,
            isSampleWorkout: true,
            difficultyLevel: "Anfänger",
            equipmentType: "Maschinen"
        )

        // Exercise 1: Beinpresse (87) - 3x13, rest=90
        if let exerciseName = exerciseIdToName[87],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 90),
                workout: workout1,
                order: 0
            )
            workout1.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 87: not found in mapping or exercise database")
        }

        // Exercise 2: Brustpresse-Maschine (92) - 3x11, rest=90
        if let exerciseName = exerciseIdToName[92],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 11, weight: 0, restTime: 90),
                workout: workout1,
                order: 1
            )
            workout1.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 92: not found in mapping or exercise database")
        }

        // Exercise 3: Latzug zur Brust (90) - 3x11, rest=90
        if let exerciseName = exerciseIdToName[90],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 11, weight: 0, restTime: 90),
                workout: workout1,
                order: 2
            )
            workout1.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 90: not found in mapping or exercise database")
        }

        // Exercise 4: Schulterdrücken Maschine (94) - 3x11, rest=90
        if let exerciseName = exerciseIdToName[94],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 11, weight: 0, restTime: 90),
                workout: workout1,
                order: 3
            )
            workout1.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 94: not found in mapping or exercise database")
        }

        // Exercise 5: Beinstrecker (88) - 3x13, rest=60
        if let exerciseName = exerciseIdToName[88],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 60),
                workout: workout1,
                order: 4
            )
            workout1.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 88: not found in mapping or exercise database")
        }

        // Exercise 6: Beinbeuger (89) - 3x13, rest=60
        if let exerciseName = exerciseIdToName[89],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 60),
                workout: workout1,
                order: 5
            )
            workout1.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 89: not found in mapping or exercise database")
        }

        // Exercise 7: Bizeps-Curl Maschine (96) - 3x13, rest=60
        if let exerciseName = exerciseIdToName[96],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 60),
                workout: workout1,
                order: 6
            )
            workout1.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 96: not found in mapping or exercise database")
        }

        // Exercise 8: Trizepsdrücken Maschine (97) - 3x13, rest=60
        if let exerciseName = exerciseIdToName[97],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 60),
                workout: workout1,
                order: 7
            )
            workout1.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 97: not found in mapping or exercise database")
        }

        // Exercise 9: Bauchpresse (108) - 3x17, rest=60
        if let exerciseName = exerciseIdToName[108],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 17, weight: 0, restTime: 60),
                workout: workout1,
                order: 8
            )
            workout1.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 108: not found in mapping or exercise database")
        }

        workout1.exerciseCount = workout1.exercises.count
        workouts.append(workout1)

        // ========================================
        // 2. Ganzkörper Maschinen Fortgeschritten
        // ========================================
        let workout2 = WorkoutEntity(
            name: "Ganzkörper Maschinen Fortgeschritten",
            date: Date(),
            exercises: [],
            defaultRestTime: 90,
            notes: "Intensives Ganzkörper-Training nur mit Maschinen",
            isFavorite: false,
            isSampleWorkout: true,
            difficultyLevel: "Fortgeschritten",
            equipmentType: "Maschinen"
        )

        // Exercise 1: Hackenschmidt-Kniebeuge (106) - 4x9, rest=120
        if let exerciseName = exerciseIdToName[106],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 9, weight: 0, restTime: 120),
                workout: workout2,
                order: 0
            )
            workout2.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 106: not found in mapping or exercise database")
        }

        // Exercise 2: Smith-Maschine Bankdrücken (102) - 4x9, rest=120
        if let exerciseName = exerciseIdToName[102],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 9, weight: 0, restTime: 120),
                workout: workout2,
                order: 1
            )
            workout2.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 102: not found in mapping or exercise database")
        }

        // Exercise 3: Rudern am Kabel (91) - 4x9, rest=90
        if let exerciseName = exerciseIdToName[91],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 9, weight: 0, restTime: 90),
                workout: workout2,
                order: 2
            )
            workout2.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 91: not found in mapping or exercise database")
        }

        // Exercise 4: Kabelzug Crossover (103) - 3x11, rest=90
        if let exerciseName = exerciseIdToName[103],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 11, weight: 0, restTime: 90),
                workout: workout2,
                order: 3
            )
            workout2.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 103: not found in mapping or exercise database")
        }

        // Exercise 5: Reverse Butterfly (110) - 3x13, rest=90
        if let exerciseName = exerciseIdToName[110],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 90),
                workout: workout2,
                order: 4
            )
            workout2.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 110: not found in mapping or exercise database")
        }

        // Exercise 6: Beinbeuger sitzend (114) - 3x13, rest=60
        if let exerciseName = exerciseIdToName[114],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 60),
                workout: workout2,
                order: 5
            )
            workout2.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 114: not found in mapping or exercise database")
        }

        // Exercise 7: Kabel-Holzhacken (113) - 3x13, rest=60
        if let exerciseName = exerciseIdToName[113],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 60),
                workout: workout2,
                order: 6
            )
            workout2.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 113: not found in mapping or exercise database")
        }

        // Exercise 8: Face Pulls (112) - 3x13, rest=60
        if let exerciseName = exerciseIdToName[112],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 60),
                workout: workout2,
                order: 7
            )
            workout2.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 112: not found in mapping or exercise database")
        }

        // Exercise 9: Wadenheben stehend (115) - 4x17, rest=60
        if let exerciseName = exerciseIdToName[115],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 17, weight: 0, restTime: 60),
                workout: workout2,
                order: 8
            )
            workout2.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 115: not found in mapping or exercise database")
        }

        workout2.exerciseCount = workout2.exercises.count
        workouts.append(workout2)

        // ========================================
        // 3. Ganzkörper Freie Gewichte Anfänger
        // ========================================
        let workout3 = WorkoutEntity(
            name: "Ganzkörper Freie Gewichte Anfänger",
            date: Date(),
            exercises: [],
            defaultRestTime: 90,
            notes: "Ganzkörper-Muskelaufbau mit freien Gewichten für Einsteiger",
            isFavorite: false,
            isSampleWorkout: true,
            difficultyLevel: "Anfänger",
            equipmentType: "Freie Gewichte"
        )

        // Exercise 1: Goblet Squat (31) - 3x11, rest=120
        if let exerciseName = exerciseIdToName[31],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 11, weight: 0, restTime: 120),
                workout: workout3,
                order: 0
            )
            workout3.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 31: not found in mapping or exercise database")
        }

        // Exercise 2: Kurzhantel-Bankdrücken (24) - 3x11, rest=90
        if let exerciseName = exerciseIdToName[24],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 11, weight: 0, restTime: 90),
                workout: workout3,
                order: 1
            )
            workout3.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 24: not found in mapping or exercise database")
        }

        // Exercise 3: Kurzhantelrudern (30) - 3x11, rest=90
        if let exerciseName = exerciseIdToName[30],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 11, weight: 0, restTime: 90),
                workout: workout3,
                order: 2
            )
            workout3.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 30: not found in mapping or exercise database")
        }

        // Exercise 4: Seitheben (27) - 3x13, rest=60
        if let exerciseName = exerciseIdToName[27],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 60),
                workout: workout3,
                order: 3
            )
            workout3.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 27: not found in mapping or exercise database")
        }

        // Exercise 5: Hip Thrust (6) - 3x13, rest=90
        if let exerciseName = exerciseIdToName[6],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 90),
                workout: workout3,
                order: 4
            )
            workout3.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 6: not found in mapping or exercise database")
        }

        // Exercise 6: Hammer-Curls (33) - 3x13, rest=60
        if let exerciseName = exerciseIdToName[33],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 60),
                workout: workout3,
                order: 5
            )
            workout3.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 33: not found in mapping or exercise database")
        }

        // Exercise 7: Überkopf-Trizepsdrücken (39) - 3x13, rest=60
        if let exerciseName = exerciseIdToName[39],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 60),
                workout: workout3,
                order: 6
            )
            workout3.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 39: not found in mapping or exercise database")
        }

        // Exercise 8: Wadenheben (36) - 3x17, rest=60
        if let exerciseName = exerciseIdToName[36],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 17, weight: 0, restTime: 60),
                workout: workout3,
                order: 7
            )
            workout3.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 36: not found in mapping or exercise database")
        }

        workout3.exerciseCount = workout3.exercises.count
        workouts.append(workout3)

        // ========================================
        // 4. Ganzkörper Freie Gewichte Fortgeschritten
        // ========================================
        let workout4 = WorkoutEntity(
            name: "Ganzkörper Freie Gewichte Fortgeschritten",
            date: Date(),
            exercises: [],
            defaultRestTime: 90,
            notes: "Intensives Ganzkörper-Training mit freien Gewichten",
            isFavorite: false,
            isSampleWorkout: true,
            difficultyLevel: "Fortgeschritten",
            equipmentType: "Freie Gewichte"
        )

        // Exercise 1: Kniebeugen (1) - 4x7, rest=180
        if let exerciseName = exerciseIdToName[1],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 7, weight: 0, restTime: 180),
                workout: workout4,
                order: 0
            )
            workout4.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 1: not found in mapping or exercise database")
        }

        // Exercise 2: Kreuzheben (2) - 4x7, rest=180
        if let exerciseName = exerciseIdToName[2],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 7, weight: 0, restTime: 180),
                workout: workout4,
                order: 1
            )
            workout4.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 2: not found in mapping or exercise database")
        }

        // Exercise 3: Bankdrücken (3) - 4x7, rest=120
        if let exerciseName = exerciseIdToName[3],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 7, weight: 0, restTime: 120),
                workout: workout4,
                order: 2
            )
            workout4.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 3: not found in mapping or exercise database")
        }

        // Exercise 4: Schulterdrücken (4) - 3x9, rest=90
        if let exerciseName = exerciseIdToName[4],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 9, weight: 0, restTime: 90),
                workout: workout4,
                order: 3
            )
            workout4.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 4: not found in mapping or exercise database")
        }

        // Exercise 5: Vorgebeugtes Rudern (5) - 3x9, rest=90
        if let exerciseName = exerciseIdToName[5],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 9, weight: 0, restTime: 90),
                workout: workout4,
                order: 4
            )
            workout4.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 5: not found in mapping or exercise database")
        }

        // Exercise 6: Rumänisches Kreuzheben (12) - 3x11, rest=90
        if let exerciseName = exerciseIdToName[12],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 11, weight: 0, restTime: 90),
                workout: workout4,
                order: 5
            )
            workout4.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 12: not found in mapping or exercise database")
        }

        // Exercise 7: Stirndrücken (10) - 3x11, rest=60
        if let exerciseName = exerciseIdToName[10],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 11, weight: 0, restTime: 60),
                workout: workout4,
                order: 6
            )
            workout4.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 10: not found in mapping or exercise database")
        }

        // Exercise 8: Bizeps-Curls (9) - 3x11, rest=60
        if let exerciseName = exerciseIdToName[9],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 11, weight: 0, restTime: 60),
                workout: workout4,
                order: 7
            )
            workout4.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 9: not found in mapping or exercise database")
        }

        workout4.exerciseCount = workout4.exercises.count
        workouts.append(workout4)

        // ========================================
        // 5. Ganzkörper Mix Anfänger
        // ========================================
        let workout5 = WorkoutEntity(
            name: "Ganzkörper Mix Anfänger",
            date: Date(),
            exercises: [],
            defaultRestTime: 90,
            notes: "Ganzkörper-Training mit Maschinen und freien Gewichten für Einsteiger",
            isFavorite: false,
            isSampleWorkout: true,
            difficultyLevel: "Anfänger",
            equipmentType: "Gemischt"
        )

        // Exercise 1: Beinpresse (87) - 3x13, rest=90
        if let exerciseName = exerciseIdToName[87],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 90),
                workout: workout5,
                order: 0
            )
            workout5.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 87: not found in mapping or exercise database")
        }

        // Exercise 2: Kurzhantel-Bankdrücken (24) - 3x11, rest=90
        if let exerciseName = exerciseIdToName[24],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 11, weight: 0, restTime: 90),
                workout: workout5,
                order: 1
            )
            workout5.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 24: not found in mapping or exercise database")
        }

        // Exercise 3: Latzug zur Brust (90) - 3x11, rest=90
        if let exerciseName = exerciseIdToName[90],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 11, weight: 0, restTime: 90),
                workout: workout5,
                order: 2
            )
            workout5.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 90: not found in mapping or exercise database")
        }

        // Exercise 4: Seitheben (27) - 3x13, rest=60
        if let exerciseName = exerciseIdToName[27],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 60),
                workout: workout5,
                order: 3
            )
            workout5.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 27: not found in mapping or exercise database")
        }

        // Exercise 5: Beinbeuger (89) - 3x13, rest=60
        if let exerciseName = exerciseIdToName[89],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 60),
                workout: workout5,
                order: 4
            )
            workout5.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 89: not found in mapping or exercise database")
        }

        // Exercise 6: Hip Thrust (6) - 3x13, rest=90
        if let exerciseName = exerciseIdToName[6],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 90),
                workout: workout5,
                order: 5
            )
            workout5.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 6: not found in mapping or exercise database")
        }

        // Exercise 7: Bizeps-Curl Maschine (96) - 3x13, rest=60
        if let exerciseName = exerciseIdToName[96],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 60),
                workout: workout5,
                order: 6
            )
            workout5.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 96: not found in mapping or exercise database")
        }

        // Exercise 8: Trizepsdrücken am Kabel (104) - 3x13, rest=60
        if let exerciseName = exerciseIdToName[104],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 60),
                workout: workout5,
                order: 7
            )
            workout5.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 104: not found in mapping or exercise database")
        }

        // Exercise 9: Bauchpresse (108) - 3x17, rest=60
        if let exerciseName = exerciseIdToName[108],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 17, weight: 0, restTime: 60),
                workout: workout5,
                order: 8
            )
            workout5.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 108: not found in mapping or exercise database")
        }

        workout5.exerciseCount = workout5.exercises.count
        workouts.append(workout5)

        // ========================================
        // 6. Ganzkörper Mix Fortgeschritten
        // ========================================
        let workout6 = WorkoutEntity(
            name: "Ganzkörper Mix Fortgeschritten",
            date: Date(),
            exercises: [],
            defaultRestTime: 90,
            notes: "Intensives Ganzkörper-Training mit allen Trainingsformen",
            isFavorite: false,
            isSampleWorkout: true,
            difficultyLevel: "Fortgeschritten",
            equipmentType: "Gemischt"
        )

        // Exercise 1: Kniebeugen (1) - 4x7, rest=180
        if let exerciseName = exerciseIdToName[1],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 7, weight: 0, restTime: 180),
                workout: workout6,
                order: 0
            )
            workout6.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 1: not found in mapping or exercise database")
        }

        // Exercise 2: Bankdrücken (3) - 4x7, rest=120
        if let exerciseName = exerciseIdToName[3],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 7, weight: 0, restTime: 120),
                workout: workout6,
                order: 1
            )
            workout6.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 3: not found in mapping or exercise database")
        }

        // Exercise 3: Rudern am Kabel (91) - 4x9, rest=90
        if let exerciseName = exerciseIdToName[91],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 9, weight: 0, restTime: 90),
                workout: workout6,
                order: 2
            )
            workout6.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 91: not found in mapping or exercise database")
        }

        // Exercise 4: Klimmzüge (47) - 3x10, rest=120 (Max reps -> use 10)
        if let exerciseName = exerciseIdToName[47],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 10, weight: 0, restTime: 120),
                workout: workout6,
                order: 3
            )
            workout6.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 47: not found in mapping or exercise database")
        }

        // Exercise 5: Schulterdrücken (4) - 3x9, rest=90
        if let exerciseName = exerciseIdToName[4],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 9, weight: 0, restTime: 90),
                workout: workout6,
                order: 4
            )
            workout6.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 4: not found in mapping or exercise database")
        }

        // Exercise 6: Dips (48) - 3x10, rest=90 (Max reps -> use 10)
        if let exerciseName = exerciseIdToName[48],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 10, weight: 0, restTime: 90),
                workout: workout6,
                order: 5
            )
            workout6.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 48: not found in mapping or exercise database")
        }

        // Exercise 7: Rumänisches Kreuzheben (12) - 3x11, rest=90
        if let exerciseName = exerciseIdToName[12],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 11, weight: 0, restTime: 90),
                workout: workout6,
                order: 6
            )
            workout6.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 12: not found in mapping or exercise database")
        }

        // Exercise 8: Kabelzug Crossover (103) - 3x13, rest=60
        if let exerciseName = exerciseIdToName[103],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 13, weight: 0, restTime: 60),
                workout: workout6,
                order: 7
            )
            workout6.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 103: not found in mapping or exercise database")
        }

        // Exercise 9: Kabel-Holzhacken (113) - 3x17, rest=60
        if let exerciseName = exerciseIdToName[113],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 17, weight: 0, restTime: 60),
                workout: workout6,
                order: 8
            )
            workout6.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 113: not found in mapping or exercise database")
        }

        // Exercise 10: Wadenheben stehend (115) - 4x17, rest=60
        if let exerciseName = exerciseIdToName[115],
            let exercise = exercises[exerciseName]
        {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 17, weight: 0, restTime: 60),
                workout: workout6,
                order: 9
            )
            workout6.exercises.append(ex)
        } else {
            print("⚠️ Skipping exercise with ID 115: not found in mapping or exercise database")
        }

        workout6.exerciseCount = workout6.exercises.count
        workouts.append(workout6)

        return workouts
    }

    private static func createSets(
        count: Int, reps: Int, weight: Double, restTime: TimeInterval = 90
    ) -> [ExerciseSetEntity] {
        var sets: [ExerciseSetEntity] = []

        for _ in 0..<count {
            let set = ExerciseSetEntity(
                reps: reps,
                weight: weight,
                restTime: restTime,
                completed: false
            )
            sets.append(set)
        }

        return sets
    }
}
