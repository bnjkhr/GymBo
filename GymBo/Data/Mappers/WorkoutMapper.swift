//
//  WorkoutMapper.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Data Layer
//

import Foundation
import SwiftData

/// Mapper for converting between Domain Workout entities and SwiftData entities
///
/// **Responsibility:**
/// - Map Domain/Workout → Data/WorkoutEntity (for persistence)
/// - Map Data/WorkoutEntity → Domain/Workout (for business logic)
/// - Handle WorkoutExercise mapping
/// - Maintain relationship integrity
///
/// **Design Decisions:**
/// - Stateless struct - No stored state
/// - Pure functions - No side effects
/// - Bidirectional mapping
///
/// **Usage:**
/// ```swift
/// let mapper = WorkoutMapper()
/// let entity = mapper.toEntity(workout)
/// let domain = mapper.toDomain(entity)
/// ```
struct WorkoutMapper {

    // MARK: - Workout Mapping

    /// Convert Domain Workout to SwiftData Entity
    /// - Parameter domain: Domain workout
    /// - Returns: SwiftData entity ready for persistence
    func toEntity(_ domain: Workout) -> WorkoutEntity {
        let entity = WorkoutEntity(
            id: domain.id,
            name: domain.name,
            date: domain.createdAt,
            exercises: [],
            defaultRestTime: domain.defaultRestTime,
            duration: nil,
            notes: domain.notes ?? "",
            isFavorite: domain.isFavorite,
            isSampleWorkout: nil
        )

        // Map exercises
        entity.exercises = domain.exercises.enumerated().map { index, exercise in
            let exerciseEntity = toEntity(exercise, orderIndex: index)
            exerciseEntity.workout = entity
            return exerciseEntity
        }

        // Update cached exercise count
        entity.exerciseCount = domain.exercises.count

        return entity
    }

    /// Convert SwiftData Entity to Domain Workout
    /// - Parameter entity: SwiftData entity
    /// - Returns: Domain workout for business logic
    func toDomain(_ entity: WorkoutEntity) -> Workout {
        Workout(
            id: entity.id,
            name: entity.name,
            exercises: entity.exercises
                .sorted(by: { $0.order < $1.order })
                .map { toDomain($0) },
            defaultRestTime: entity.defaultRestTime,
            notes: entity.notes.isEmpty ? nil : entity.notes,
            createdAt: entity.date,
            updatedAt: entity.date,
            isFavorite: entity.isFavorite
        )
    }

    /// Update existing entity with domain data (for in-place updates)
    /// - Parameters:
    ///   - entity: Existing SwiftData entity
    ///   - domain: Domain workout with updated data
    func updateEntity(_ entity: WorkoutEntity, from domain: Workout) {
        entity.name = domain.name
        entity.defaultRestTime = domain.defaultRestTime
        entity.notes = domain.notes ?? ""
        entity.isFavorite = domain.isFavorite
        entity.date = domain.updatedAt

        // Update exercises IN-PLACE to preserve SwiftData relationships
        // Match by ID and update existing entities
        for domainExercise in domain.exercises {
            if let existingExercise = entity.exercises.first(where: { $0.id == domainExercise.id })
            {
                // Update existing exercise
                updateExerciseEntity(existingExercise, from: domainExercise)
            } else {
                // Add new exercise
                let newExercise = toEntity(domainExercise, orderIndex: domainExercise.orderIndex)
                newExercise.workout = entity
                entity.exercises.append(newExercise)
            }
        }

        // Remove exercises that are no longer in domain
        let domainExerciseIds = Set(domain.exercises.map { $0.id })
        entity.exercises.removeAll { !domainExerciseIds.contains($0.id) }

        entity.exerciseCount = domain.exercises.count
    }

    /// Update existing exercise entity with domain data
    /// - Parameters:
    ///   - entity: Existing SwiftData entity
    ///   - domain: Domain workout exercise with updated data
    private func updateExerciseEntity(_ entity: WorkoutExerciseEntity, from domain: WorkoutExercise)
    {
        entity.order = domain.orderIndex
        entity.notes = domain.notes

        // Note: We don't update exerciseId, as the exercise reference is immutable
        // The entity's exercise relationship is managed separately by the repository

        // Update sets - for workout templates, sets represent target values
        // Clear and rebuild sets as they define the template structure
        entity.sets.removeAll()
        for _ in 0..<domain.targetSets {
            // For time-based exercises (targetTime != nil), store 0 reps
            // For rep-based exercises, store targetReps
            let reps = domain.targetReps ?? 0

            let setEntity = ExerciseSetEntity(
                id: UUID(),
                reps: reps,
                weight: domain.targetWeight ?? 0.0,
                restTime: domain.restTime ?? 90,
                completed: false
            )
            setEntity.owner = entity
            entity.sets.append(setEntity)
        }
    }

    // MARK: - WorkoutExercise Mapping

    /// Convert Domain WorkoutExercise to SwiftData Entity
    /// - Parameters:
    ///   - domain: Domain workout exercise
    ///   - orderIndex: Position in workout
    /// - Returns: SwiftData entity
    private func toEntity(_ domain: WorkoutExercise, orderIndex: Int) -> WorkoutExerciseEntity {
        let entity = WorkoutExerciseEntity(
            id: domain.id,
            exerciseId: domain.exerciseId,  // Store exerciseId directly for reliable lookups
            exercise: nil,  // Will be set by repository when loading exercise catalog
            sets: [],
            workout: nil,
            session: nil,
            order: orderIndex,
            notes: domain.notes
        )

        // Create sets based on target values
        for _ in 0..<domain.targetSets {
            // For time-based exercises (targetTime != nil), store 0 reps
            // For rep-based exercises, store targetReps
            let reps = domain.targetReps ?? 0

            let setEntity = ExerciseSetEntity(
                id: UUID(),
                reps: reps,
                weight: domain.targetWeight ?? 0.0,
                restTime: domain.restTime ?? 90,
                completed: false
            )
            setEntity.owner = entity
            entity.sets.append(setEntity)
        }

        return entity
    }

    /// Convert SwiftData Entity to Domain WorkoutExercise
    /// - Parameter entity: SwiftData entity
    /// - Returns: Domain workout exercise
    private func toDomain(_ entity: WorkoutExerciseEntity) -> WorkoutExercise {
        // Extract target values from first set (template pattern)
        let firstSet = entity.sets.first

        // Get exerciseId: prefer direct field, fallback to relationship, then generate placeholder
        let exerciseId = entity.exerciseId ?? entity.exercise?.id ?? UUID()

        // If reps is 0, this is a time-based exercise
        // Note: We can't store targetTime in current schema, so for now we lose that info on reload
        // TODO: Add targetTime field to ExerciseSetEntity in future schema version
        let reps = firstSet?.reps ?? 8
        let targetReps = reps > 0 ? reps : nil
        let targetTime: TimeInterval? = reps == 0 ? 60 : nil  // Default 60s for time-based

        return WorkoutExercise(
            id: entity.id,
            exerciseId: exerciseId,
            targetSets: entity.sets.count,
            targetReps: targetReps,
            targetTime: targetTime,
            targetWeight: firstSet?.weight,
            restTime: firstSet?.restTime,
            orderIndex: entity.order,
            notes: entity.notes
        )
    }

    // MARK: - Batch Mapping

    /// Convert array of SwiftData entities to Domain workouts
    /// - Parameter entities: Array of SwiftData entities
    /// - Returns: Array of domain workouts
    func toDomain(_ entities: [WorkoutEntity]) -> [Workout] {
        entities.map { toDomain($0) }
    }
}
