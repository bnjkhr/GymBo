//
//  SessionSetTests.swift
//  GymBoTests
//
//  Comprehensive tests for DomainSessionSet entity
//

import XCTest

@testable import GymBo

final class SessionSetTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_WithDefaultValues_CreatesSet() {
        // Given/When: Creating a set with defaults
        let set = DomainSessionSet(
            weight: 60.0,
            reps: 10,
            orderIndex: 0
        )

        // Then: Should have correct default values
        XCTAssertEqual(set.weight, 60.0)
        XCTAssertEqual(set.reps, 10)
        XCTAssertEqual(set.orderIndex, 0)
        XCTAssertFalse(set.completed, "Should start incomplete")
        XCTAssertNil(set.completedAt, "Should not have completion date")
        XCTAssertFalse(set.isWarmup, "Should not be warmup by default")
        XCTAssertNil(set.restTime, "Rest time is optional")
        XCTAssertNotNil(set.id, "Should generate ID")
    }

    func testInit_WithAllParameters_CreatesSet() {
        // Given: All parameters
        let id = UUID()
        let completionDate = Date()
        let restTime: TimeInterval = 90

        // When: Creating set
        let set = DomainSessionSet(
            id: id,
            weight: 60.0,
            reps: 10,
            completed: true,
            completedAt: completionDate,
            orderIndex: 0,
            restTime: restTime,
            isWarmup: true
        )

        // Then: All values should be set correctly
        XCTAssertEqual(set.id, id)
        XCTAssertEqual(set.weight, 60.0)
        XCTAssertEqual(set.reps, 10)
        XCTAssertTrue(set.completed)
        XCTAssertEqual(set.completedAt, completionDate)
        XCTAssertEqual(set.orderIndex, 0)
        XCTAssertTrue(set.isWarmup)
        XCTAssertEqual(set.restTime, restTime)
    }

    // MARK: - Toggle Completion Tests

    func testToggleCompletion_WithIncompleteSet_CompletesSet() {
        // Given: An incomplete set
        var set = TestDataFactory.createSessionSet(completed: false)
        let beforeToggle = Date()

        // When: Toggling completion
        set.toggleCompletion()
        let afterToggle = Date()

        // Then: Should be completed with timestamp
        XCTAssertTrue(set.completed, "Should be completed")
        XCTAssertNotNil(set.completedAt, "Should have completion timestamp")
        XCTAssertGreaterThanOrEqual(
            set.completedAt!, beforeToggle, "Completion time should be recent")
        XCTAssertLessThanOrEqual(set.completedAt!, afterToggle, "Completion time should be recent")
    }

    func testToggleCompletion_WithCompletedSet_UncompletesSet() {
        // Given: A completed set
        var set = TestDataFactory.createSessionSet(completed: true, completedAt: Date())

        // When: Toggling completion
        set.toggleCompletion()

        // Then: Should be incomplete without timestamp
        XCTAssertFalse(set.completed, "Should be incomplete")
        XCTAssertNil(set.completedAt, "Should not have completion timestamp")
    }

    func testToggleCompletion_MultipleTimes_TogglesCorrectly() {
        // Given: An incomplete set
        var set = TestDataFactory.createSessionSet(completed: false)

        // When: Toggling 4 times
        set.toggleCompletion()  // complete
        XCTAssertTrue(set.completed)
        XCTAssertNotNil(set.completedAt)

        set.toggleCompletion()  // incomplete
        XCTAssertFalse(set.completed)
        XCTAssertNil(set.completedAt)

        set.toggleCompletion()  // complete
        XCTAssertTrue(set.completed)
        XCTAssertNotNil(set.completedAt)

        set.toggleCompletion()  // incomplete
        XCTAssertFalse(set.completed)
        XCTAssertNil(set.completedAt)
    }

    // MARK: - Value Type Semantics Tests

    func testValueType_CopyDoesNotAffectOriginal() {
        // Given: An original set
        var original = TestDataFactory.createSessionSet(completed: false)

        // When: Creating a copy and modifying it
        var copy = original
        copy.toggleCompletion()
        copy.weight = 80.0

        // Then: Original should be unchanged
        XCTAssertFalse(original.completed, "Original should remain incomplete")
        XCTAssertEqual(original.weight, 60.0, "Original weight should be unchanged")

        // Copy should be modified
        XCTAssertTrue(copy.completed, "Copy should be completed")
        XCTAssertEqual(copy.weight, 80.0, "Copy weight should be modified")
    }

    // MARK: - Equatable Tests

    func testEquatable_WithSameId_AreEqual() {
        // Given: Two sets with same ID
        let id = UUID()
        let set1 = DomainSessionSet(id: id, weight: 60.0, reps: 10, orderIndex: 0)
        let set2 = DomainSessionSet(id: id, weight: 70.0, reps: 12, orderIndex: 1)

        // When/Then: Should be equal (based on ID)
        XCTAssertEqual(set1, set2, "Sets with same ID should be equal")
    }

    func testEquatable_WithDifferentIds_AreNotEqual() {
        // Given: Two sets with different IDs
        let set1 = DomainSessionSet(weight: 60.0, reps: 10, orderIndex: 0)
        let set2 = DomainSessionSet(weight: 60.0, reps: 10, orderIndex: 0)

        // When/Then: Should not be equal
        XCTAssertNotEqual(set1, set2, "Sets with different IDs should not be equal")
    }

    // MARK: - Hashable Tests

    func testHashable_CanBeUsedInSet() {
        // Given: Multiple sets
        let set1 = TestDataFactory.createSessionSet(orderIndex: 0)
        let set2 = TestDataFactory.createSessionSet(orderIndex: 1)
        let set3 = set1  // Same ID as set1

        // When: Adding to a Set
        let setCollection: Set<DomainSessionSet> = [set1, set2, set3]

        // Then: Should only contain unique sets by ID
        XCTAssertEqual(setCollection.count, 2, "Should have 2 unique sets")
    }

    func testHashable_CanBeUsedInDictionary() {
        // Given: Sets as dictionary keys
        let set1 = TestDataFactory.createSessionSet()
        let set2 = TestDataFactory.createSessionSet()

        // When: Creating dictionary
        var dictionary: [DomainSessionSet: String] = [:]
        dictionary[set1] = "Set 1"
        dictionary[set2] = "Set 2"

        // Then: Should work as keys
        XCTAssertEqual(dictionary.count, 2)
        XCTAssertEqual(dictionary[set1], "Set 1")
        XCTAssertEqual(dictionary[set2], "Set 2")
    }

    // MARK: - Edge Cases

    func testInit_WithZeroWeight_IsValid() {
        // Given/When: Creating set with zero weight
        let set = DomainSessionSet(weight: 0.0, reps: 10, orderIndex: 0)

        // Then: Should be valid (e.g., bodyweight exercises)
        XCTAssertEqual(set.weight, 0.0)
    }

    func testInit_WithZeroReps_IsValid() {
        // Given/When: Creating set with zero reps (time-based exercise)
        let set = DomainSessionSet(weight: 60.0, reps: 0, orderIndex: 0)

        // Then: Should be valid
        XCTAssertEqual(set.reps, 0)
    }

    func testInit_WithNegativeOrderIndex_IsValid() {
        // Given/When: Creating set with negative order index
        let set = DomainSessionSet(weight: 60.0, reps: 10, orderIndex: -1)

        // Then: Should be valid (though unusual)
        XCTAssertEqual(set.orderIndex, -1)
    }

    func testInit_WithVeryLargeWeight_IsValid() {
        // Given/When: Creating set with very large weight
        let set = DomainSessionSet(weight: 500.0, reps: 1, orderIndex: 0)

        // Then: Should be valid
        XCTAssertEqual(set.weight, 500.0)
    }

    func testInit_WithVeryHighReps_IsValid() {
        // Given/When: Creating set with very high reps
        let set = DomainSessionSet(weight: 20.0, reps: 100, orderIndex: 0)

        // Then: Should be valid
        XCTAssertEqual(set.reps, 100)
    }

    func testInit_WithDecimalWeight_PreservesPrecision() {
        // Given/When: Creating set with decimal weight
        let set = DomainSessionSet(weight: 62.5, reps: 10, orderIndex: 0)

        // Then: Should preserve decimal precision
        XCTAssertEqual(set.weight, 62.5, accuracy: 0.01)
    }

    // MARK: - Warmup Set Tests

    func testInit_WarmupSet_HasCorrectFlag() {
        // Given/When: Creating warmup set
        let warmupSet = DomainSessionSet(
            weight: 30.0,
            reps: 10,
            orderIndex: 0,
            isWarmup: true
        )

        // Then: Should be marked as warmup
        XCTAssertTrue(warmupSet.isWarmup)
    }

    func testToggleCompletion_OnWarmupSet_Works() {
        // Given: A warmup set
        var warmupSet = DomainSessionSet(
            weight: 30.0,
            reps: 10,
            orderIndex: 0,
            isWarmup: true
        )

        // When: Completing the warmup set
        warmupSet.toggleCompletion()

        // Then: Should complete normally
        XCTAssertTrue(warmupSet.completed)
        XCTAssertTrue(warmupSet.isWarmup, "Should still be warmup")
        XCTAssertNotNil(warmupSet.completedAt)
    }

    // MARK: - Rest Time Tests

    func testInit_WithRestTime_StoresValue() {
        // Given/When: Creating set with rest time
        let set = DomainSessionSet(
            weight: 60.0,
            reps: 10,
            orderIndex: 0,
            restTime: 120
        )

        // Then: Should store rest time
        XCTAssertEqual(set.restTime, 120)
    }

    func testInit_WithoutRestTime_IsNil() {
        // Given/When: Creating set without rest time
        let set = DomainSessionSet(weight: 60.0, reps: 10, orderIndex: 0)

        // Then: Rest time should be nil
        XCTAssertNil(set.restTime)
    }

    func testInit_WithZeroRestTime_IsValid() {
        // Given/When: Creating set with zero rest time
        let set = DomainSessionSet(
            weight: 60.0,
            reps: 10,
            orderIndex: 0,
            restTime: 0
        )

        // Then: Should be valid
        XCTAssertEqual(set.restTime, 0)
    }
}
