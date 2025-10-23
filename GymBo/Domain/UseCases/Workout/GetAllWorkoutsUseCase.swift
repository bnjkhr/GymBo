//
//  GetAllWorkoutsUseCase.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use Case for fetching all workout templates
///
/// **Responsibility:**
/// - Load all workout templates from repository
/// - Return sorted list (favorites first, then by name)
///
/// **Business Rules:**
/// - Returns empty array if no workouts exist
/// - Favorites are sorted to top
/// - Alphabetical sorting within groups
///
/// **Usage:**
/// ```swift
/// let useCase = DefaultGetAllWorkoutsUseCase(repository: repository)
/// let workouts = try await useCase.execute()
/// ```
protocol GetAllWorkoutsUseCase {
    /// Fetch all workout templates
    /// - Returns: Array of workouts (may be empty)
    /// - Throws: UseCaseError if fetch fails
    func execute() async throws -> [Workout]
}

// MARK: - Implementation

final class DefaultGetAllWorkoutsUseCase: GetAllWorkoutsUseCase {
    
    private let repository: WorkoutRepositoryProtocol
    
    init(repository: WorkoutRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute() async throws -> [Workout] {
        do {
            let workouts = try await repository.fetchAll()
            
            // Sort: Favorites first, then alphabetically
            return workouts.sorted { lhs, rhs in
                if lhs.isFavorite != rhs.isFavorite {
                    return lhs.isFavorite
                }
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            }
        } catch let error as WorkoutRepositoryError {
            throw UseCaseError.repositoryError(error)
        } catch {
            throw UseCaseError.unknownError(error)
        }
    }
}
