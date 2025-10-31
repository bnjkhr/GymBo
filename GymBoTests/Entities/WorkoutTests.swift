//
//  WorkoutTests.swift
//  GymBoTests
//
//  Comprehensive tests for Workout entity
//

import XCTest

@testable import GymBo

final class WorkoutTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_WithBasicValues_CreatesWorkout() {
        // Given/When: Creating a workout
        let workout = Workout(
            name: "Push Day",
            exercises: [],
            defaultRestTime: 90,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date(),
            isFavorite: false
        )

        // Then: Should have correct values
        XCTAssertEqual(workout.name, "Push Day")
        XCTAssertEqual(workout.exercises.count, 0)
        XCTAssertEqual(workout.defaultRestTime, 90)
        XCTAssertNil(workout.notes)
        XCTAssertFalse(workout.isFavorite)
        XCTAssertNotNil(workout.id)
        XCTAssertNotNil(workout.createdAt)
        XCTAssertNotNil(workout.updatedAt)
    }

    func testInit_WithExercises_StoresExercises() {
        // Given: Exercises
        let exercises = [
            TestDataFactory.createWorkoutExercise(orderIndex: 0),
            TestDataFactory.createWorkoutExercise(orderIndex: 1),
            TestDataFactory.createWorkoutExercise(orderIndex: 2),
        ]

        // When: Creating workout
        let workout = Workout(
            name: "Test",
            exercises: exercises,
            defaultRestTime: 90,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date(),
            isFavorite: false
        )

        // Then: Should store exercises
        XCTAssertEqual(workout.exercises.count, 3)
        XCTAssertEqual(workout.exercises[0].orderIndex, 0)
        XCTAssertEqual(workout.exercises[1].orderIndex, 1)
        XCTAssertEqual(workout.exercises[2].orderIndex, 2)
    }

    func testInit_WithNotes_StoresNotes() {
        // Given/When: Creating workout with notes
        let workout = Workout(
            name: "Test",
            exercises: [],
            defaultRestTime: 90,
            notes: "Important workout notes",
            createdAt: Date(),
            updatedAt: Date(),
            isFavorite: false
        )

        // Then: Should store notes
        XCTAssertEqual(workout.notes, "Important workout notes")
    }

    func testInit_WithFavoriteFlag_SetsFavorite() {
        // Given/When: Creating favorite workout
        let workout = Workout(
            name: "Test",
            exercises: [],
            defaultRestTime: 90,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date(),
            isFavorite: true
        )

        // Then: Should be favorite
        XCTAssertTrue(workout.isFavorite)
    }

    // MARK: - Workout Type Tests

    func testInit_WithDefaultType_IsStandard() {
        // Given/When: Creating workout without specifying type
        let workout = TestDataFactory.createWorkout()

        // Then: Should be standard type
        XCTAssertEqual(workout.workoutType, .standard)
    }

    func testInit_WithSupersetType_IsSupersetType() {
        // Given/When: Creating superset workout
        let workout = TestDataFactory.createWorkout(workoutType: .superset)

        // Then: Should be superset type
        XCTAssertEqual(workout.workoutType, .superset)
    }

    func testInit_WithCircuitType_IsCircuit() {
        // Given/When: Creating circuit workout
        let workout = TestDataFactory.createWorkout(workoutType: .circuit)

        // Then: Should be circuit type
        XCTAssertEqual(workout.workoutType, .circuit)
    }

    // MARK: - Exercise Groups Tests

    func testInit_WithExerciseGroups_StoresGroups() {
        // Given: Exercise groups with exercises
        let exercise1 = TestDataFactory.createWorkoutExercise(orderIndex: 0)
        let exercise2 = TestDataFactory.createWorkoutExercise(orderIndex: 1)
        let exercise3 = TestDataFactory.createWorkoutExercise(orderIndex: 2)

        let groups = [
            TestDataFactory.createExerciseGroup(exercises: [exercise1], groupIndex: 0),
            TestDataFactory.createExerciseGroup(exercises: [exercise2, exercise3], groupIndex: 1),
        ]

        // When: Creating workout with groups
        let workout = TestDataFactory.createWorkout(
            workoutType: .superset,
            exerciseGroups: groups
        )

        // Then: Should store groups
        XCTAssertNotNil(workout.exerciseGroups)
        XCTAssertEqual(workout.exerciseGroups?.count, 2)
        XCTAssertEqual(workout.exerciseGroups?[0].exercises.count, 1)
        XCTAssertEqual(workout.exerciseGroups?[1].exercises.count, 2)
    }

    // MARK: - Folder Tests

    func testInit_WithFolder_StoresFolderId() {
        // Given/When: Creating workout in folder
        let folderId = UUID()
        let workout = TestDataFactory.createWorkout(folderId: folderId)

        // Then: Should store folder ID
        XCTAssertEqual(workout.folderId, folderId)
    }

    func testInit_WithoutFolder_HasNilFolderId() {
        // Given/When: Creating workout without folder
        let workout = TestDataFactory.createWorkout()

        // Then: Folder ID should be nil
        XCTAssertNil(workout.folderId)
    }

    // MARK: - Value Type Semantics Tests

    func testValueType_CopyDoesNotAffectOriginal() {
        // Given: An original workout
        var original = TestDataFactory.createWorkout(name: "Original", isFavorite: false)

        // When: Creating a copy and modifying it
        var copy = original
        copy.name = "Modified"
        copy.isFavorite = true

        // Then: Original should be unchanged
        XCTAssertEqual(original.name, "Original")
        XCTAssertFalse(original.isFavorite)

        // Copy should be modified
        XCTAssertEqual(copy.name, "Modified")
        XCTAssertTrue(copy.isFavorite)
    }

    // MARK: - Equatable Tests

    func testEquatable_WithSameId_AreEqual() {
        // Given: Two workouts with same ID
        let id = UUID()
        let workout1 = TestDataFactory.createWorkout(id: id, name: "Workout 1")
        let workout2 = TestDataFactory.createWorkout(id: id, name: "Workout 2")

        // When/Then: Should be equal (based on ID)
        XCTAssertEqual(workout1, workout2)
    }

    func testEquatable_WithDifferentIds_AreNotEqual() {
        // Given: Two workouts with different IDs
        let workout1 = TestDataFactory.createWorkout(name: "Workout")
        let workout2 = TestDataFactory.createWorkout(name: "Workout")

        // When/Then: Should not be equal
        XCTAssertNotEqual(workout1, workout2)
    }

    // MARK: - Hashable Tests

    func testHashable_CanBeUsedInSet() {
        // Given: Multiple workouts
        let workout1 = TestDataFactory.createWorkout(name: "A")
        let workout2 = TestDataFactory.createWorkout(name: "B")
        let workout3 = workout1  // Same ID

        // When: Adding to Set
        let workoutSet: Set<Workout> = [workout1, workout2, workout3]

        // Then: Should only contain unique workouts
        XCTAssertEqual(workoutSet.count, 2)
    }

    func testHashable_CanBeUsedInDictionary() {
        // Given: Workouts as keys
        let workout1 = TestDataFactory.createWorkout()
        let workout2 = TestDataFactory.createWorkout()

        // When: Creating dictionary
        var dictionary: [Workout: String] = [:]
        dictionary[workout1] = "Value 1"
        dictionary[workout2] = "Value 2"

        // Then: Should work as keys
        XCTAssertEqual(dictionary.count, 2)
        XCTAssertEqual(dictionary[workout1], "Value 1")
        XCTAssertEqual(dictionary[workout2], "Value 2")
    }

    // MARK: - Edge Cases

    func testInit_WithEmptyName_IsValid() {
        // Given/When: Creating workout with empty name (validation happens in use case)
        let workout = TestDataFactory.createWorkout(name: "")

        // Then: Should be valid (entity doesn't validate)
        XCTAssertEqual(workout.name, "")
    }

    func testInit_WithLongName_IsValid() {
        // Given/When: Creating workout with very long name
        let longName = String(repeating: "A", count: 500)
        let workout = TestDataFactory.createWorkout(name: longName)

        // Then: Should be valid
        XCTAssertEqual(workout.name.count, 500)
    }

    func testInit_WithSpecialCharacters_PreservesCharacters() {
        // Given/When: Creating workout with special characters
        let name = "Push Day 💪 (Upper Body) #1"
        let workout = TestDataFactory.createWorkout(name: name)

        // Then: Should preserve special characters
        XCTAssertEqual(workout.name, name)
    }

    func testInit_WithZeroRestTime_IsValid() {
        // Given/When: Creating workout with zero rest time
        let workout = TestDataFactory.createWorkout(defaultRestTime: 0)

        // Then: Should be valid (validation happens in use case)
        XCTAssertEqual(workout.defaultRestTime, 0)
    }

    func testInit_WithVeryLongRestTime_IsValid() {
        // Given/When: Creating workout with very long rest time
        let workout = TestDataFactory.createWorkout(defaultRestTime: 600)

        // Then: Should be valid
        XCTAssertEqual(workout.defaultRestTime, 600)
    }

    func testInit_WithManyExercises_StoresAll() {
        // Given: Many exercises
        let exercises = (0..<50).map { index in
            TestDataFactory.createWorkoutExercise(orderIndex: index)
        }

        // When: Creating workout
        let workout = TestDataFactory.createWorkout(exercises: exercises)

        // Then: Should store all exercises
        XCTAssertEqual(workout.exercises.count, 50)
    }

    func testInit_CreatedAndUpdatedDates_CanBeDifferent() {
        // Given: Different dates
        let createdDate = Date().addingTimeInterval(-86400)  // 1 day ago
        let updatedDate = Date()

        // When: Creating workout
        let workout = Workout(
            name: "Test",
            exercises: [],
            defaultRestTime: 90,
            notes: nil,
            createdAt: createdDate,
            updatedAt: updatedDate,
            isFavorite: false
        )

        // Then: Should store both dates correctly
        XCTAssertEqual(workout.createdAt, createdDate)
        XCTAssertEqual(workout.updatedAt, updatedDate)
        XCTAssertGreaterThan(workout.updatedAt, workout.createdAt)
    }
}
