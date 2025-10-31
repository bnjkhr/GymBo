//
//  ExerciseGroupMapper.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V6 Clean Architecture - Data Layer
//

import Foundation
import SwiftData

/// Mapper for converting between Domain ExerciseGroup entities and SwiftData entities
///
/// **Responsibility:**
/// - Map Domain/ExerciseGroup → Data/ExerciseGroupEntity (for persistence)
/// - Map Data/ExerciseGroupEntity → Domain/ExerciseGroup (for business logic)
/// - Handle WorkoutExercise mapping within groups
/// - Maintain relationship integrity
///
/// **Design Decisions:**
/// - Stateless struct - No stored state
/// - Pure functions - No side effects
/// - Bidirectional mapping
///
/// **Usage:**
/// ```swift
/// let mapper = ExerciseGroupMapper()
/// let entity = mapper.toEntity(group)
/// let domain = mapper.toDomain(entity)
/// ```
struct ExerciseGroupMapper {

    // MARK: - ExerciseGroup Mapping

    /// Convert Domain ExerciseGroup to SwiftData Entity
    /// - Parameter domain: Domain exercise group
    /// - Returns: SwiftData entity ready for persistence
    func toEntity(_ domain: ExerciseGroup) -> ExerciseGroupEntity {
        let entity = ExerciseGroupEntity(
            id: domain.id,
            groupIndex: domain.groupIndex,
            restAfterGroup: domain.restAfterGroup,
            exercises: []  // Will be set below
        )

        // Map exercises - need to handle WorkoutExercise mapping
        // Note: We need access to WorkoutMapper's private method, so we'll create exercises directly
        entity.exercises = domain.exercises.enumerated().map { index, exercise in
            let exerciseEntity = WorkoutExerciseEntity(
                id: exercise.id,
                exerciseId: exercise.exerciseId,
                exercise: nil,  // Will be set by repository
                sets: [],  // Will be created below
                workout: nil,  // Will be set by parent workout
                session: nil,
                order: exercise.orderIndex,
                notes: exercise.notes,
                groupId: domain.id  // Link to this group
            )

            // Create sets for this exercise
            for setIndex in 0..<exercise.targetSets {
                let reps = exercise.targetReps ?? 0
                let restTime: TimeInterval
                if let perSetRestTimes = exercise.perSetRestTimes, setIndex < perSetRestTimes.count
                {
                    restTime = perSetRestTimes[setIndex]
                } else {
                    restTime = exercise.restTime ?? 90
                }

                let setEntity = ExerciseSetEntity(
                    id: UUID(),
                    reps: reps,
                    weight: exercise.targetWeight ?? 0.0,
                    restTime: restTime,
                    completed: false
                )
                setEntity.owner = exerciseEntity
                exerciseEntity.sets.append(setEntity)
            }

            exerciseEntity.group = entity
            return exerciseEntity
        }

        return entity
    }

    /// Convert SwiftData Entity to Domain ExerciseGroup
    /// - Parameter entity: SwiftData entity
    /// - Returns: Domain exercise group for business logic
    func toDomain(_ entity: ExerciseGroupEntity) -> ExerciseGroup {
        ExerciseGroup(
            id: entity.id,
            exercises: entity.exercises
                .sorted(by: { $0.order < $1.order })
                .map { toDomainWorkoutExercise($0) },
            groupIndex: entity.groupIndex,
            restAfterGroup: entity.restAfterGroup
        )
    }

    /// Update existing entity with domain data (for in-place updates)
    /// - Parameters:
    ///   - entity: Existing SwiftData entity
    ///   - domain: Domain exercise group with updated data
    func updateEntity(_ entity: ExerciseGroupEntity, from domain: ExerciseGroup) {
        entity.groupIndex = domain.groupIndex
        entity.restAfterGroup = domain.restAfterGroup

        // Update exercises IN-PLACE to preserve SwiftData relationships
        for domainExercise in domain.exercises {
            if let existingExercise = entity.exercises.first(where: { $0.id == domainExercise.id })
            {
                // Update existing exercise
                updateExerciseEntity(existingExercise, from: domainExercise)
            } else {
                // Add new exercise
                let newExercise = toEntityExercise(domainExercise, groupId: domain.id)
                newExercise.group = entity
                entity.exercises.append(newExercise)
            }
        }

        // Remove exercises that are no longer in domain
        let domainExerciseIds = Set(domain.exercises.map { $0.id })
        entity.exercises.removeAll { !domainExerciseIds.contains($0.id) }
    }

    // MARK: - Private Helpers

    /// Convert WorkoutExerciseEntity to Domain WorkoutExercise
    private func toDomainWorkoutExercise(_ entity: WorkoutExerciseEntity) -> WorkoutExercise {
        let firstSet = entity.sets.first
        let exerciseId = entity.exerciseId ?? entity.exercise?.id ?? UUID()

        let reps = firstSet?.reps ?? 8
        let targetReps = reps > 0 ? reps : nil
        let targetTime: TimeInterval? = reps == 0 ? 60 : nil

        // Check for per-set rest times
        let restTimes = entity.sets.compactMap { $0.restTime }
        let hasIndividualRestTimes: Bool
        if restTimes.isEmpty || restTimes.count < 2 {
            hasIndividualRestTimes = false
        } else {
            let firstRestTime = restTimes.first!
            hasIndividualRestTimes = !restTimes.allSatisfy { $0 == firstRestTime }
        }

        let perSetRestTimes: [TimeInterval]? = hasIndividualRestTimes ? restTimes : nil
        let restTime: TimeInterval? = firstSet?.restTime

        return WorkoutExercise(
            id: entity.id,
            exerciseId: exerciseId,
            targetSets: entity.sets.count,
            targetReps: targetReps,
            targetTime: targetTime,
            targetWeight: firstSet?.weight,
            restTime: restTime,
            perSetRestTimes: perSetRestTimes,
            orderIndex: entity.order,
            notes: entity.notes
        )
    }

    /// Convert Domain WorkoutExercise to Entity (for group exercises)
    private func toEntityExercise(
        _ domain: WorkoutExercise, groupId: UUID
    ) -> WorkoutExerciseEntity {
        let entity = WorkoutExerciseEntity(
            id: domain.id,
            exerciseId: domain.exerciseId,
            exercise: nil,
            sets: [],
            workout: nil,
            session: nil,
            order: domain.orderIndex,
            notes: domain.notes,
            groupId: groupId
        )

        // Create sets
        for setIndex in 0..<domain.targetSets {
            let reps = domain.targetReps ?? 0
            let restTime: TimeInterval
            if let perSetRestTimes = domain.perSetRestTimes, setIndex < perSetRestTimes.count {
                restTime = perSetRestTimes[setIndex]
            } else {
                restTime = domain.restTime ?? 90
            }

            let setEntity = ExerciseSetEntity(
                id: UUID(),
                reps: reps,
                weight: domain.targetWeight ?? 0.0,
                restTime: restTime,
                completed: false
            )
            setEntity.owner = entity
            entity.sets.append(setEntity)
        }

        return entity
    }

    /// Update existing exercise entity
    private func updateExerciseEntity(
        _ entity: WorkoutExerciseEntity, from domain: WorkoutExercise
    ) {
        entity.order = domain.orderIndex
        entity.notes = domain.notes
        entity.exerciseId = domain.exerciseId

        // Update sets
        entity.sets.removeAll()
        for setIndex in 0..<domain.targetSets {
            let reps = domain.targetReps ?? 0
            let restTime: TimeInterval
            if let perSetRestTimes = domain.perSetRestTimes, setIndex < perSetRestTimes.count {
                restTime = perSetRestTimes[setIndex]
            } else {
                restTime = domain.restTime ?? 90
            }

            let setEntity = ExerciseSetEntity(
                id: UUID(),
                reps: reps,
                weight: domain.targetWeight ?? 0.0,
                restTime: restTime,
                completed: false
            )
            setEntity.owner = entity
            entity.sets.append(setEntity)
        }
    }

    // MARK: - Batch Mapping

    /// Convert array of SwiftData entities to Domain exercise groups
    func toDomain(_ entities: [ExerciseGroupEntity]) -> [ExerciseGroup] {
        entities.map { toDomain($0) }
    }
}
