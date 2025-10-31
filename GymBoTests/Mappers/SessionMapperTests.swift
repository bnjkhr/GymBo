//
//  SessionMapperTests.swift
//  GymBoTests
//
//  Comprehensive tests for SessionMapper
//

import SwiftData
import XCTest

@testable import GymBo

@MainActor
final class SessionMapperTests: XCTestCase {

    // MARK: - Properties

    var sut: SessionMapper!
    var modelContext: ModelContext!
    var modelContainer: ModelContainer!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = SessionMapper()

        // Create in-memory model container for testing
        let schema = Schema([
            WorkoutSessionEntity.self,
            SessionExerciseEntity.self,
            SessionSetEntity.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
    }

    override func tearDown() async throws {
        sut = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Domain to Entity Tests

    func testToEntity_WithBasicSession_CreatesEntity() {
        // Given: A domain session
        let domainSession = TestDataFactory.createActiveSession(
            exerciseCount: 2, setsPerExercise: 3)

        // When: Converting to entity
        let entity = sut.toEntity(domainSession)

        // Then: Should create entity with correct data
        XCTAssertEqual(entity.id, domainSession.id)
        XCTAssertEqual(entity.workoutId, domainSession.workoutId)
        XCTAssertEqual(entity.workoutName, domainSession.workoutName)
        XCTAssertEqual(entity.startDate, domainSession.startDate)
        XCTAssertEqual(entity.endDate, domainSession.endDate)
        XCTAssertEqual(entity.state, domainSession.state.rawValue)
        XCTAssertEqual(entity.exercises.count, 2)
    }

    func testToEntity_MapsAllSessionStates_Correctly() {
        // Given: Sessions with different states
        let states: [DomainWorkoutSession.SessionState] = [
            .active, .completed, .paused,
        ]

        for state in states {
            var session = TestDataFactory.createSession()
            session.state = state

            // When: Converting to entity
            let entity = sut.toEntity(session)

            // Then: State should be mapped correctly
            XCTAssertEqual(entity.state, state.rawValue, "State \(state) should map correctly")
        }
    }

    func testToEntity_WithHealthKitSession_MapsId() {
        // Given: A session with HealthKit ID
        var session = TestDataFactory.createSession()
        let healthKitId = UUID().uuidString
        session.healthKitSessionId = healthKitId

        // When: Converting to entity
        let entity = sut.toEntity(session)

        // Then: HealthKit ID should be mapped
        XCTAssertEqual(entity.healthKitSessionId, healthKitId)
    }

    func testToEntity_WithExercises_MapsAllExercises() {
        // Given: A session with 3 exercises
        let session = TestDataFactory.createActiveSession(exerciseCount: 3, setsPerExercise: 2)

        // When: Converting to entity
        let entity = sut.toEntity(session)

        // Then: All exercises should be mapped
        XCTAssertEqual(entity.exercises.count, 3)
        XCTAssertEqual(entity.exercises[0].exerciseId, session.exercises[0].exerciseId)
        XCTAssertEqual(entity.exercises[0].exerciseName, session.exercises[0].exerciseName)
        XCTAssertEqual(entity.exercises[0].orderIndex, 0)
        XCTAssertEqual(entity.exercises[1].orderIndex, 1)
        XCTAssertEqual(entity.exercises[2].orderIndex, 2)
    }

    func testToEntity_WithSets_MapsAllSets() {
        // Given: A session with sets
        let session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)

        // When: Converting to entity
        let entity = sut.toEntity(session)

        // Then: All sets should be mapped
        let exerciseEntity = entity.exercises[0]
        XCTAssertEqual(exerciseEntity.sets.count, 3)

        for (index, setEntity) in exerciseEntity.sets.enumerated() {
            let domainSet = session.exercises[0].sets[index]
            XCTAssertEqual(setEntity.id, domainSet.id)
            XCTAssertEqual(setEntity.weight, domainSet.weight)
            XCTAssertEqual(setEntity.reps, domainSet.reps)
            XCTAssertEqual(setEntity.completed, domainSet.completed)
            XCTAssertEqual(setEntity.orderIndex, domainSet.orderIndex)
            XCTAssertEqual(setEntity.isWarmup, domainSet.isWarmup)
            XCTAssertEqual(setEntity.restTime, domainSet.restTime)
        }
    }

    func testToEntity_WithCompletedSets_MapsCompletionData() {
        // Given: A session with completed sets
        var session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 2)
        let completionDate = Date()
        session.exercises[0].sets[0].completed = true
        session.exercises[0].sets[0].completedAt = completionDate

        // When: Converting to entity
        let entity = sut.toEntity(session)

        // Then: Completion data should be mapped
        let setEntity = entity.exercises[0].sets[0]
        XCTAssertEqual(setEntity.completed, true)
        XCTAssertEqual(setEntity.completedAt, completionDate)
    }

    func testToEntity_WithWarmupSets_MapsWarmupFlag() {
        // Given: A session with warmup sets
        var session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)
        session.exercises[0].sets[0].isWarmup = true
        session.exercises[0].sets[1].isWarmup = false

        // When: Converting to entity
        let entity = sut.toEntity(session)

        // Then: Warmup flags should be mapped
        XCTAssertEqual(entity.exercises[0].sets[0].isWarmup, true)
        XCTAssertEqual(entity.exercises[0].sets[1].isWarmup, false)
    }

    func testToEntity_PreservesOrderIndices() {
        // Given: A session with specific order indices
        var session = TestDataFactory.createActiveSession(exerciseCount: 3, setsPerExercise: 2)
        session.exercises[0].orderIndex = 2
        session.exercises[1].orderIndex = 0
        session.exercises[2].orderIndex = 1

        // When: Converting to entity
        let entity = sut.toEntity(session)

        // Then: Order indices should be preserved
        XCTAssertEqual(entity.exercises[0].orderIndex, 2)
        XCTAssertEqual(entity.exercises[1].orderIndex, 0)
        XCTAssertEqual(entity.exercises[2].orderIndex, 1)
    }

    // MARK: - Entity to Domain Tests

    func testToDomain_WithBasicEntity_CreatesDomainObject() {
        // Given: An entity
        let entityId = UUID()
        let workoutId = UUID()
        let startDate = Date()
        let entity = WorkoutSessionEntity(
            id: entityId,
            workoutId: workoutId,
            startDate: startDate,
            state: "active",
            workoutName: "Test Workout"
        )

        // When: Converting to domain
        let domain = sut.toDomain(entity)

        // Then: Should create domain object with correct data
        XCTAssertEqual(domain.id, entityId)
        XCTAssertEqual(domain.workoutId, workoutId)
        XCTAssertEqual(domain.workoutName, "Test Workout")
        XCTAssertEqual(domain.startDate, startDate)
        XCTAssertEqual(domain.state, .active)
    }

    func testToDomain_WithEndDate_MapsEndDate() {
        // Given: An entity with end date
        let startDate = Date().addingTimeInterval(-3600)
        let endDate = Date()
        let entity = WorkoutSessionEntity(
            workoutId: UUID(),
            startDate: startDate,
            endDate: endDate,
            state: "completed",
            workoutName: "Test"
        )

        // When: Converting to domain
        let domain = sut.toDomain(entity)

        // Then: End date should be mapped
        XCTAssertEqual(domain.endDate, endDate)
        XCTAssertEqual(domain.state, .completed)
    }

    func testToDomain_SortsExercises_ByOrderIndex() {
        // Given: An entity with exercises in wrong order
        let exercise1 = SessionExerciseEntity(
            exerciseId: UUID(),
            exerciseName: "Exercise 3",
            orderIndex: 2
        )

        let exercise2 = SessionExerciseEntity(
            exerciseId: UUID(),
            exerciseName: "Exercise 1",
            orderIndex: 0
        )

        let exercise3 = SessionExerciseEntity(
            exerciseId: UUID(),
            exerciseName: "Exercise 2",
            orderIndex: 1
        )

        let entity = WorkoutSessionEntity(
            workoutId: UUID(),
            startDate: Date(),
            state: "active",
            workoutName: "Test",
            exercises: [exercise1, exercise2, exercise3]
        )

        // When: Converting to domain
        let domain = sut.toDomain(entity)

        // Then: Exercises should be sorted by orderIndex
        XCTAssertEqual(domain.exercises.count, 3)
        XCTAssertEqual(domain.exercises[0].exerciseName, "Exercise 1")
        XCTAssertEqual(domain.exercises[1].exerciseName, "Exercise 2")
        XCTAssertEqual(domain.exercises[2].exerciseName, "Exercise 3")
    }

    func testToDomain_SortsSets_ByOrderIndex() {
        // Given: An entity with sets in wrong order
        let set1 = SessionSetEntity(
            weight: 60.0,
            reps: 10,
            orderIndex: 2
        )

        let set2 = SessionSetEntity(
            weight: 60.0,
            reps: 12,
            orderIndex: 0
        )

        let set3 = SessionSetEntity(
            weight: 60.0,
            reps: 11,
            orderIndex: 1
        )

        let exercise = SessionExerciseEntity(
            exerciseId: UUID(),
            sets: [set1, set2, set3]
        )

        let entity = WorkoutSessionEntity(
            workoutId: UUID(),
            startDate: Date(),
            state: "active",
            workoutName: "Test",
            exercises: [exercise]
        )

        // When: Converting to domain
        let domain = sut.toDomain(entity)

        // Then: Sets should be sorted by orderIndex
        let domainExercise = domain.exercises[0]
        XCTAssertEqual(domainExercise.sets.count, 3)
        XCTAssertEqual(domainExercise.sets[0].reps, 12)
        XCTAssertEqual(domainExercise.sets[1].reps, 11)
        XCTAssertEqual(domainExercise.sets[2].reps, 10)
    }

    // MARK: - Round-trip Tests

    func testRoundTrip_PreservesAllData() {
        // Given: A complex domain session
        let originalSession = TestDataFactory.createCompletedSession(
            workoutName: "Test Workout",
            exerciseCount: 3,
            setsPerExercise: 4
        )

        // When: Converting to entity and back
        let entity = sut.toEntity(originalSession)
        let roundTripSession = sut.toDomain(entity)

        // Then: Should preserve all data
        XCTAssertEqual(roundTripSession.id, originalSession.id)
        XCTAssertEqual(roundTripSession.workoutId, originalSession.workoutId)
        XCTAssertEqual(roundTripSession.workoutName, originalSession.workoutName)
        XCTAssertEqual(roundTripSession.startDate, originalSession.startDate)
        XCTAssertEqual(roundTripSession.endDate, originalSession.endDate)
        XCTAssertEqual(roundTripSession.state, originalSession.state)
        XCTAssertEqual(roundTripSession.exercises.count, originalSession.exercises.count)
    }

    func testRoundTrip_PreservesExerciseData() {
        // Given: A session with exercise metadata
        var session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)
        session.exercises[0].notes = "Important notes"
        session.exercises[0].restTimeToNext = 120
        session.exercises[0].isFinished = true

        // When: Converting to entity and back
        let entity = sut.toEntity(session)
        let roundTrip = sut.toDomain(entity)

        // Then: Should preserve exercise metadata
        XCTAssertEqual(roundTrip.exercises[0].notes, "Important notes")
        XCTAssertEqual(roundTrip.exercises[0].restTimeToNext, 120)
        XCTAssertEqual(roundTrip.exercises[0].isFinished, true)
    }

    func testRoundTrip_PreservesSetData() {
        // Given: A session with set metadata
        var session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 2)
        let completionDate = Date()
        session.exercises[0].sets[0].weight = 60.5
        session.exercises[0].sets[0].reps = 12
        session.exercises[0].sets[0].completed = true
        session.exercises[0].sets[0].completedAt = completionDate
        session.exercises[0].sets[0].isWarmup = true
        session.exercises[0].sets[0].restTime = 90

        // When: Converting to entity and back
        let entity = sut.toEntity(session)
        let roundTrip = sut.toDomain(entity)

        // Then: Should preserve set metadata
        let set = roundTrip.exercises[0].sets[0]
        XCTAssertEqual(set.weight, 60.5)
        XCTAssertEqual(set.reps, 12)
        XCTAssertEqual(set.completed, true)
        XCTAssertEqual(set.completedAt, completionDate)
        XCTAssertEqual(set.isWarmup, true)
        XCTAssertEqual(set.restTime, 90)
    }

    // MARK: - Edge Cases

    func testToEntity_WithEmptySession_CreatesValidEntity() {
        // Given: A session with no exercises
        let session = TestDataFactory.createSession(exercises: [])

        // When: Converting to entity
        let entity = sut.toEntity(session)

        // Then: Should create valid entity with no exercises
        XCTAssertEqual(entity.exercises.count, 0)
        XCTAssertNotNil(entity.id)
        XCTAssertNotNil(entity.startDate)
    }

    func testToDomain_WithEmptyEntity_CreatesValidDomain() {
        // Given: An entity with no exercises
        let entity = WorkoutSessionEntity(
            workoutId: UUID(),
            startDate: Date(),
            state: "active",
            workoutName: "Empty",
            exercises: []
        )

        // When: Converting to domain
        let domain = sut.toDomain(entity)

        // Then: Should create valid domain with no exercises
        XCTAssertEqual(domain.exercises.count, 0)
        XCTAssertNotNil(domain.id)
    }

    func testToEntity_WithNilValues_HandlesGracefully() {
        // Given: A session with nil optional values
        var session = TestDataFactory.createSession()
        session.endDate = nil
        session.healthKitSessionId = nil
        session.exercises[0].notes = nil
        session.exercises[0].restTimeToNext = nil

        // When: Converting to entity
        let entity = sut.toEntity(session)

        // Then: Should handle nil values
        XCTAssertNil(entity.endDate)
        XCTAssertNil(entity.healthKitSessionId)
    }
}
