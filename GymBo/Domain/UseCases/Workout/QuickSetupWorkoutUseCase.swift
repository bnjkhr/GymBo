//
//  QuickSetupWorkoutUseCase.swift
//  GymBo
//
//  Created on 2025-10-26.
//  Domain Layer - Quick-Setup Workout Generation
//

import Foundation

/// Use Case for generating workouts from Quick-Setup configuration
protocol QuickSetupWorkoutUseCase {
    /// Generate workout exercises based on Quick-Setup config
    /// - Parameter config: The Quick-Setup configuration
    /// - Returns: Array of suggested WorkoutExercises (not yet saved)
    func generateWorkoutExercises(config: QuickSetupConfig) async throws -> [WorkoutExercise]
}

// MARK: - Implementation

final class DefaultQuickSetupWorkoutUseCase: QuickSetupWorkoutUseCase {

    private let exerciseRepository: ExerciseRepositoryProtocol

    init(exerciseRepository: ExerciseRepositoryProtocol) {
        self.exerciseRepository = exerciseRepository
    }

    func generateWorkoutExercises(config: QuickSetupConfig) async throws -> [WorkoutExercise] {
        // 1. Fetch all exercises
        let allExercises = try await exerciseRepository.fetchAll()

        // 2. Filter by equipment (Exercise matches ANY of the selected equipment)
        let filteredByEquipment = allExercises.filter { exercise in
            config.availableEquipment.contains { category in
                exercise.equipmentTypeRaw == category.rawValue
            }
        }

        // 3. Filter by muscle groups (based on goal)
        let filteredByGoal = filteredByEquipment.filter { exercise in
            let targetGroups = config.goal.targetMuscleGroups
            return exercise.muscleGroupsRaw.contains { muscleGroup in
                targetGroups.contains(muscleGroup)
            }
        }

        // 4. Select exercises based on duration
        let selectedExercises = selectDistributedExercises(
            from: filteredByGoal,
            count: config.duration.recommendedExerciseCount,
            goal: config.goal
        )

        // 5. Create WorkoutExercise objects with proper set/rep scheme
        let scheme = config.goal.defaultSetRepScheme
        let workoutExercises = selectedExercises.enumerated().map { index, exercise in
            WorkoutExercise(
                exerciseId: exercise.id,
                targetSets: scheme.sets,
                targetReps: scheme.reps > 0 ? scheme.reps : nil,
                targetTime: scheme.reps == 0 ? 30 : nil,  // Time-based for cardio
                targetWeight: nil,  // User will set during workout
                restTime: scheme.rest,
                perSetRestTimes: nil,
                orderIndex: index,
                notes: nil
            )
        }

        return workoutExercises
    }

    // MARK: - Private Helpers

    /// Select exercises distributed across muscle groups
    private func selectDistributedExercises(
        from exercises: [ExerciseEntity],
        count: Int,
        goal: WorkoutGoal
    ) -> [ExerciseEntity] {
        var selected: [ExerciseEntity] = []
        var usedMuscleGroups: Set<String> = []

        // Group exercises by primary muscle group
        let groupedByMuscle = Dictionary(grouping: exercises) { exercise -> String in
            exercise.muscleGroupsRaw.first ?? "Unknown"
        }

        // Priority order based on goal
        let muscleGroupPriority = goal.targetMuscleGroups

        // First pass: Select one exercise per muscle group (priority order)
        for muscleGroup in muscleGroupPriority {
            guard selected.count < count else { break }

            if let exercisesForGroup = groupedByMuscle[muscleGroup],
                let exercise = exercisesForGroup.randomElement()
            {
                selected.append(exercise)
                usedMuscleGroups.insert(muscleGroup)
            }
        }

        // Second pass: Fill remaining slots with any exercises (avoid duplicates)
        let remainingCount = count - selected.count
        if remainingCount > 0 {
            let remainingExercises =
                exercises
                .filter { !selected.contains($0) }
                .shuffled()
                .prefix(remainingCount)

            selected.append(contentsOf: remainingExercises)
        }

        return selected
    }
}

// MARK: - Errors

enum QuickSetupError: LocalizedError {
    case notEnoughExercises(available: Int, required: Int)

    var errorDescription: String? {
        switch self {
        case .notEnoughExercises(let available, let required):
            return "Nicht genug Übungen verfügbar. Benötigt: \(required), Verfügbar: \(available)"
        }
    }
}
