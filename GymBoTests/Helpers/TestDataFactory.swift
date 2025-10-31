//
//  TestDataFactory.swift
//  GymBoTests
//
//  Created for testing purposes
//  Factory for creating test data objects
//

import Foundation

@testable import GymBo

/// Factory for creating test data objects with sensible defaults
///
/// **Usage:**
/// ```swift
/// let workout = TestDataFactory.createWorkout(name: "Push Day")
/// let session = TestDataFactory.createSession(workoutId: workout.id)
/// let exercise = TestDataFactory.createExercise(name: "Bench Press")
/// ```
enum TestDataFactory {

    // MARK: - Workouts

    static func createWorkout(
        id: UUID = UUID(),
        name: String = "Test Workout",
        exercises: [WorkoutExercise] = [],
        defaultRestTime: TimeInterval = 90,
        notes: String? = nil,
        isFavorite: Bool = false,
        folderId: UUID? = nil,
        workoutType: WorkoutType = .standard,
        exerciseGroups: [ExerciseGroup]? = nil
    ) -> Workout {
        return Workout(
            id: id,
            name: name,
            exercises: exercises,
            defaultRestTime: defaultRestTime,
            notes: notes,
            createdAt: Date(),
            updatedAt: Date(),
            isFavorite: isFavorite,
            difficultyLevel: nil,
            equipmentType: nil,
            folderId: folderId,
            orderInFolder: 0,
            warmupStrategy: nil,
            workoutType: workoutType,
            exerciseGroups: exerciseGroups
        )
    }

    static func createWorkoutExercise(
        id: UUID = UUID(),
        exerciseId: UUID = UUID(),
        targetSets: Int = 3,
        targetReps: Int? = 10,
        targetWeight: Double? = 50.0,
        restTime: TimeInterval? = 90,
        perSetRestTimes: [TimeInterval]? = nil,
        orderIndex: Int = 0,
        notes: String? = nil
    ) -> WorkoutExercise {
        return WorkoutExercise(
            id: id,
            exerciseId: exerciseId,
            targetSets: targetSets,
            targetReps: targetReps,
            targetTime: nil,
            targetWeight: targetWeight,
            restTime: restTime,
            perSetRestTimes: perSetRestTimes,
            orderIndex: orderIndex,
            notes: notes
        )
    }

    static func createExerciseGroup(
        id: UUID = UUID(),
        exercises: [WorkoutExercise] = [],
        groupIndex: Int = 0,
        restAfterGroup: TimeInterval = 120
    ) -> ExerciseGroup {
        return ExerciseGroup(
            id: id,
            exercises: exercises,
            groupIndex: groupIndex,
            restAfterGroup: restAfterGroup
        )
    }

    // MARK: - Exercises

    static func createExercise(
        id: UUID = UUID(),
        name: String = "Bench Press",
        muscleGroups: [String] = ["Chest"],
        equipment: String = "Barbell",
        difficulty: String = "Intermediate",
        lastUsedWeight: Double? = 60.0,
        lastUsedReps: Int? = 10
    ) -> ExerciseEntity {
        return ExerciseEntity(
            id: id,
            name: name,
            muscleGroupsRaw: muscleGroups,
            equipmentTypeRaw: equipment,
            difficultyLevelRaw: difficulty,
            descriptionText: "",
            instructions: [],
            lastUsedWeight: lastUsedWeight,
            lastUsedReps: lastUsedReps
        )
    }

    // MARK: - Sessions

    static func createSession(
        id: UUID = UUID(),
        workoutId: UUID = UUID(),
        workoutName: String = "Test Workout",
        startDate: Date = Date(),
        endDate: Date? = nil,
        exercises: [DomainSessionExercise] = [],
        state: DomainWorkoutSession.SessionState = .active,
        healthKitSessionId: String? = nil
    ) -> DomainWorkoutSession {
        return DomainWorkoutSession(
            id: id,
            workoutId: workoutId,
            startDate: startDate,
            endDate: endDate,
            exercises: exercises,
            state: state,
            workoutName: workoutName,
            healthKitSessionId: healthKitSessionId
        )
    }

    static func createSessionExercise(
        id: UUID = UUID(),
        exerciseId: UUID = UUID(),
        exerciseName: String = "Bench Press",
        sets: [DomainSessionSet] = [],
        notes: String? = nil,
        restTimeToNext: TimeInterval? = 90,
        orderIndex: Int = 0,
        isFinished: Bool = false
    ) -> DomainSessionExercise {
        let defaultSets =
            sets.isEmpty
            ? [
                createSessionSet(orderIndex: 0),
                createSessionSet(orderIndex: 1),
                createSessionSet(orderIndex: 2),
            ] : sets

        return DomainSessionExercise(
            id: id,
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            sets: defaultSets,
            notes: notes,
            restTimeToNext: restTimeToNext,
            orderIndex: orderIndex,
            isFinished: isFinished
        )
    }

    static func createSessionSet(
        id: UUID = UUID(),
        weight: Double = 60.0,
        reps: Int = 10,
        completed: Bool = false,
        completedAt: Date? = nil,
        orderIndex: Int = 0,
        restTime: TimeInterval? = 90,
        isWarmup: Bool = false
    ) -> DomainSessionSet {
        return DomainSessionSet(
            id: id,
            weight: weight,
            reps: reps,
            completed: completed,
            completedAt: completedAt,
            orderIndex: orderIndex,
            restTime: restTime,
            isWarmup: isWarmup
        )
    }

    static func createSessionExerciseGroup(
        id: UUID = UUID(),
        exercises: [DomainSessionExercise] = [],
        groupIndex: Int = 0,
        currentRound: Int = 1,
        totalRounds: Int = 3,
        restAfterGroup: TimeInterval = 120
    ) -> SessionExerciseGroup {
        return SessionExerciseGroup(
            id: id,
            exercises: exercises,
            groupIndex: groupIndex,
            currentRound: currentRound,
            totalRounds: totalRounds,
            restAfterGroup: restAfterGroup
        )
    }

    // MARK: - User Profile

    static func createUserProfile(
        id: UUID = UUID(),
        name: String? = "Test User",
        age: Int? = 25,
        bodyMass: Double? = 75.0,
        height: Double? = 180.0,
        weeklyWorkoutGoal: Int = 4,
        profileImageData: Data? = nil
    ) -> DomainUserProfile {
        return DomainUserProfile(
            id: id,
            name: name,
            profileImageData: profileImageData,
            age: age,
            experienceLevel: nil,
            fitnessGoal: nil,
            bodyMass: bodyMass,
            height: height,
            weeklyWorkoutGoal: weeklyWorkoutGoal,
            healthKitEnabled: false,
            appTheme: .system,
            notificationsEnabled: true,
            liveActivityEnabled: true
        )
    }

    // MARK: - Workout Folder

    static func createWorkoutFolder(
        id: UUID = UUID(),
        name: String = "Test Folder",
        color: String = "blue",
        order: Int = 0
    ) -> WorkoutFolder {
        return WorkoutFolder(
            id: id,
            name: name,
            color: color,
            order: order
        )
    }

    // MARK: - Complex Test Scenarios

    /// Create a complete workout with exercises
    static func createCompleteWorkout(
        name: String = "Test Workout",
        exerciseCount: Int = 3
    ) -> Workout {
        let exercises = (0..<exerciseCount).map { index in
            createWorkoutExercise(
                exerciseId: UUID(),
                targetSets: 3,
                targetReps: 10,
                targetWeight: 50.0 + Double(index * 10),
                restTime: 90,
                orderIndex: index
            )
        }

        return createWorkout(name: name, exercises: exercises)
    }

    /// Create an active session with exercises and sets
    static func createActiveSession(
        workoutName: String = "Test Workout",
        exerciseCount: Int = 3,
        setsPerExercise: Int = 3,
        startDate: Date = Date()
    ) -> DomainWorkoutSession {
        let exercises = (0..<exerciseCount).map { exerciseIndex in
            let sets = (0..<setsPerExercise).map { setIndex in
                createSessionSet(orderIndex: setIndex)
            }
            return createSessionExercise(
                exerciseName: "Exercise \(exerciseIndex + 1)",
                sets: sets,
                orderIndex: exerciseIndex
            )
        }

        return createSession(
            workoutName: workoutName,
            startDate: startDate,
            exercises: exercises,
            state: .active
        )
    }

    /// Create a completed session with all sets marked as completed
    static func createCompletedSession(
        workoutName: String = "Test Workout",
        exerciseCount: Int = 3,
        setsPerExercise: Int = 3,
        startDate: Date = Date().addingTimeInterval(-3600),
        endDate: Date = Date()
    ) -> DomainWorkoutSession {
        let exercises = (0..<exerciseCount).map { exerciseIndex in
            let sets = (0..<setsPerExercise).map { setIndex in
                createSessionSet(
                    completed: true,
                    completedAt: startDate.addingTimeInterval(
                        Double(exerciseIndex * 300 + setIndex * 100)),
                    orderIndex: setIndex
                )
            }
            return createSessionExercise(
                exerciseName: "Exercise \(exerciseIndex + 1)",
                sets: sets,
                orderIndex: exerciseIndex,
                isFinished: true
            )
        }

        return createSession(
            workoutName: workoutName,
            startDate: startDate,
            endDate: endDate,
            exercises: exercises,
            state: .completed
        )
    }

    /// Create a superset workout with 2 groups
    static func createSupersetWorkout(
        name: String = "Superset Workout"
    ) -> Workout {
        // Create workout exercises for two supersets
        let group1Exercise1 = createWorkoutExercise(exerciseId: UUID(), orderIndex: 0)
        let group1Exercise2 = createWorkoutExercise(exerciseId: UUID(), orderIndex: 1)
        let group2Exercise1 = createWorkoutExercise(exerciseId: UUID(), orderIndex: 2)
        let group2Exercise2 = createWorkoutExercise(exerciseId: UUID(), orderIndex: 3)

        let groups = [
            createExerciseGroup(
                exercises: [group1Exercise1, group1Exercise2],
                groupIndex: 0,
                restAfterGroup: 120
            ),
            createExerciseGroup(
                exercises: [group2Exercise1, group2Exercise2],
                groupIndex: 1,
                restAfterGroup: 120
            ),
        ]

        let allExercises = [group1Exercise1, group1Exercise2, group2Exercise1, group2Exercise2]

        return createWorkout(
            name: name,
            exercises: allExercises,
            folderId: nil,
            workoutType: .superset,
            exerciseGroups: groups
        )
    }
}
