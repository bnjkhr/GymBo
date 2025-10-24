//
//  WorkoutSeedData.swift
//  GymBo
//
//  Created on 2025-10-23.
//  Updated on 2025-10-24 - 6 comprehensive sample workouts with difficulty levels
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

        // ========================================
        // 1. MASCHINEN: Ganzkörper Anfänger
        // ========================================
        let fullBodyMachine = WorkoutEntity(
            name: "Ganzkörper Maschine",
            date: Date(),
            exercises: [],
            defaultRestTime: 90,
            notes: "Anfängerfreundliches Ganzkörpertraining an Maschinen",
            isFavorite: true,
            isSampleWorkout: true,
            difficultyLevel: "Anfänger",
            equipmentType: "Maschine"
        )

        var order = 0

        // Beinpresse: 3x12
        if let exercise = exercises["Beinpresse"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 12, weight: 0),
                workout: fullBodyMachine,
                order: order
            )
            fullBodyMachine.exercises.append(ex)
            order += 1
        }

        // Brustpresse: 3x10
        if let exercise = exercises["Brustpresse-Maschine"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 10, weight: 0),
                workout: fullBodyMachine,
                order: order
            )
            fullBodyMachine.exercises.append(ex)
            order += 1
        }

        // Latzug: 3x10
        if let exercise = exercises["Latzug zur Brust"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 10, weight: 0),
                workout: fullBodyMachine,
                order: order
            )
            fullBodyMachine.exercises.append(ex)
            order += 1
        }

        // Schulterpresse: 3x10
        if let exercise = exercises["Schulterpresse-Maschine"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 10, weight: 0),
                workout: fullBodyMachine,
                order: order
            )
            fullBodyMachine.exercises.append(ex)
            order += 1
        }

        // Beinbeuger: 3x12
        if let exercise = exercises["Beinbeuger"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 12, weight: 0),
                workout: fullBodyMachine,
                order: order
            )
            fullBodyMachine.exercises.append(ex)
            order += 1
        }

        // Sitzendes Rudern: 3x10
        if let exercise = exercises["Sitzendes Kabelrudern"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 10, weight: 0),
                workout: fullBodyMachine,
                order: order
            )
            fullBodyMachine.exercises.append(ex)
            order += 1
        }

        fullBodyMachine.exerciseCount = fullBodyMachine.exercises.count
        workouts.append(fullBodyMachine)

        // ========================================
        // 2. MASCHINEN: Oberkörper Fortgeschritten
        // ========================================
        let upperBodyMachine = WorkoutEntity(
            name: "Oberkörper Maschine",
            date: Date(),
            exercises: [],
            defaultRestTime: 90,
            notes: "Intensives Oberkörpertraining an Maschinen",
            isFavorite: false,
            isSampleWorkout: true,
            difficultyLevel: "Fortgeschritten",
            equipmentType: "Maschine"
        )

        order = 0

        // Brustpresse: 4x8
        if let exercise = exercises["Brustpresse-Maschine"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 8, weight: 0),
                workout: upperBodyMachine,
                order: order
            )
            upperBodyMachine.exercises.append(ex)
            order += 1
        }

        // Latzug: 4x8
        if let exercise = exercises["Latzug zur Brust"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 8, weight: 0),
                workout: upperBodyMachine,
                order: order
            )
            upperBodyMachine.exercises.append(ex)
            order += 1
        }

        // Schulterpresse: 4x10
        if let exercise = exercises["Schulterpresse-Maschine"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 10, weight: 0),
                workout: upperBodyMachine,
                order: order
            )
            upperBodyMachine.exercises.append(ex)
            order += 1
        }

        // Sitzendes Rudern: 4x10
        if let exercise = exercises["Sitzendes Kabelrudern"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 10, weight: 0),
                workout: upperBodyMachine,
                order: order
            )
            upperBodyMachine.exercises.append(ex)
            order += 1
        }

        // Butterfly: 3x12
        if let exercise = exercises["Butterfly"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 12, weight: 0),
                workout: upperBodyMachine,
                order: order
            )
            upperBodyMachine.exercises.append(ex)
            order += 1
        }

        // Trizepsmaschine: 3x12
        if let exercise = exercises["Trizepsstrecker-Maschine"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 12, weight: 0),
                workout: upperBodyMachine,
                order: order
            )
            upperBodyMachine.exercises.append(ex)
            order += 1
        }

        // Bizeps Curl Maschine: 3x12
        if let exercise = exercises["Bizeps-Curl-Maschine"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 12, weight: 0),
                workout: upperBodyMachine,
                order: order
            )
            upperBodyMachine.exercises.append(ex)
            order += 1
        }

        upperBodyMachine.exerciseCount = upperBodyMachine.exercises.count
        workouts.append(upperBodyMachine)

        // ========================================
        // 3. FREIE GEWICHTE: Push Day
        // ========================================
        let pushDay = WorkoutEntity(
            name: "Push Day (Langhantel)",
            date: Date(),
            exercises: [],
            defaultRestTime: 120,
            notes: "Brust, Schultern und Trizeps mit freien Gewichten",
            isFavorite: true,
            isSampleWorkout: true,
            difficultyLevel: "Fortgeschritten",
            equipmentType: "Freie Gewichte"
        )

        order = 0

        // Bankdrücken: 4x6
        if let exercise = exercises["Bankdrücken"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 6, weight: 80.0, restTime: 120),
                workout: pushDay,
                order: order
            )
            pushDay.exercises.append(ex)
            order += 1
        }

        // Schrägbankdrücken: 4x8
        if let exercise = exercises["Schrägbankdrücken"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 8, weight: 60.0),
                workout: pushDay,
                order: order
            )
            pushDay.exercises.append(ex)
            order += 1
        }

        // Überkopfdrücken: 4x8
        if let exercise = exercises["Überkopfdrücken"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 8, weight: 40.0),
                workout: pushDay,
                order: order
            )
            pushDay.exercises.append(ex)
            order += 1
        }

        // Dips: 3x10
        if let exercise = exercises["Dips"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 10, weight: 0),
                workout: pushDay,
                order: order
            )
            pushDay.exercises.append(ex)
            order += 1
        }

        // Trizepsdrücken am Kabel: 3x12
        if let exercise = exercises["Trizepsdrücken am Kabel"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 12, weight: 0),
                workout: pushDay,
                order: order
            )
            pushDay.exercises.append(ex)
            order += 1
        }

        pushDay.exerciseCount = pushDay.exercises.count
        workouts.append(pushDay)

        // ========================================
        // 4. FREIE GEWICHTE: Pull Day
        // ========================================
        let pullDay = WorkoutEntity(
            name: "Pull Day (Langhantel & Kurzhantel)",
            date: Date(),
            exercises: [],
            defaultRestTime: 120,
            notes: "Rücken und Bizeps mit freien Gewichten",
            isFavorite: false,
            isSampleWorkout: true,
            difficultyLevel: "Fortgeschritten",
            equipmentType: "Freie Gewichte"
        )

        order = 0

        // Kreuzheben: 4x5
        if let exercise = exercises["Kreuzheben"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 5, weight: 100.0, restTime: 180),
                workout: pullDay,
                order: order
            )
            pullDay.exercises.append(ex)
            order += 1
        }

        // Langhantelrudern: 4x8
        if let exercise = exercises["Langhantelrudern"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 8, weight: 60.0),
                workout: pullDay,
                order: order
            )
            pullDay.exercises.append(ex)
            order += 1
        }

        // Klimmzüge: 4x6
        if let exercise = exercises["Klimmzüge"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 6, weight: 0),
                workout: pullDay,
                order: order
            )
            pullDay.exercises.append(ex)
            order += 1
        }

        // Kurzhantelrudern: 3x10
        if let exercise = exercises["Kurzhantelrudern"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 10, weight: 30.0),
                workout: pullDay,
                order: order
            )
            pullDay.exercises.append(ex)
            order += 1
        }

        // Bizeps Curls: 3x12
        if let exercise = exercises["Kurzhantel-Bizeps-Curls"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 12, weight: 12.0),
                workout: pullDay,
                order: order
            )
            pullDay.exercises.append(ex)
            order += 1
        }

        // Hammer Curls: 3x12
        if let exercise = exercises["Hammer-Curls"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 12, weight: 12.0),
                workout: pullDay,
                order: order
            )
            pullDay.exercises.append(ex)
            order += 1
        }

        pullDay.exerciseCount = pullDay.exercises.count
        workouts.append(pullDay)

        // ========================================
        // 5. GEMISCHT: Beine Push/Pull (Profi)
        // ========================================
        let legDay = WorkoutEntity(
            name: "Beine Push/Pull",
            date: Date(),
            exercises: [],
            defaultRestTime: 180,
            notes: "Komplettes Beintraining für Fortgeschrittene",
            isFavorite: true,
            isSampleWorkout: true,
            difficultyLevel: "Profi",
            equipmentType: "Gemischt"
        )

        order = 0

        // Kniebeugen (Langhantel): 5x5
        if let exercise = exercises["Kniebeugen"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 5, reps: 5, weight: 100.0, restTime: 180),
                workout: legDay,
                order: order
            )
            legDay.exercises.append(ex)
            order += 1
        }

        // Beinpresse (Maschine): 4x10
        if let exercise = exercises["Beinpresse"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 10, weight: 0),
                workout: legDay,
                order: order
            )
            legDay.exercises.append(ex)
            order += 1
        }

        // Rumänisches Kreuzheben (Langhantel): 4x8
        if let exercise = exercises["Rumänisches Kreuzheben"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 8, weight: 80.0),
                workout: legDay,
                order: order
            )
            legDay.exercises.append(ex)
            order += 1
        }

        // Beinbeuger (Maschine): 3x12
        if let exercise = exercises["Beinbeuger"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 12, weight: 0),
                workout: legDay,
                order: order
            )
            legDay.exercises.append(ex)
            order += 1
        }

        // Beinstrecker (Maschine): 3x12
        if let exercise = exercises["Beinstrecker"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 12, weight: 0),
                workout: legDay,
                order: order
            )
            legDay.exercises.append(ex)
            order += 1
        }

        // Walking Lunges (Kurzhantel): 3x12 pro Bein
        if let exercise = exercises["Ausfallschritte"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 12, weight: 20.0),
                workout: legDay,
                order: order
            )
            legDay.exercises.append(ex)
            order += 1
        }

        // Wadenheben (Maschine): 4x15
        if let exercise = exercises["Wadenheben stehend"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 15, weight: 0, restTime: 60),
                workout: legDay,
                order: order
            )
            legDay.exercises.append(ex)
            order += 1
        }

        legDay.exerciseCount = legDay.exercises.count
        workouts.append(legDay)

        // ========================================
        // 6. GEMISCHT: Oberkörper Hybrid
        // ========================================
        let hybridUpper = WorkoutEntity(
            name: "Oberkörper Hybrid",
            date: Date(),
            exercises: [],
            defaultRestTime: 90,
            notes: "Kombination aus freien Gewichten und Maschinen",
            isFavorite: false,
            isSampleWorkout: true,
            difficultyLevel: "Fortgeschritten",
            equipmentType: "Gemischt"
        )

        order = 0

        // Bankdrücken (Langhantel): 4x8
        if let exercise = exercises["Bankdrücken"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 8, weight: 70.0, restTime: 120),
                workout: hybridUpper,
                order: order
            )
            hybridUpper.exercises.append(ex)
            order += 1
        }

        // Brustpresse (Maschine): 3x10
        if let exercise = exercises["Brustpresse-Maschine"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 10, weight: 0),
                workout: hybridUpper,
                order: order
            )
            hybridUpper.exercises.append(ex)
            order += 1
        }

        // Klimmzüge (Bodyweight): 4x8
        if let exercise = exercises["Klimmzüge"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 8, weight: 0),
                workout: hybridUpper,
                order: order
            )
            hybridUpper.exercises.append(ex)
            order += 1
        }

        // Latzug (Maschine): 3x10
        if let exercise = exercises["Latzug zur Brust"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 10, weight: 0),
                workout: hybridUpper,
                order: order
            )
            hybridUpper.exercises.append(ex)
            order += 1
        }

        // Kurzhantel Schulterdrücken: 4x10
        if let exercise = exercises["Kurzhantel-Schulterdrücken"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 4, reps: 10, weight: 20.0),
                workout: hybridUpper,
                order: order
            )
            hybridUpper.exercises.append(ex)
            order += 1
        }

        // Seitheben (Kurzhantel): 3x12
        if let exercise = exercises["Seitheben"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 12, weight: 10.0),
                workout: hybridUpper,
                order: order
            )
            hybridUpper.exercises.append(ex)
            order += 1
        }

        // Bizeps Curls (Kurzhantel): 3x12
        if let exercise = exercises["Kurzhantel-Bizeps-Curls"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 12, weight: 12.0),
                workout: hybridUpper,
                order: order
            )
            hybridUpper.exercises.append(ex)
            order += 1
        }

        // Trizepsdrücken (Kabel): 3x12
        if let exercise = exercises["Trizepsdrücken am Kabel"] {
            let ex = WorkoutExerciseEntity(
                exerciseId: exercise.id,
                exercise: exercise,
                sets: createSets(count: 3, reps: 12, weight: 0),
                workout: hybridUpper,
                order: order
            )
            hybridUpper.exercises.append(ex)
            order += 1
        }

        hybridUpper.exerciseCount = hybridUpper.exercises.count
        workouts.append(hybridUpper)

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
