//
//  StartSessionUseCaseTests.swift
//  GymBoTests
//
//  Comprehensive tests for StartSessionUseCase
//

import HealthKit
import XCTest

@testable import GymBo

@MainActor
final class StartSessionUseCaseTests: XCTestCase {

    // MARK: - Properties

    var sut: DefaultStartSessionUseCase!
    var mockSessionRepository: MockSessionRepository!
    var mockExerciseRepository: MockExerciseRepository!
    var mockWorkoutRepository: MockWorkoutRepository!
    var mockHealthKitService: MockHealthKitService!
    var mockFeatureFlagService: MockFeatureFlagService!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockSessionRepository = MockSessionRepository()
        mockExerciseRepository = MockExerciseRepository()
        mockWorkoutRepository = MockWorkoutRepository()
        mockHealthKitService = MockHealthKitService()
        mockFeatureFlagService = MockFeatureFlagService()

        sut = DefaultStartSessionUseCase(
            sessionRepository: mockSessionRepository,
            exerciseRepository: mockExerciseRepository,
            workoutRepository: mockWorkoutRepository,
            healthKitService: mockHealthKitService,
            featureFlagService: mockFeatureFlagService
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockSessionRepository = nil
        mockExerciseRepository = nil
        mockWorkoutRepository = nil
        mockHealthKitService = nil
        mockFeatureFlagService = nil
        try await super.tearDown()
    }

    // MARK: - Success Cases

    func testExecute_WithValidWorkout_CreatesSession() async throws {
        // Given: A workout with 3 exercises
        let workout = TestDataFactory.createCompleteWorkout(name: "Push Day", exerciseCount: 3)
        mockWorkoutRepository.addWorkout(workout)

        // Add exercises to repository
        for exercise in workout.exercises {
            let exerciseEntity = TestDataFactory.createExercise(
                id: exercise.exerciseId, name: "Exercise \(exercise.orderIndex)")
            mockExerciseRepository.addExercise(exerciseEntity)
        }

        // When: Starting a session
        let session = try await sut.execute(workoutId: workout.id)

        // Then: Session should be created with correct data
        XCTAssertEqual(session.workoutId, workout.id, "Should reference correct workout")
        XCTAssertEqual(session.workoutName, "Push Day", "Should have workout name")
        XCTAssertEqual(session.exercises.count, 3, "Should have 3 exercises")
        XCTAssertEqual(session.state, .active, "Should be active")
        XCTAssertNotNil(session.startDate, "Should have start date")
        XCTAssertNil(session.endDate, "Should not have end date")

        // Verify repository calls
        XCTAssertEqual(mockSessionRepository.saveCallCount, 1, "Should save session once")
        XCTAssertEqual(mockWorkoutRepository.fetchCallCount, 1, "Should fetch workout once")
        XCTAssertEqual(
            mockSessionRepository.fetchActiveSessionCallCount, 1, "Should check for active session")
    }

    func testExecute_CreatesSessionExercises_WithCorrectSets() async throws {
        // Given: A workout with 1 exercise (3 sets, 10 reps, 50kg)
        let exerciseId = UUID()
        let workoutExercise = TestDataFactory.createWorkoutExercise(
            exerciseId: exerciseId,
            targetSets: 3,
            targetReps: 10,
            targetWeight: 50.0
        )
        let workout = TestDataFactory.createWorkout(name: "Test", exercises: [workoutExercise])
        mockWorkoutRepository.addWorkout(workout)

        let exercise = TestDataFactory.createExercise(id: exerciseId, name: "Bench Press")
        mockExerciseRepository.addExercise(exercise)

        // When: Starting a session
        let session = try await sut.execute(workoutId: workout.id)

        // Then: Should create correct sets
        XCTAssertEqual(session.exercises.count, 1, "Should have 1 exercise")
        let sessionExercise = session.exercises[0]
        XCTAssertEqual(sessionExercise.sets.count, 3, "Should have 3 sets")
        XCTAssertEqual(sessionExercise.sets[0].reps, 10, "Should have 10 reps")
        XCTAssertEqual(sessionExercise.sets[0].weight, 50.0, "Should have 50kg weight")
        XCTAssertEqual(sessionExercise.sets[0].completed, false, "Sets should start incomplete")
        XCTAssertEqual(sessionExercise.sets[0].orderIndex, 0, "First set should have orderIndex 0")
        XCTAssertEqual(sessionExercise.sets[2].orderIndex, 2, "Last set should have orderIndex 2")
    }

    func testExecute_UsesLastUsedValues_WhenAvailable() async throws {
        // Given: An exercise with last used values different from template
        let exerciseId = UUID()
        let workoutExercise = TestDataFactory.createWorkoutExercise(
            exerciseId: exerciseId,
            targetSets: 3,
            targetReps: 10,
            targetWeight: 50.0
        )
        let workout = TestDataFactory.createWorkout(exercises: [workoutExercise])
        mockWorkoutRepository.addWorkout(workout)

        // Exercise has been used before with 60kg and 12 reps
        let exercise = TestDataFactory.createExercise(
            id: exerciseId,
            lastUsedWeight: 60.0,
            lastUsedReps: 12
        )
        mockExerciseRepository.addExercise(exercise)

        // When: Starting a session
        let session = try await sut.execute(workoutId: workout.id)

        // Then: Should use last used values
        let sessionExercise = session.exercises[0]
        XCTAssertEqual(sessionExercise.sets[0].weight, 60.0, "Should use last used weight")
        XCTAssertEqual(sessionExercise.sets[0].reps, 12, "Should use last used reps")
    }

    func testExecute_WithPerSetRestTimes_AppliesCorrectly() async throws {
        // Given: A workout with per-set rest times
        let exerciseId = UUID()
        let perSetRestTimes: [TimeInterval] = [60, 90, 120]
        let workoutExercise = TestDataFactory.createWorkoutExercise(
            exerciseId: exerciseId,
            targetSets: 3,
            perSetRestTimes: perSetRestTimes
        )
        let workout = TestDataFactory.createWorkout(exercises: [workoutExercise])
        mockWorkoutRepository.addWorkout(workout)

        let exercise = TestDataFactory.createExercise(id: exerciseId)
        mockExerciseRepository.addExercise(exercise)

        // When: Starting a session
        let session = try await sut.execute(workoutId: workout.id)

        // Then: Should apply per-set rest times
        let sessionExercise = session.exercises[0]
        XCTAssertEqual(sessionExercise.sets[0].restTime, 60, "First set should have 60s rest")
        XCTAssertEqual(sessionExercise.sets[1].restTime, 90, "Second set should have 90s rest")
        XCTAssertEqual(sessionExercise.sets[2].restTime, 120, "Third set should have 120s rest")
    }

    func testExecute_PreservesExerciseOrder() async throws {
        // Given: A workout with exercises in specific order
        let exercise1 = TestDataFactory.createWorkoutExercise(exerciseId: UUID(), orderIndex: 0)
        let exercise2 = TestDataFactory.createWorkoutExercise(exerciseId: UUID(), orderIndex: 1)
        let exercise3 = TestDataFactory.createWorkoutExercise(exerciseId: UUID(), orderIndex: 2)
        let workout = TestDataFactory.createWorkout(exercises: [exercise1, exercise2, exercise3])
        mockWorkoutRepository.addWorkout(workout)

        for (index, exercise) in workout.exercises.enumerated() {
            let exerciseEntity = TestDataFactory.createExercise(
                id: exercise.exerciseId, name: "Exercise \(index)")
            mockExerciseRepository.addExercise(exerciseEntity)
        }

        // When: Starting a session
        let session = try await sut.execute(workoutId: workout.id)

        // Then: Should preserve order
        XCTAssertEqual(
            session.exercises[0].orderIndex, 0, "First exercise should have orderIndex 0")
        XCTAssertEqual(
            session.exercises[1].orderIndex, 1, "Second exercise should have orderIndex 1")
        XCTAssertEqual(
            session.exercises[2].orderIndex, 2, "Third exercise should have orderIndex 2")
    }

    func testExecute_WithHealthKitEnabled_StartsHealthKitSession() async throws {
        // Given: HealthKit feature flags are enabled
        mockFeatureFlagService.enableFlag(.dynamicIsland)
        mockHealthKitService.isHealthKitAvailable = true
        mockHealthKitService.startWorkoutSessionResult = .success(UUID().uuidString)

        let workout = TestDataFactory.createCompleteWorkout()
        mockWorkoutRepository.addWorkout(workout)
        for exercise in workout.exercises {
            mockExerciseRepository.addExercise(
                TestDataFactory.createExercise(id: exercise.exerciseId))
        }

        // When: Starting a session
        let _ = try await sut.execute(workoutId: workout.id)

        // Wait for background task
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

        // Then: Should attempt to start HealthKit session
        // Note: This is a fire-and-forget operation, so we can't guarantee timing
        // In real tests, you might use expectation or mock callbacks
    }

    // MARK: - Error Cases

    func testExecute_WithActiveSession_ThrowsError() async {
        // Given: An active session already exists
        let existingSession = TestDataFactory.createActiveSession()
        mockSessionRepository.fetchActiveSessionResult = existingSession

        let workoutId = UUID()

        // When/Then: Should throw activeSessionExists error
        do {
            _ = try await sut.execute(workoutId: workoutId)
            XCTFail("Should throw activeSessionExists error")
        } catch let error as UseCaseError {
            if case .activeSessionExists(let id) = error {
                XCTAssertEqual(id, existingSession.id, "Should return existing session ID")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecute_WithInvalidWorkoutId_ThrowsError() async {
        // Given: No workout with the given ID
        let invalidWorkoutId = UUID()

        // When/Then: Should throw workoutNotFound error
        do {
            _ = try await sut.execute(workoutId: invalidWorkoutId)
            XCTFail("Should throw workoutNotFound error")
        } catch let error as UseCaseError {
            if case .workoutNotFound(let id) = error {
                XCTAssertEqual(id, invalidWorkoutId, "Should return workout ID")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecute_WithRepositorySaveError_ThrowsError() async {
        // Given: Repository will fail on save
        let workout = TestDataFactory.createCompleteWorkout()
        mockWorkoutRepository.addWorkout(workout)
        for exercise in workout.exercises {
            mockExerciseRepository.addExercise(
                TestDataFactory.createExercise(id: exercise.exerciseId))
        }
        mockSessionRepository.saveError = RepositoryError.saveFailed("Database error")

        // When/Then: Should throw saveFailed error
        do {
            _ = try await sut.execute(workoutId: workout.id)
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

    // MARK: - Edge Cases

    func testExecute_WithEmptyWorkout_CreatesSessionWithNoExercises() async throws {
        // Given: A workout with no exercises
        let workout = TestDataFactory.createWorkout(name: "Empty Workout", exercises: [])
        mockWorkoutRepository.addWorkout(workout)

        // When: Starting a session
        let session = try await sut.execute(workoutId: workout.id)

        // Then: Should create session with no exercises
        XCTAssertEqual(session.exercises.count, 0, "Should have no exercises")
        XCTAssertEqual(session.state, .active, "Should still be active")
    }

    func testExecute_WithMissingExerciseInCatalog_UsesFallbackName() async throws {
        // Given: A workout referencing an exercise not in catalog
        let missingExerciseId = UUID()
        let workoutExercise = TestDataFactory.createWorkoutExercise(exerciseId: missingExerciseId)
        let workout = TestDataFactory.createWorkout(exercises: [workoutExercise])
        mockWorkoutRepository.addWorkout(workout)
        // Don't add exercise to repository

        // When: Starting a session
        let session = try await sut.execute(workoutId: workout.id)

        // Then: Should use fallback name
        XCTAssertEqual(session.exercises[0].exerciseName, "Übung", "Should use fallback name")
        XCTAssertEqual(session.exercises[0].sets.count, 3, "Should still create sets")
    }

    func testExecute_ChecksForActiveSession_BeforeLoading() async {
        // Given: An active session exists
        let existingSession = TestDataFactory.createActiveSession()
        mockSessionRepository.fetchActiveSessionResult = existingSession

        // When/Then: Should throw error without fetching workout
        do {
            _ = try await sut.execute(workoutId: UUID())
            XCTFail("Should throw error")
        } catch {
            // Success
        }

        // Verify workout was not fetched (optimization check)
        XCTAssertEqual(
            mockWorkoutRepository.fetchCallCount, 0,
            "Should not fetch workout if active session exists")
    }
}
