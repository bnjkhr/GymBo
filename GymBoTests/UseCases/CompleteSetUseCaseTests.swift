//
//  CompleteSetUseCaseTests.swift
//  GymBoTests
//
//  Comprehensive tests for CompleteSetUseCase
//

import XCTest

@testable import GymBo

@MainActor
final class CompleteSetUseCaseTests: XCTestCase {

    // MARK: - Properties

    var sut: DefaultCompleteSetUseCase!
    var mockSessionRepository: MockSessionRepository!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockSessionRepository = MockSessionRepository()
        sut = DefaultCompleteSetUseCase(sessionRepository: mockSessionRepository)
    }

    override func tearDown() async throws {
        sut = nil
        mockSessionRepository = nil
        try await super.tearDown()
    }

    // MARK: - Success Cases

    func testExecute_WithValidIds_CompletesSet() async throws {
        // Given: A session with an incomplete set
        let session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)
        let exerciseId = session.exercises[0].id
        let setId = session.exercises[0].sets[0].id
        mockSessionRepository.addSession(session)

        // When: Completing the set
        try await sut.execute(sessionId: session.id, exerciseId: exerciseId, setId: setId)

        // Then: Set should be marked as completed
        XCTAssertEqual(mockSessionRepository.updateCallCount, 1, "Should update session once")
        let updatedSession = mockSessionRepository.lastUpdatedSession
        XCTAssertNotNil(updatedSession, "Should have updated session")

        let updatedSet = updatedSession?.exercises[0].sets[0]
        XCTAssertEqual(updatedSet?.completed, true, "Set should be completed")
        XCTAssertNotNil(updatedSet?.completedAt, "Completion timestamp should be set")
    }

    func testExecute_WithCompletedSet_TogglesBack() async throws {
        // Given: A session with a completed set
        var session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)
        session.exercises[0].sets[0].completed = true
        session.exercises[0].sets[0].completedAt = Date()
        let exerciseId = session.exercises[0].id
        let setId = session.exercises[0].sets[0].id
        mockSessionRepository.addSession(session)

        // When: Toggling the set back to incomplete
        try await sut.execute(sessionId: session.id, exerciseId: exerciseId, setId: setId)

        // Then: Set should be incomplete again
        let updatedSession = mockSessionRepository.lastUpdatedSession
        let updatedSet = updatedSession?.exercises[0].sets[0]
        XCTAssertEqual(updatedSet?.completed, false, "Set should be incomplete")
        XCTAssertNil(updatedSet?.completedAt, "Completion timestamp should be cleared")
    }

    func testExecute_WithAllSetsCompleted_AutoFinishesExercise() async throws {
        // Given: A session with 2/3 sets completed
        var session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)
        session.exercises[0].sets[0].completed = true
        session.exercises[0].sets[1].completed = true
        // Set 2 is incomplete
        let exerciseId = session.exercises[0].id
        let setId = session.exercises[0].sets[2].id
        mockSessionRepository.addSession(session)

        // When: Completing the last set
        try await sut.execute(sessionId: session.id, exerciseId: exerciseId, setId: setId)

        // Then: Exercise should be auto-finished
        let updatedSession = mockSessionRepository.lastUpdatedSession
        let updatedExercise = updatedSession?.exercises[0]
        XCTAssertEqual(updatedExercise?.isFinished, true, "Exercise should be auto-finished")
        XCTAssertEqual(updatedExercise?.sets[2].completed, true, "Last set should be completed")
    }

    func testExecute_WithUncompletingSet_UnfinishesExercise() async throws {
        // Given: A session with all sets completed and exercise finished
        var session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)
        session.exercises[0].sets[0].completed = true
        session.exercises[0].sets[1].completed = true
        session.exercises[0].sets[2].completed = true
        session.exercises[0].isFinished = true
        let exerciseId = session.exercises[0].id
        let setId = session.exercises[0].sets[0].id
        mockSessionRepository.addSession(session)

        // When: Uncompleting a set
        try await sut.execute(sessionId: session.id, exerciseId: exerciseId, setId: setId)

        // Then: Exercise should be un-finished
        let updatedSession = mockSessionRepository.lastUpdatedSession
        let updatedExercise = updatedSession?.exercises[0]
        XCTAssertEqual(updatedExercise?.isFinished, false, "Exercise should be un-finished")
        XCTAssertEqual(updatedExercise?.sets[0].completed, false, "Set should be incomplete")
    }

    func testExecute_WithMultipleExercises_OnlyUpdatesCorrectExercise() async throws {
        // Given: A session with 3 exercises
        let session = TestDataFactory.createActiveSession(exerciseCount: 3, setsPerExercise: 3)
        let targetExerciseId = session.exercises[1].id
        let targetSetId = session.exercises[1].sets[0].id
        mockSessionRepository.addSession(session)

        // When: Completing a set in the middle exercise
        try await sut.execute(
            sessionId: session.id, exerciseId: targetExerciseId, setId: targetSetId)

        // Then: Only the target set should be completed
        let updatedSession = mockSessionRepository.lastUpdatedSession!
        XCTAssertEqual(
            updatedSession.exercises[0].sets[0].completed, false,
            "First exercise should be unchanged")
        XCTAssertEqual(
            updatedSession.exercises[1].sets[0].completed, true,
            "Target exercise should be completed")
        XCTAssertEqual(
            updatedSession.exercises[2].sets[0].completed, false,
            "Last exercise should be unchanged")
    }

    func testExecute_PreservesOtherSessionData() async throws {
        // Given: A session with metadata
        let originalStartDate = Date().addingTimeInterval(-1800)
        var session = TestDataFactory.createActiveSession(
            exerciseCount: 1, setsPerExercise: 3, startDate: originalStartDate)
        session.exercises[0].notes = "Important notes"
        let exerciseId = session.exercises[0].id
        let setId = session.exercises[0].sets[0].id
        mockSessionRepository.addSession(session)

        // When: Completing a set
        try await sut.execute(sessionId: session.id, exerciseId: exerciseId, setId: setId)

        // Then: Other data should be preserved
        let updatedSession = mockSessionRepository.lastUpdatedSession!
        XCTAssertEqual(
            updatedSession.startDate, originalStartDate, "Start date should be preserved")
        XCTAssertEqual(
            updatedSession.exercises[0].notes, "Important notes", "Notes should be preserved")
        XCTAssertEqual(
            updatedSession.workoutName, session.workoutName, "Workout name should be preserved")
    }

    // MARK: - Error Cases

    func testExecute_WithInvalidSessionId_ThrowsError() async {
        // Given: No session in repository
        let sessionId = UUID()
        let exerciseId = UUID()
        let setId = UUID()

        // When/Then: Should throw sessionNotFound error
        do {
            try await sut.execute(sessionId: sessionId, exerciseId: exerciseId, setId: setId)
            XCTFail("Should throw sessionNotFound error")
        } catch let error as UseCaseError {
            if case .sessionNotFound(let id) = error {
                XCTAssertEqual(id, sessionId, "Should return correct session ID")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecute_WithInvalidExerciseId_ThrowsError() async {
        // Given: A session without the target exercise
        let session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)
        let invalidExerciseId = UUID()
        let setId = UUID()
        mockSessionRepository.addSession(session)

        // When/Then: Should throw exerciseNotFound error
        do {
            try await sut.execute(
                sessionId: session.id, exerciseId: invalidExerciseId, setId: setId)
            XCTFail("Should throw exerciseNotFound error")
        } catch let error as UseCaseError {
            if case .exerciseNotFound(let id) = error {
                XCTAssertEqual(id, invalidExerciseId, "Should return correct exercise ID")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecute_WithInvalidSetId_ThrowsError() async {
        // Given: A session with an exercise but without the target set
        let session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)
        let exerciseId = session.exercises[0].id
        let invalidSetId = UUID()
        mockSessionRepository.addSession(session)

        // When/Then: Should throw setNotFound error
        do {
            try await sut.execute(
                sessionId: session.id, exerciseId: exerciseId, setId: invalidSetId)
            XCTFail("Should throw setNotFound error")
        } catch let error as UseCaseError {
            if case .setNotFound(let id) = error {
                XCTAssertEqual(id, invalidSetId, "Should return correct set ID")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecute_WithRepositoryError_ThrowsUpdateFailed() async {
        // Given: Repository will fail on update
        let session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)
        let exerciseId = session.exercises[0].id
        let setId = session.exercises[0].sets[0].id
        mockSessionRepository.addSession(session)
        mockSessionRepository.updateError = RepositoryError.updateFailed("Database error")

        // When/Then: Should throw updateFailed error
        do {
            try await sut.execute(sessionId: session.id, exerciseId: exerciseId, setId: setId)
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

    // MARK: - Edge Cases

    func testExecute_WithSingleSet_CanComplete() async throws {
        // Given: An exercise with only one set
        var session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 1)
        let exerciseId = session.exercises[0].id
        let setId = session.exercises[0].sets[0].id
        mockSessionRepository.addSession(session)

        // When: Completing the only set
        try await sut.execute(sessionId: session.id, exerciseId: exerciseId, setId: setId)

        // Then: Set should be completed and exercise auto-finished
        let updatedSession = mockSessionRepository.lastUpdatedSession!
        XCTAssertEqual(
            updatedSession.exercises[0].sets[0].completed, true, "Set should be completed")
        XCTAssertEqual(
            updatedSession.exercises[0].isFinished, true, "Exercise should be auto-finished")
    }

    func testExecute_WithWarmupSet_CanComplete() async throws {
        // Given: A session with a warmup set
        var session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)
        session.exercises[0].sets[0].isWarmup = true
        let exerciseId = session.exercises[0].id
        let setId = session.exercises[0].sets[0].id
        mockSessionRepository.addSession(session)

        // When: Completing the warmup set
        try await sut.execute(sessionId: session.id, exerciseId: exerciseId, setId: setId)

        // Then: Warmup set should be completed
        let updatedSession = mockSessionRepository.lastUpdatedSession!
        XCTAssertEqual(
            updatedSession.exercises[0].sets[0].completed, true, "Warmup set should be completed")
        XCTAssertEqual(
            updatedSession.exercises[0].sets[0].isWarmup, true, "Should still be marked as warmup")
    }

    func testExecute_CompletingSetMultipleTimes_TogglesCorrectly() async throws {
        // Given: A session with an incomplete set
        let session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)
        let exerciseId = session.exercises[0].id
        let setId = session.exercises[0].sets[0].id
        mockSessionRepository.addSession(session)

        // When: Completing the set 3 times
        try await sut.execute(sessionId: session.id, exerciseId: exerciseId, setId: setId)
        var updatedSession = mockSessionRepository.lastUpdatedSession!
        mockSessionRepository.addSession(updatedSession)

        try await sut.execute(sessionId: session.id, exerciseId: exerciseId, setId: setId)
        updatedSession = mockSessionRepository.lastUpdatedSession!
        mockSessionRepository.addSession(updatedSession)

        try await sut.execute(sessionId: session.id, exerciseId: exerciseId, setId: setId)
        updatedSession = mockSessionRepository.lastUpdatedSession!

        // Then: Set should be completed (toggled 3 times: incomplete -> complete -> incomplete -> complete)
        XCTAssertEqual(
            updatedSession.exercises[0].sets[0].completed, true,
            "Should be completed after 3 toggles")
        XCTAssertEqual(mockSessionRepository.updateCallCount, 3, "Should have updated 3 times")
    }
}
