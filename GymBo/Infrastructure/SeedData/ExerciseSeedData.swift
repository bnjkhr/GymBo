//
//  ExerciseSeedData.swift
//  GymBo
//
//  Created on 2025-10-23.
//

import Foundation
import SwiftData

/// Seeds the database with all 145 predefined exercises from CSV
struct ExerciseSeedData {

    /// Seed exercises into the database
    static func seedIfNeeded(context: ModelContext) {
        // Check if exercises already exist
        let descriptor = FetchDescriptor<ExerciseEntity>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        if existingCount > 0 {
            print("📊 Exercises already seeded (\(existingCount) exercises)")
            return
        }

        print("🌱 Seeding exercises from CSV...")

        // Parse CSV and create exercises
        guard let exercises = parseExercisesFromCSV() else {
            print("❌ Failed to parse exercises CSV")
            return
        }

        for exercise in exercises {
            context.insert(exercise)
        }

        do {
            try context.save()
            print("✅ Seeded \(exercises.count) exercises")
        } catch {
            print("❌ Failed to seed exercises: \(error)")
        }
    }

    /// Parse exercises from embedded CSV file
    private static func parseExercisesFromCSV() -> [ExerciseEntity]? {
        guard let csvPath = Bundle.main.path(forResource: "exercises_with_ids", ofType: "csv"),
            let csvContent = try? String(contentsOfFile: csvPath, encoding: .utf8)
        else {
            print("❌ Could not load exercises_with_ids.csv")
            return nil
        }

        var exercises: [ExerciseEntity] = []
        let lines = csvContent.components(separatedBy: .newlines)

        // Skip header line and empty lines
        for line in lines.dropFirst() where !line.isEmpty {
            guard let exercise = parseCSVLine(line) else {
                continue
            }
            exercises.append(exercise)
        }

        return exercises
    }

    /// Parse a single CSV line into ExerciseEntity
    private static func parseCSVLine(_ line: String) -> ExerciseEntity? {
        let columns = line.components(separatedBy: ",")

        guard columns.count >= 10 else {
            print("⚠️ Invalid CSV line (not enough columns): \(line)")
            return nil
        }

        // Parse fields
        let name = columns[1]
        let muscleGroups = columns[2].components(separatedBy: ";")
        let equipmentType = columns[3]
        let difficultyLevel = columns[4]
        let description = columns[5]

        // Parse instructions (up to 4)
        var instructions: [String] = []
        for i in 6..<10 {
            if i < columns.count && !columns[i].isEmpty {
                instructions.append(columns[i])
            }
        }

        return ExerciseEntity(
            name: name,
            muscleGroupsRaw: muscleGroups,
            equipmentTypeRaw: equipmentType,
            difficultyLevelRaw: difficultyLevel,
            descriptionText: description,
            instructions: instructions,
            lastUsedWeight: nil,
            lastUsedReps: nil,
            lastUsedSetCount: nil,
            lastUsedDate: nil,
            lastUsedRestTime: nil
        )
    }
}
