//
//  CreateWorkoutUseCaseTests.swift
//  GymBoTests
//
//  Comprehensive tests for CreateWorkoutUseCase
//

import XCTest
@testable import GymBo

@MainActor
final class CreateWorkoutUseCaseTests: XCTestCase {

    // MARK: - Properties

    var sut: DefaultCreateWorkoutUseCase!
    var mockWorkoutRepository: MockWorkoutRepository!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockWorkoutRepository = MockWorkoutRepository()
        sut = DefaultCreateWorkoutUseCase(workoutRepository: mockWorkoutRepository)
    }

    override func tearDown() async throws {
        sut = nil
        mockWorkoutRepository = nil
        try await super.tearDown()
    }

    // MARK: - Success Cases

    func testExecute_WithValidName_CreatesWorkout() async throws {
        // Given: Valid workout name
        let name = "Push Day"
        let restTime: TimeInterval = 90

        // When: Creating workout
        let workout = try await sut.execute(name: name, defaultRestTime: restTime)

        // Then: Should create workout with correct data
        XCTAssertEqual(workout.name, "Push Day", "Should have correct name")
        XCTAssertEqual(workout.defaultRestTime, 90, "Should have correct rest time")
        XCTAssertEqual(workout.exercises.count, 0, "Should start with no exercises")
        XCTAssertEqual(workout.isFavorite, false, "Should not be favorited by default")
        XCTAssertNotNil(workout.createdAt, "Should have creation date")
        XCTAssertNotNil(workout.updatedAt, "Should have update date")

        // Verify repository call
        XCTAssertEqual(mockWorkoutRepository.saveCallCount, 1, "Should save once")
        XCTAssertEqual(mockWorkoutRepository.lastSavedWorkout?.name, "Push Day", "Should save correct workout")
    }

    func testExecute_TrimsWhitespace_FromName() async throws {
        // Given: Name with leading/trailing whitespace
        let name = "  Push Day  "

        // When: Creating workout
        let workout = try await sut.execute(name: name, defaultRestTime: 90)

        // Then: Should trim whitespace
        XCTAssertEqual(workout.name, "Push Day", "Should trim whitespace")
    }

    func testExecute_WithCustomRestTime_UsesProvidedValue() async throws {
        // Given: Custom rest time
        let restTime: TimeInterval = 120

        // When: Creating workout
        let workout = try await sut.execute(name: "Test", defaultRestTime: restTime)

        // Then: Should use custom rest time
        XCTAssertEqual(workout.defaultRestTime, 120, "Should use custom rest time")
    }

    func testExecute_WithMinimalRestTime_CreatesWorkout() async throws {
        // Given: Minimal rest time (1 second)
        let restTime: TimeInterval = 1

        // When: Creating workout
        let workout = try await sut.execute(name: "Test", defaultRestTime: restTime)

        // Then: Should create workout
        XCTAssertEqual(workout.defaultRestTime, 1, "Should accept minimal rest time")
    }

    func testExecute_CreatesUniqueIds() async throws {
        // Given: Same workout name
        let name = "Push Day"

        // When: Creating two workouts
        let workout1 = try await sut.execute(name: name, defaultRestTime: 90)
        let workout2 = try await sut.execute(name: name, defaultRestTime: 90)

        // Then: Should have different IDs
        XCTAssertNotEqual(workout1.id, workout2.id, "Should create unique IDs")
    }

    func testExecute_SetsCreatedAndUpdatedDates() async throws {
        // Given: Current time before creation
        let beforeCreation = Date()

        // When: Creating workout
        let workout = try await sut.execute(name: "Test", defaultRestTime: 90)

        // Then: Dates should be set and after beforeCreation
        XCTAssertGreaterThanOrEqual(workout.createdAt, beforeCreation, "Created date should be recent")
        XCTAssertGreaterThanOrEqual(workout.updatedAt, beforeCreation, "Updated date should be recent")
        XCTAssertEqual(workout.createdAt, workout.updatedAt, "Initially, dates should be the same")
    }

    func testExecute_WithLongName_CreatesWorkout() async throws {
        // Given: Very long name
        let name = String(repeating: "A", count: 200)

        // When: Creating workout
        let workout = try await sut.execute(name: name, defaultRestTime: 90)

        // Then: Should create workout with full name
        XCTAssertEqual(workout.name.count, 200, "Should preserve long name")
    }

    func testExecute_WithSpecialCharacters_CreatesWorkout() async throws {
        // Given: Name with special characters
        let name = "Push Day 💪 (Upper Body) #1"

        // When: Creating workout
        let workout = try await sut.execute(name: name, defaultRestTime: 90)

        // Then: Should preserve special characters
        XCTAssertEqual(workout.name, "Push Day 💪 (Upper Body) #1", "Should preserve special characters")
    }

    func testExecute_WithGermanUmlauts_CreatesWorkout() async throws {
        // Given: Name with German umlauts
        let name = "Übung für Rücken"

        // When: Creating workout
        let workout = try await sut.execute(name: name, defaultRestTime: 90)

        // Then: Should preserve umlauts
        XCTAssertEqual(workout.name, "Übung für Rücken", "Should preserve umlauts")
    }

    // MARK: - Validation Error Cases

    func testExecute_WithEmptyName_ThrowsError() async {
        // Given: Empty name
        let name = ""

        // When/Then: Should throw validation error
        do {
            _ = try await sut.execute(name: name, defaultRestTime: 90)
            XCTFail("Should throw invalidInput error")
        } catch let error as UseCaseError {
            if case .invalidInput(let message) = error {
                XCTAssertTrue(message.contains("empty"), "Error message should mention empty name")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        // Should not save
        XCTAssertEqual(mockWorkoutRepository.saveCallCount, 0, "Should not save invalid workout")
    }

    func testExecute_WithWhitespaceOnlyName_ThrowsError() async {
        // Given: Name with only whitespace
        let name = "   \n\t  "

        // When/Then: Should throw validation error
        do {
            _ = try await sut.execute(name: name, defaultRestTime: 90)
            XCTFail("Should throw invalidInput error")
        } catch let error as UseCaseError {
            if case .invalidInput = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecute_WithZeroRestTime_ThrowsError() async {
        // Given: Zero rest time
        let restTime: TimeInterval = 0

        // When/Then: Should throw validation error
        do {
            _ = try await sut.execute(name: "Test", defaultRestTime: restTime)
            XCTFail("Should throw invalidInput error")
        } catch let error as UseCaseError {
            if case .invalidInput(let message) = error {
                XCTAssertTrue(message.contains("greater than 0"), "Error message should mention positive rest time")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecute_WithNegativeRestTime_ThrowsError() async {
        // Given: Negative rest time
        let restTime: TimeInterval = -30

        // When/Then: Should throw validation error
        do {
            _ = try await sut.execute(name: "Test", defaultRestTime: restTime)
            XCTFail("Should throw invalidInput error")
        } catch let error as UseCaseError {
            if case .invalidInput = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Repository Error Cases

    func testExecute_WithRepositorySaveError_ThrowsError() async {
        // Given: Repository will fail on save
        mockWorkoutRepository.saveError = RepositoryError.saveFailed("Database error")

        // When/Then: Should throw saveFailed error
        do {
            _ = try await sut.execute(name: "Test", defaultRestTime: 90)
            XCTFail("Should throw saveFailed error")
        } catch let error as UseCaseError {
            if case .saveFailed = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Integration Cases

    func testExecute_MultipleWorkouts_AllSavedCorrectly() async throws {
        // Given: Creating multiple workouts
        let names = ["Push Day", "Pull Day", "Leg Day"]

        // When: Creating all workouts
        var createdWorkouts: [Workout] = []
        for name in names {
            let workout = try await sut.execute(name: name, defaultRestTime: 90)
            createdWorkouts.append(workout)
        }

        // Then: All should be created and saved
        XCTAssertEqual(mockWorkoutRepository.saveCallCount, 3, "Should save 3 workouts")
        XCTAssertEqual(createdWorkouts.count, 3, "Should create 3 workouts")
        XCTAssertEqual(createdWorkouts[0].name, "Push Day")
        XCTAssertEqual(createdWorkouts[1].name, "Pull Day")
        XCTAssertEqual(createdWorkouts[2].name, "Leg Day")

        // All should have unique IDs
        let ids = Set(createdWorkouts.map { $0.id })
        XCTAssertEqual(ids.count, 3, "All workouts should have unique IDs")
    }

    func testExecute_ValidatesDuringCreation_NotJustOnSave() async {
        // Given: Invalid name
        let name = ""

        // When/Then: Should fail validation before attempting save
        do {
            _ = try await sut.execute(name: name, defaultRestTime: 90)
            XCTFail("Should throw error")
        } catch {
            // Success
        }

        // Should not attempt to save
        XCTAssertEqual(mockWorkoutRepository.saveCallCount, 0, "Should not attempt save after validation failure")
    }
}
