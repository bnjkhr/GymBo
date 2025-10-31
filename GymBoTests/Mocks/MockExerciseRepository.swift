//
//  MockExerciseRepository.swift
//  GymBoTests
//
//  Created for testing purposes
//  Mock implementation of ExerciseRepositoryProtocol
//

import Foundation

@testable import GymBo

/// Mock implementation of ExerciseRepositoryProtocol for testing
final class MockExerciseRepository: ExerciseRepositoryProtocol {

    // MARK: - Storage

    private var exercises: [UUID: ExerciseEntity] = [:]

    // MARK: - Call Tracking

    private(set) var saveCallCount = 0
    private(set) var updateCallCount = 0
    private(set) var deleteCallCount = 0
    private(set) var fetchCallCount = 0
    private(set) var fetchAllCallCount = 0
    private(set) var updateLastUsedValuesCallCount = 0

    private(set) var lastSavedExercise: ExerciseEntity?
    private(set) var lastUpdatedExercise: ExerciseEntity?
    private(set) var lastDeletedId: UUID?
    private(set) var lastFetchedId: UUID?
    private(set) var lastUpdatedExerciseId: UUID?
    private(set) var lastUpdatedWeight: Double?
    private(set) var lastUpdatedReps: Int?

    // MARK: - Error Injection

    var createError: Error?
    var deleteError: Error?
    var fetchError: Error?
    var fetchAllError: Error?
    var updateLastUsedValuesError: Error?
    var findByNameError: Error?

    // MARK: - Custom Behaviors

    var fetchAllResult: [ExerciseEntity]?

    // MARK: - ExerciseRepositoryProtocol Methods

    func fetch(id: UUID) async throws -> ExerciseEntity? {
        fetchCallCount += 1
        lastFetchedId = id

        if let error = fetchError {
            throw error
        }

        return exercises[id]
    }

    func updateLastUsed(exerciseId: UUID, weight: Double, reps: Int, date: Date) async throws {
        updateLastUsedValuesCallCount += 1
        lastUpdatedExerciseId = exerciseId
        lastUpdatedWeight = weight
        lastUpdatedReps = reps

        if let error = updateLastUsedValuesError {
            throw error
        }

        guard var exercise = exercises[exerciseId] else {
            throw RepositoryError.notFound(exerciseId)
        }

        exercise.lastUsedWeight = weight
        exercise.lastUsedReps = reps
        exercise.lastUsedDate = date
        exercises[exerciseId] = exercise
    }

    func findByName(_ name: String) async throws -> UUID? {
        if let error = findByNameError {
            throw error
        }

        return exercises.values.first { $0.name == name }?.id
    }

    func fetchAll() async throws -> [ExerciseEntity] {
        fetchAllCallCount += 1

        if let error = fetchAllError {
            throw error
        }

        if let customResult = fetchAllResult {
            return customResult
        }

        return Array(exercises.values).sorted { $0.name < $1.name }
    }

    func create(
        name: String,
        muscleGroups: [String],
        equipment: String,
        difficulty: String,
        description: String,
        instructions: [String]
    ) async throws -> ExerciseEntity {
        saveCallCount += 1

        if let error = createError {
            throw error
        }

        let exercise = ExerciseEntity(
            name: name,
            muscleGroupsRaw: muscleGroups,
            equipmentTypeRaw: equipment,
            difficultyLevelRaw: difficulty,
            descriptionText: description,
            instructions: instructions
        )

        exercises[exercise.id] = exercise
        lastSavedExercise = exercise
        return exercise
    }

    func delete(exerciseId: UUID) async throws {
        deleteCallCount += 1
        lastDeletedId = exerciseId

        if let error = deleteError {
            throw error
        }

        guard exercises[exerciseId] != nil else {
            throw RepositoryError.notFound(exerciseId)
        }

        exercises.removeValue(forKey: exerciseId)
    }

    // MARK: - Test Helper Methods

    func reset() {
        saveCallCount = 0
        updateCallCount = 0
        deleteCallCount = 0
        fetchCallCount = 0
        fetchAllCallCount = 0
        updateLastUsedValuesCallCount = 0

        lastSavedExercise = nil
        lastUpdatedExercise = nil
        lastDeletedId = nil
        lastFetchedId = nil
        lastUpdatedExerciseId = nil
        lastUpdatedWeight = nil
        lastUpdatedReps = nil

        createError = nil
        deleteError = nil
        fetchError = nil
        fetchAllError = nil
        updateLastUsedValuesError = nil
        findByNameError = nil

        fetchAllResult = nil

        exercises.removeAll()
    }

    func addExercise(_ exercise: ExerciseEntity) {
        exercises[exercise.id] = exercise
    }

    func getAllExercises() -> [ExerciseEntity] {
        Array(exercises.values)
    }

    func hasExercise(id: UUID) -> Bool {
        exercises[id] != nil
    }
}
