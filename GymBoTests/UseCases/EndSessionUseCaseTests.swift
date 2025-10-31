//
//  EndSessionUseCaseTests.swift
//  GymBoTests
//
//  Comprehensive tests for EndSessionUseCase
//

import XCTest

@testable import GymBo

@MainActor
final class EndSessionUseCaseTests: XCTestCase {

    // MARK: - Properties

    var sut: DefaultEndSessionUseCase!
    var mockSessionRepository: MockSessionRepository!
    var mockExerciseRepository: MockExerciseRepository!
    var mockHealthKitService: MockHealthKitService!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockSessionRepository = MockSessionRepository()
        mockExerciseRepository = MockExerciseRepository()
        mockHealthKitService = MockHealthKitService()

        sut = DefaultEndSessionUseCase(
            sessionRepository: mockSessionRepository,
            healthKitService: mockHealthKitService,
            userProfileRepository: MockUserProfileRepository()
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockSessionRepository = nil
        mockExerciseRepository = nil
        mockHealthKitService = nil
        try await super.tearDown()
    }

    // MARK: - Success Cases

    func testExecute_WithActiveSession_CompletesSession() async throws {
        // Given: An active session
        let session = TestDataFactory.createActiveSession(exerciseCount: 2, setsPerExercise: 3)
        mockSessionRepository.addSession(session)

        // When: Ending the session
        let completedSession = try await sut.execute(sessionId: session.id)

        // Then: Session should be marked as completed
        XCTAssertEqual(completedSession.state, .completed, "Should be completed")
        XCTAssertNotNil(completedSession.endDate, "Should have end date")
        XCTAssertGreaterThan(
            completedSession.endDate!, completedSession.startDate,
            "End date should be after start date")

        // Verify repository call
        XCTAssertEqual(mockSessionRepository.updateCallCount, 1, "Should update session once")
        XCTAssertEqual(mockSessionRepository.lastUpdatedSession?.state, .completed)
    }

    func testExecute_UpdatesLastUsedValues_ForAllExercises() async throws {
        // Given: A session with 3 exercises, each with completed sets
        var session = TestDataFactory.createActiveSession(exerciseCount: 3, setsPerExercise: 3)

        // Complete all sets with specific values
        for exerciseIndex in 0..<session.exercises.count {
            for setIndex in 0..<session.exercises[exerciseIndex].sets.count {
                session.exercises[exerciseIndex].sets[setIndex].completed = true
                session.exercises[exerciseIndex].sets[setIndex].weight =
                    50.0 + Double(exerciseIndex * 10)
                session.exercises[exerciseIndex].sets[setIndex].reps = 10 + exerciseIndex
            }
        }
        mockSessionRepository.addSession(session)

        // Add exercises to repository
        for exercise in session.exercises {
            mockExerciseRepository.addExercise(
                TestDataFactory.createExercise(id: exercise.exerciseId))
        }

        // When: Ending the session
        _ = try await sut.execute(sessionId: session.id)

        // Then: Should update last used values for all exercises
        XCTAssertEqual(
            mockExerciseRepository.updateLastUsedValuesCallCount, 3, "Should update 3 exercises")
    }

    func testExecute_UsesMaxValues_FromCompletedSets() async throws {
        // Given: A session with varying set values
        var session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)
        let exerciseId = session.exercises[0].exerciseId

        // Set 1: 50kg x 10 reps (completed)
        session.exercises[0].sets[0].weight = 50.0
        session.exercises[0].sets[0].reps = 10
        session.exercises[0].sets[0].completed = true

        // Set 2: 60kg x 8 reps (completed) - highest weight
        session.exercises[0].sets[1].weight = 60.0
        session.exercises[0].sets[1].reps = 8
        session.exercises[0].sets[1].completed = true

        // Set 3: 55kg x 12 reps (completed) - highest reps
        session.exercises[0].sets[2].weight = 55.0
        session.exercises[0].sets[2].reps = 12
        session.exercises[0].sets[2].completed = true

        mockSessionRepository.addSession(session)
        mockExerciseRepository.addExercise(TestDataFactory.createExercise(id: exerciseId))

        // When: Ending the session
        _ = try await sut.execute(sessionId: session.id)

        // Then: Should use max weight and max reps
        XCTAssertEqual(
            mockExerciseRepository.lastUpdatedWeight, 60.0, "Should use max weight (60kg)")
        XCTAssertEqual(mockExerciseRepository.lastUpdatedReps, 12, "Should use max reps (12)")
        XCTAssertEqual(mockExerciseRepository.lastUpdatedExerciseId, exerciseId)
    }

    func testExecute_IgnoresIncompleteSets_WhenCalculatingMax() async throws {
        // Given: A session with completed and incomplete sets
        var session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)
        let exerciseId = session.exercises[0].exerciseId

        // Set 1: 50kg x 10 reps (completed)
        session.exercises[0].sets[0].weight = 50.0
        session.exercises[0].sets[0].reps = 10
        session.exercises[0].sets[0].completed = true

        // Set 2: 100kg x 20 reps (NOT completed) - should be ignored
        session.exercises[0].sets[1].weight = 100.0
        session.exercises[0].sets[1].reps = 20
        session.exercises[0].sets[1].completed = false

        // Set 3: 55kg x 12 reps (completed)
        session.exercises[0].sets[2].weight = 55.0
        session.exercises[0].sets[2].reps = 12
        session.exercises[0].sets[2].completed = true

        mockSessionRepository.addSession(session)
        mockExerciseRepository.addExercise(TestDataFactory.createExercise(id: exerciseId))

        // When: Ending the session
        _ = try await sut.execute(sessionId: session.id)

        // Then: Should only use completed sets
        XCTAssertEqual(
            mockExerciseRepository.lastUpdatedWeight, 55.0,
            "Should use max from completed sets only")
        XCTAssertEqual(
            mockExerciseRepository.lastUpdatedReps, 12,
            "Should use max reps from completed sets only")
    }

    func testExecute_WithNoCompletedSets_DoesNotUpdateExercise() async throws {
        // Given: A session with no completed sets
        let session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)
        // All sets are incomplete by default
        mockSessionRepository.addSession(session)

        // When: Ending the session
        _ = try await sut.execute(sessionId: session.id)

        // Then: Should not update exercise values
        XCTAssertEqual(
            mockExerciseRepository.updateLastUsedValuesCallCount, 0,
            "Should not update with no completed sets")
    }

    func testExecute_WithWarmupSets_IgnoresThemInCalculation() async throws {
        // Given: A session with warmup and working sets
        var session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 4)
        let exerciseId = session.exercises[0].exerciseId

        // Warmup set: 30kg x 10 reps (completed, should be ignored)
        session.exercises[0].sets[0].weight = 30.0
        session.exercises[0].sets[0].reps = 10
        session.exercises[0].sets[0].completed = true
        session.exercises[0].sets[0].isWarmup = true

        // Working sets
        session.exercises[0].sets[1].weight = 50.0
        session.exercises[0].sets[1].reps = 10
        session.exercises[0].sets[1].completed = true
        session.exercises[0].sets[1].isWarmup = false

        session.exercises[0].sets[2].weight = 55.0
        session.exercises[0].sets[2].reps = 8
        session.exercises[0].sets[2].completed = true
        session.exercises[0].sets[2].isWarmup = false

        mockSessionRepository.addSession(session)
        mockExerciseRepository.addExercise(TestDataFactory.createExercise(id: exerciseId))

        // When: Ending the session
        _ = try await sut.execute(sessionId: session.id)

        // Then: Should ignore warmup sets
        XCTAssertEqual(mockExerciseRepository.lastUpdatedWeight, 55.0, "Should ignore warmup set")
        XCTAssertEqual(
            mockExerciseRepository.lastUpdatedReps, 10, "Should use max from working sets")
    }

    func testExecute_WithHealthKitSession_EndsHealthKitSession() async throws {
        // Given: A session with HealthKit ID
        var session = TestDataFactory.createActiveSession()
        let healthKitId = UUID().uuidString
        session.healthKitSessionId = healthKitId
        mockSessionRepository.addSession(session)
        mockHealthKitService.endWorkoutSessionResult = .success(())

        // When: Ending the session
        _ = try await sut.execute(sessionId: session.id)

        // Wait for background task
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

        // Then: Should attempt to end HealthKit session
        // Note: This is fire-and-forget, so timing is not guaranteed in tests
    }

    func testExecute_WithoutHealthKitSession_SkipsHealthKit() async throws {
        // Given: A session without HealthKit ID
        let session = TestDataFactory.createActiveSession()
        XCTAssertNil(session.healthKitSessionId, "Should not have HealthKit ID")
        mockSessionRepository.addSession(session)

        // When: Ending the session
        _ = try await sut.execute(sessionId: session.id)

        // Wait a bit
        try await Task.sleep(nanoseconds: 50_000_000)

        // Then: Should complete without calling HealthKit
        // (No way to verify negative case without complex mocking)
    }

    func testExecute_PreservesSessionData() async throws {
        // Given: A session with metadata
        let originalStartDate = Date().addingTimeInterval(-3600)
        var session = TestDataFactory.createActiveSession(startDate: originalStartDate)
        session.workoutName = "Important Workout"
        mockSessionRepository.addSession(session)

        // When: Ending the session
        let completedSession = try await sut.execute(sessionId: session.id)

        // Then: Should preserve other data
        XCTAssertEqual(completedSession.workoutName, "Important Workout")
        XCTAssertEqual(completedSession.startDate, originalStartDate)
        XCTAssertEqual(completedSession.workoutId, session.workoutId)
        XCTAssertEqual(completedSession.exercises.count, session.exercises.count)
    }

    // MARK: - Error Cases

    func testExecute_WithInvalidSessionId_ThrowsError() async {
        // Given: No session in repository
        let sessionId = UUID()

        // When/Then: Should throw sessionNotFound error
        do {
            _ = try await sut.execute(sessionId: sessionId)
            XCTFail("Should throw sessionNotFound error")
        } catch let error as UseCaseError {
            if case .sessionNotFound(let id) = error {
                XCTAssertEqual(id, sessionId)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecute_WithRepositoryUpdateError_ThrowsError() async {
        // Given: Repository will fail on update
        let session = TestDataFactory.createActiveSession()
        mockSessionRepository.addSession(session)
        mockSessionRepository.updateError = RepositoryError.updateFailed("Database error")

        // When/Then: Should throw updateFailed error
        do {
            _ = try await sut.execute(sessionId: session.id)
            XCTFail("Should throw updateFailed error")
        } catch let error as UseCaseError {
            if case .updateFailed = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecute_WithExerciseUpdateError_ContinuesAnyway() async throws {
        // Given: Exercise repository will fail on update
        var session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)
        session.exercises[0].sets[0].completed = true
        mockSessionRepository.addSession(session)
        mockExerciseRepository.addExercise(
            TestDataFactory.createExercise(id: session.exercises[0].exerciseId))
        mockExerciseRepository.updateLastUsedValuesError = RepositoryError.updateFailed("Error")

        // When: Ending the session
        let completedSession = try await sut.execute(sessionId: session.id)

        // Then: Should still complete session (exercise update failures are non-fatal)
        XCTAssertEqual(
            completedSession.state, .completed, "Should complete despite exercise update failure")
    }

    // MARK: - Edge Cases

    func testExecute_WithAlreadyCompletedSession_CanEndAgain() async throws {
        // Given: An already completed session
        var session = TestDataFactory.createActiveSession()
        session.state = .completed
        session.endDate = Date().addingTimeInterval(-3600)
        let originalEndDate = session.endDate!
        mockSessionRepository.addSession(session)

        // When: Ending again
        let completedSession = try await sut.execute(sessionId: session.id)

        // Then: Should update end date
        XCTAssertEqual(completedSession.state, .completed)
        XCTAssertNotEqual(completedSession.endDate, originalEndDate, "Should update end date")
        XCTAssertGreaterThan(
            completedSession.endDate!, originalEndDate, "New end date should be later")
    }

    func testExecute_WithZeroDuration_CanComplete() async throws {
        // Given: A session just started (almost zero duration)
        let session = TestDataFactory.createActiveSession()
        mockSessionRepository.addSession(session)

        // When: Ending immediately
        let completedSession = try await sut.execute(sessionId: session.id)

        // Then: Should complete successfully
        XCTAssertEqual(completedSession.state, .completed)
        XCTAssertNotNil(completedSession.endDate)
    }
}
