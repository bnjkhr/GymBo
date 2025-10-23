//
//  GetWorkoutByIdUseCase.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use Case for fetching a specific workout template by ID
///
/// **Responsibility:**
/// - Load workout template from repository
/// - Validate workout exists
///
/// **Business Rules:**
/// - Throws error if workout not found
///
/// **Usage:**
/// ```swift
/// let useCase = DefaultGetWorkoutByIdUseCase(repository: repository)
/// let workout = try await useCase.execute(id: workoutId)
/// ```
protocol GetWorkoutByIdUseCase {
    /// Fetch a workout by ID
    /// - Parameter id: Workout unique identifier
    /// - Returns: The workout
    /// - Throws: UseCaseError if workout not found or fetch fails
    func execute(id: UUID) async throws -> Workout
}

// MARK: - Implementation

final class DefaultGetWorkoutByIdUseCase: GetWorkoutByIdUseCase {
    
    private let repository: WorkoutRepositoryProtocol
    
    init(repository: WorkoutRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(id: UUID) async throws -> Workout {
        do {
            guard let workout = try await repository.fetch(id: id) else {
                throw UseCaseError.workoutNotFound(id)
            }
            return workout
        } catch let error as WorkoutRepositoryError {
            throw UseCaseError.repositoryError(error)
        } catch let error as UseCaseError {
            throw error
        } catch {
            throw UseCaseError.unknownError(error)
        }
    }
}
