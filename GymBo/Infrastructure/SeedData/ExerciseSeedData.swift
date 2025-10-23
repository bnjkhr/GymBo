//
//  ExerciseSeedData.swift
//  GymBo
//
//  Created on 2025-10-23.
//

import Foundation
import SwiftData

/// Seeds the database with test exercises for development
struct ExerciseSeedData {

    /// Seed test exercises into the database
    static func seedIfNeeded(context: ModelContext) {
        // Check if exercises already exist
        let descriptor = FetchDescriptor<ExerciseEntity>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        if existingCount > 0 {
            print("📊 Exercises already seeded (\(existingCount) exercises)")
            return
        }

        print("🌱 Seeding test exercises...")

        // Create test exercises
        let exercises = createTestExercises()

        for exercise in exercises {
            context.insert(exercise)
        }

        do {
            try context.save()
            print("✅ Seeded \(exercises.count) test exercises")
        } catch {
            print("❌ Failed to seed exercises: \(error)")
        }
    }

    private static func createTestExercises() -> [ExerciseEntity] {
        return [
            ExerciseEntity(
                name: "Bankdrücken",
                muscleGroupsRaw: ["Brust", "Trizeps", "Schultern"],
                equipmentTypeRaw: "barbell",
                difficultyLevelRaw: "Fortgeschritten",
                descriptionText: "Klassische Brustübung mit Langhantel",
                instructions: [
                    "Auf Bank legen, Füße fest am Boden",
                    "Hantel mit schulterbreitem Griff",
                    "Kontrolliert zur Brust senken",
                    "Explosiv nach oben drücken",
                ],
                lastUsedWeight: 100.0,
                lastUsedReps: 8
            ),
            ExerciseEntity(
                name: "Lat Pulldown",
                muscleGroupsRaw: ["Rücken", "Bizeps"],
                equipmentTypeRaw: "cable",
                difficultyLevelRaw: "Anfänger",
                descriptionText: "Kabelzug für breiten Rücken",
                instructions: [
                    "Aufrecht sitzen, Knie fixiert",
                    "Breiter Griff an der Stange",
                    "Zur Brust ziehen",
                    "Kontrolliert zurück",
                ],
                lastUsedWeight: 80.0,
                lastUsedReps: 10
            ),
            ExerciseEntity(
                name: "Kniebeugen",
                muscleGroupsRaw: ["Beine", "Gesäß", "Core"],
                equipmentTypeRaw: "barbell",
                difficultyLevelRaw: "Fortgeschritten",
                descriptionText: "King of exercises - Langhantel Kniebeugen",
                instructions: [
                    "Hantel auf oberem Rücken",
                    "Schulterbreiter Stand",
                    "Tief beugen (90°+)",
                    "Explosiv hochdrücken",
                ],
                lastUsedWeight: 60.0,
                lastUsedReps: 12
            ),
        ]
    }
}
