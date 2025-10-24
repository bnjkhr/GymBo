//
//  CreateExerciseUseCase.swift
//  GymBo
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for creating a custom exercise
///
/// **Responsibility:**
/// - Validate exercise data
/// - Create new exercise via repository
/// - Return created exercise
///
/// **Business Rules:**
/// - Name must not be empty
/// - At least one muscle group must be selected
/// - Equipment type must be specified
protocol CreateExerciseUseCase {
    func execute(
        name: String,
        muscleGroups: [String],
        equipment: String,
        difficulty: String,
        description: String,
        instructions: [String]
    ) async throws -> ExerciseEntity
}

// MARK: - Default Implementation

final class DefaultCreateExerciseUseCase: CreateExerciseUseCase {

    private let exerciseRepository: ExerciseRepositoryProtocol

    init(exerciseRepository: ExerciseRepositoryProtocol) {
        self.exerciseRepository = exerciseRepository
    }

    func execute(
        name: String,
        muscleGroups: [String],
        equipment: String,
        difficulty: String,
        description: String,
        instructions: [String]
    ) async throws -> ExerciseEntity {

        // Validation
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CreateExerciseError.emptyName
        }

        guard !muscleGroups.isEmpty else {
            throw CreateExerciseError.noMuscleGroups
        }

        guard !equipment.isEmpty else {
            throw CreateExerciseError.noEquipment
        }

        // Create exercise via repository
        return try await exerciseRepository.create(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            muscleGroups: muscleGroups,
            equipment: equipment,
            difficulty: difficulty.isEmpty ? "Anfänger" : difficulty,
            description: description,
            instructions: instructions
        )
    }
}

// MARK: - Errors

enum CreateExerciseError: LocalizedError {
    case emptyName
    case noMuscleGroups
    case noEquipment

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Der Name darf nicht leer sein"
        case .noMuscleGroups:
            return "Wähle mindestens eine Muskelgruppe aus"
        case .noEquipment:
            return "Wähle ein Equipment aus"
        }
    }
}
