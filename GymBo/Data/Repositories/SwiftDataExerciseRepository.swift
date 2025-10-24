//
//  SwiftDataExerciseRepository.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Data Layer
//

import Foundation
import SwiftData

/// SwiftData implementation of ExerciseRepositoryProtocol
///
/// **Responsibility:**
/// - Update lastUsed values in ExerciseEntity
/// - Fetch exercises from SwiftData
@MainActor
final class SwiftDataExerciseRepository: ExerciseRepositoryProtocol {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetch(id: UUID) async throws -> ExerciseEntity? {
        let descriptor = FetchDescriptor<ExerciseEntity>(
            predicate: #Predicate<ExerciseEntity> { entity in
                entity.id == id
            }
        )

        return try modelContext.fetch(descriptor).first
    }

    func updateLastUsed(
        exerciseId: UUID,
        weight: Double,
        reps: Int,
        date: Date
    ) async throws {

        // Fetch exercise
        let descriptor = FetchDescriptor<ExerciseEntity>(
            predicate: #Predicate<ExerciseEntity> { entity in
                entity.id == exerciseId
            }
        )

        guard let exercise = try modelContext.fetch(descriptor).first else {
            print("⚠️ Exercise not found: \(exerciseId)")
            return  // Silently ignore if exercise doesn't exist (may be test data)
        }

        // Update last used values
        exercise.lastUsedWeight = weight
        exercise.lastUsedReps = reps
        exercise.lastUsedDate = date

        // Save
        try modelContext.save()

        print("✅ Updated exercise \(exercise.name): lastWeight=\(weight), lastReps=\(reps)")
    }

    func findByName(_ name: String) async throws -> UUID? {
        let descriptor = FetchDescriptor<ExerciseEntity>(
            predicate: #Predicate<ExerciseEntity> { entity in
                entity.name == name
            }
        )

        return try modelContext.fetch(descriptor).first?.id
    }

    func fetchAll() async throws -> [ExerciseEntity] {
        let descriptor = FetchDescriptor<ExerciseEntity>(
            sortBy: [SortDescriptor(\.name)]
        )

        return try modelContext.fetch(descriptor)
    }

    func create(
        name: String,
        muscleGroups: [String],
        equipment: String,
        difficulty: String,
        description: String,
        instructions: [String]
    ) async throws -> ExerciseEntity {
        // Create new exercise entity
        let exercise = ExerciseEntity(
            name: name,
            muscleGroupsRaw: muscleGroups,
            equipmentTypeRaw: equipment,
            difficultyLevelRaw: difficulty,
            descriptionText: description,
            instructions: instructions,
            createdAt: Date()
        )

        // Insert into context
        modelContext.insert(exercise)

        // Save
        try modelContext.save()

        print("✅ Created custom exercise: \(name)")

        return exercise
    }

    func delete(exerciseId: UUID) async throws {
        // Fetch exercise
        let descriptor = FetchDescriptor<ExerciseEntity>(
            predicate: #Predicate<ExerciseEntity> { entity in
                entity.id == exerciseId
            }
        )

        guard let exercise = try modelContext.fetch(descriptor).first else {
            print("⚠️ Exercise not found: \(exerciseId)")
            return  // Silently ignore if exercise doesn't exist
        }

        // Delete from context
        modelContext.delete(exercise)

        // Save
        try modelContext.save()

        print("✅ Deleted exercise: \(exercise.name)")
    }
}
