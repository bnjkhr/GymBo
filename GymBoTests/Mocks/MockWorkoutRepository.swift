//
//  MockWorkoutRepository.swift
//  GymBoTests
//
//  Created for testing purposes
//  Mock implementation of WorkoutRepositoryProtocol
//

import Foundation

@testable import GymBo

/// Mock implementation of WorkoutRepositoryProtocol for testing
final class MockWorkoutRepository: WorkoutRepositoryProtocol {

    // MARK: - Storage

    private var workouts: [UUID: Workout] = [:]
    private var folders: [UUID: WorkoutFolder] = [:]

    // MARK: - Call Tracking

    private(set) var saveCallCount = 0
    private(set) var updateCallCount = 0
    private(set) var deleteCallCount = 0
    private(set) var fetchCallCount = 0
    private(set) var fetchAllCallCount = 0
    private(set) var fetchByFolderCallCount = 0

    private(set) var lastSavedWorkout: Workout?
    private(set) var lastUpdatedWorkout: Workout?
    private(set) var lastDeletedId: UUID?
    private(set) var lastFetchedId: UUID?
    private(set) var lastFetchedFolderId: UUID?

    // MARK: - Error Injection

    var saveError: Error?
    var updateError: Error?
    var deleteError: Error?
    var fetchError: Error?
    var fetchAllError: Error?
    var fetchByFolderError: Error?

    // MARK: - Custom Behaviors

    var fetchAllResult: [Workout]?
    var fetchByFolderResult: [Workout]?

    // MARK: - WorkoutRepositoryProtocol Methods

    func save(_ workout: Workout) async throws {
        saveCallCount += 1
        lastSavedWorkout = workout

        if let error = saveError {
            throw error
        }

        workouts[workout.id] = workout
    }

    func update(_ workout: Workout) async throws {
        updateCallCount += 1
        lastUpdatedWorkout = workout

        if let error = updateError {
            throw error
        }

        guard workouts[workout.id] != nil else {
            throw RepositoryError.notFound(workout.id)
        }

        workouts[workout.id] = workout
    }

    func delete(id: UUID) async throws {
        deleteCallCount += 1
        lastDeletedId = id

        if let error = deleteError {
            throw error
        }

        guard workouts[id] != nil else {
            throw RepositoryError.notFound(id)
        }

        workouts.removeValue(forKey: id)
    }

    func fetch(id: UUID) async throws -> Workout? {
        fetchCallCount += 1
        lastFetchedId = id

        if let error = fetchError {
            throw error
        }

        return workouts[id]
    }

    func fetchAll() async throws -> [Workout] {
        fetchAllCallCount += 1

        if let error = fetchAllError {
            throw error
        }

        if let customResult = fetchAllResult {
            return customResult
        }

        return Array(workouts.values).sorted { $0.name < $1.name }
    }

    func fetchFavorites() async throws -> [Workout] {
        if let error = fetchAllError {
            throw error
        }

        return workouts.values.filter { $0.isFavorite }.sorted { $0.name < $1.name }
    }

    func search(query: String) async throws -> [Workout] {
        if let error = fetchAllError {
            throw error
        }

        return workouts.values
            .filter { $0.name.localizedCaseInsensitiveContains(query) }
            .sorted { $0.name < $1.name }
    }

    func deleteAll() async throws {
        if let error = deleteError {
            throw error
        }

        workouts.removeAll()
    }

    func updateExerciseOrder(workoutId: UUID, exerciseOrder: [UUID]) async throws {
        if let error = updateError {
            throw error
        }

        guard var workout = workouts[workoutId] else {
            throw RepositoryError.notFound(workoutId)
        }

        // Update exercise order
        var updatedExercises = workout.exercises
        for (newIndex, exerciseId) in exerciseOrder.enumerated() {
            if let exerciseIndex = updatedExercises.firstIndex(where: {
                $0.exerciseId == exerciseId
            }) {
                updatedExercises[exerciseIndex].orderIndex = newIndex
            }
        }
        workout.exercises = updatedExercises.sorted {
            (ex1: WorkoutExercise, ex2: WorkoutExercise) -> Bool in
            ex1.orderIndex < ex2.orderIndex
        }
        workouts[workoutId] = workout
    }

    func fetchAllFolders() async throws -> [WorkoutFolder] {
        return Array(folders.values).sorted { (f1: WorkoutFolder, f2: WorkoutFolder) -> Bool in
            f1.order < f2.order
        }
    }

    func createFolder(_ folder: WorkoutFolder) async throws {
        folders[folder.id] = folder
    }

    func updateFolder(_ folder: WorkoutFolder) async throws {
        guard folders[folder.id] != nil else {
            throw RepositoryError.notFound(folder.id)
        }
        folders[folder.id] = folder
    }

    func deleteFolder(id: UUID) async throws {
        guard folders[id] != nil else {
            throw RepositoryError.notFound(id)
        }

        // Remove folder reference from workouts
        for (workoutId, var workout) in workouts where workout.folderId == id {
            workout.folderId = nil
            workouts[workoutId] = workout
        }

        folders.removeValue(forKey: id)
    }

    func moveWorkoutToFolder(workoutId: UUID, folderId: UUID?) async throws {
        guard var workout = workouts[workoutId] else {
            throw RepositoryError.notFound(workoutId)
        }

        workout.folderId = folderId
        workouts[workoutId] = workout
    }

    // MARK: - Test Helper Methods

    func reset() {
        saveCallCount = 0
        updateCallCount = 0
        deleteCallCount = 0
        fetchCallCount = 0
        fetchAllCallCount = 0
        fetchByFolderCallCount = 0

        lastSavedWorkout = nil
        lastUpdatedWorkout = nil
        lastDeletedId = nil
        lastFetchedId = nil
        lastFetchedFolderId = nil

        saveError = nil
        updateError = nil
        deleteError = nil
        fetchError = nil
        fetchAllError = nil
        fetchByFolderError = nil

        fetchAllResult = nil
        fetchByFolderResult = nil

        workouts.removeAll()
        folders.removeAll()
    }

    func addWorkout(_ workout: Workout) {
        workouts[workout.id] = workout
    }

    func addFolder(_ folder: WorkoutFolder) {
        folders[folder.id] = folder
    }

    func getAllWorkouts() -> [Workout] {
        Array(workouts.values)
    }

    func getAllFolders() -> [WorkoutFolder] {
        Array(folders.values)
    }

    func hasWorkout(id: UUID) -> Bool {
        workouts[id] != nil
    }
}
