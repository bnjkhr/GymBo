//
//  WorkoutRepositoryProtocol.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Repository protocol for workout template operations
///
/// **Design Principles:**
/// - Pure protocol in Domain layer - No implementation details
/// - Async/await for all operations
/// - Throws for error handling
/// - Returns Domain entities only (Workout, not WorkoutEntity)
///
/// **Implementation:**
/// - Will be implemented by `SwiftDataWorkoutRepository` in Data layer
/// - Can be mocked for testing Use Cases
///
/// **Usage:**
/// ```swift
/// let repository: WorkoutRepositoryProtocol = SwiftDataWorkoutRepository(...)
/// let workouts = try await repository.fetchAll()
/// ```
protocol WorkoutRepositoryProtocol {

    // MARK: - Create & Update

    /// Save a new workout template
    /// - Parameter workout: The workout to save
    /// - Throws: WorkoutRepositoryError if save fails
    func save(_ workout: Workout) async throws

    /// Update an existing workout template
    /// - Parameter workout: The workout with updated data
    /// - Throws: WorkoutRepositoryError if update fails or workout not found
    func update(_ workout: Workout) async throws

    /// Update exercise order in a workout (without recreating exercises)
    /// - Parameters:
    ///   - workoutId: ID of the workout
    ///   - exerciseOrder: Array of exercise IDs in desired order
    /// - Throws: WorkoutRepositoryError if update fails
    func updateExerciseOrder(workoutId: UUID, exerciseOrder: [UUID]) async throws

    // MARK: - Read

    /// Fetch a workout by ID
    /// - Parameter id: The workout's unique identifier
    /// - Returns: The workout if found, nil otherwise
    /// - Throws: WorkoutRepositoryError if fetch fails
    func fetch(id: UUID) async throws -> Workout?

    /// Fetch all workout templates
    /// - Returns: Array of all workouts, sorted by creation date
    /// - Throws: WorkoutRepositoryError if fetch fails
    func fetchAll() async throws -> [Workout]

    /// Fetch favorite workouts
    /// - Returns: Array of favorite workouts
    /// - Throws: WorkoutRepositoryError if fetch fails
    func fetchFavorites() async throws -> [Workout]

    /// Search workouts by name
    /// - Parameter query: Search query string
    /// - Returns: Array of matching workouts
    /// - Throws: WorkoutRepositoryError if fetch fails
    func search(query: String) async throws -> [Workout]

    // MARK: - Delete

    /// Delete a workout by ID
    /// - Parameter id: The workout's unique identifier
    /// - Throws: WorkoutRepositoryError if delete fails
    func delete(id: UUID) async throws

    /// Delete all workouts (use with caution!)
    /// - Throws: WorkoutRepositoryError if delete fails
    func deleteAll() async throws
}

// MARK: - Repository Errors

/// Errors that can occur during workout repository operations
enum WorkoutRepositoryError: Error, LocalizedError {
    /// Workout with given ID was not found
    case workoutNotFound(UUID)

    /// Failed to save workout to persistence
    case saveFailed(Error)

    /// Failed to update workout in persistence
    case updateFailed(Error)

    /// Failed to fetch workout from persistence
    case fetchFailed(Error)

    /// Failed to delete workout from persistence
    case deleteFailed(Error)

    /// Invalid workout data (e.g., empty name, no exercises)
    case invalidData(String)

    var errorDescription: String? {
        switch self {
        case .workoutNotFound(let id):
            return "Workout with ID \(id.uuidString) not found"
        case .saveFailed(let error):
            return "Failed to save workout: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update workout: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch workout: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete workout: \(error.localizedDescription)"
        case .invalidData(let message):
            return "Invalid workout data: \(message)"
        }
    }
}

// MARK: - Mock Implementation (for Testing)

#if DEBUG
    /// Mock implementation of WorkoutRepositoryProtocol for testing
    final class MockWorkoutRepository: WorkoutRepositoryProtocol {

        /// In-memory storage
        private var workouts: [UUID: Workout] = [:]

        /// Flag to simulate errors (for testing error handling)
        var shouldThrowError: Bool = false

        /// Error to throw when shouldThrowError is true
        var errorToThrow: WorkoutRepositoryError = .fetchFailed(NSError(domain: "Mock", code: -1))

        func save(_ workout: Workout) async throws {
            if shouldThrowError { throw errorToThrow }
            workouts[workout.id] = workout
        }

        func update(_ workout: Workout) async throws {
            if shouldThrowError { throw errorToThrow }
            guard workouts[workout.id] != nil else {
                throw WorkoutRepositoryError.workoutNotFound(workout.id)
            }
            workouts[workout.id] = workout
        }

        func fetch(id: UUID) async throws -> Workout? {
            if shouldThrowError { throw errorToThrow }
            return workouts[id]
        }

        func fetchAll() async throws -> [Workout] {
            if shouldThrowError { throw errorToThrow }
            return workouts.values.sorted { $0.createdAt < $1.createdAt }
        }

        func fetchFavorites() async throws -> [Workout] {
            if shouldThrowError { throw errorToThrow }
            return workouts.values.filter { $0.isFavorite }
        }

        func search(query: String) async throws -> [Workout] {
            if shouldThrowError { throw errorToThrow }
            return workouts.values.filter {
                $0.name.localizedCaseInsensitiveContains(query)
            }
        }

        func delete(id: UUID) async throws {
            if shouldThrowError { throw errorToThrow }
            workouts.removeValue(forKey: id)
        }

        func deleteAll() async throws {
            if shouldThrowError { throw errorToThrow }
            workouts.removeAll()
        }

        func updateExerciseOrder(workoutId: UUID, exerciseOrder: [UUID]) async throws {
            if shouldThrowError { throw errorToThrow }
            guard var workout = workouts[workoutId] else {
                throw WorkoutRepositoryError.workoutNotFound(workoutId)
            }

            // Update exercise order in the domain model
            var updatedExercises = workout.exercises
            for (newIndex, exerciseId) in exerciseOrder.enumerated() {
                if let exerciseIndex = updatedExercises.firstIndex(where: {
                    $0.exerciseId == exerciseId
                }) {
                    updatedExercises[exerciseIndex].orderIndex = newIndex
                }
            }
            workout.exercises = updatedExercises.sorted { $0.orderIndex < $1.orderIndex }
            workouts[workoutId] = workout
        }

        /// Reset the mock repository (useful between tests)
        func reset() {
            workouts.removeAll()
            shouldThrowError = false
        }

        /// Seed with sample workouts for testing
        func seedSampleWorkouts() {
            let pushDay = Workout(
                name: "Push Day",
                exercises: [],
                isFavorite: true
            )
            let pullDay = Workout(
                name: "Pull Day",
                exercises: []
            )
            let legDay = Workout(
                name: "Leg Day",
                exercises: [],
                isFavorite: true
            )

            workouts[pushDay.id] = pushDay
            workouts[pullDay.id] = pullDay
            workouts[legDay.id] = legDay
        }
    }
#endif
