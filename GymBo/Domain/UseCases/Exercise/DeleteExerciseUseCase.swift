//
//  DeleteExerciseUseCase.swift
//  GymBo
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for deleting a custom exercise
///
/// **Business Rules:**
/// - Can only delete custom exercises (created by user)
/// - Cannot delete built-in exercises from catalog
/// - Exercise must exist
protocol DeleteExerciseUseCaseProtocol {
    /// Delete an exercise
    /// - Parameter exerciseId: ID of exercise to delete
    /// - Throws: DeleteExerciseError if validation fails or deletion fails
    func execute(exerciseId: UUID) async throws
}

/// Default implementation of DeleteExerciseUseCase
final class DefaultDeleteExerciseUseCase: DeleteExerciseUseCaseProtocol {

    private let exerciseRepository: ExerciseRepositoryProtocol

    init(exerciseRepository: ExerciseRepositoryProtocol) {
        self.exerciseRepository = exerciseRepository
    }

    func execute(exerciseId: UUID) async throws {
        // Fetch exercise to verify it exists and is deletable
        guard let exercise = try await exerciseRepository.fetch(id: exerciseId) else {
            throw DeleteExerciseError.exerciseNotFound
        }

        // Check if it's a custom exercise (has createdAt date)
        // Built-in exercises don't have createdAt set by seed data
        guard exercise.createdAt != nil else {
            throw DeleteExerciseError.cannotDeleteBuiltIn
        }

        // Delete the exercise
        try await exerciseRepository.delete(exerciseId: exerciseId)

        print("✅ UseCase: Deleted exercise \(exercise.name)")
    }
}

// MARK: - Errors

enum DeleteExerciseError: LocalizedError {
    case exerciseNotFound
    case cannotDeleteBuiltIn

    var errorDescription: String? {
        switch self {
        case .exerciseNotFound:
            return "Übung nicht gefunden"
        case .cannotDeleteBuiltIn:
            return "Vordefinierte Übungen können nicht gelöscht werden"
        }
    }
}
