//
//  SessionExerciseGroupMapper.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V6 Clean Architecture - Data Layer
//

import Foundation
import SwiftData

/// Mapper for converting between Domain SessionExerciseGroup entities and SwiftData entities
///
/// **Responsibility:**
/// - Map Domain/SessionExerciseGroup → Data/SessionExerciseGroupEntity (for persistence)
/// - Map Data/SessionExerciseGroupEntity → Domain/SessionExerciseGroup (for business logic)
/// - Handle SessionExercise mapping within groups
/// - Maintain relationship integrity
///
/// **Design Decisions:**
/// - Stateless struct - No stored state
/// - Pure functions - No side effects
/// - Bidirectional mapping
///
/// **Usage:**
/// ```swift
/// let mapper = SessionExerciseGroupMapper()
/// let entity = mapper.toEntity(group)
/// let domain = mapper.toDomain(entity)
/// ```
struct SessionExerciseGroupMapper {

    // MARK: - SessionExerciseGroup Mapping

    /// Convert Domain SessionExerciseGroup to SwiftData Entity
    /// - Parameter domain: Domain session exercise group
    /// - Returns: SwiftData entity ready for persistence
    func toEntity(_ domain: SessionExerciseGroup) -> SessionExerciseGroupEntity {
        let entity = SessionExerciseGroupEntity(
            id: domain.id,
            groupIndex: domain.groupIndex,
            restAfterGroup: domain.restAfterGroup,
            exercises: [],  // Will be set below
            currentRound: domain.currentRound,
            totalRounds: domain.totalRounds
        )

        // Map exercises
        entity.exercises = domain.exercises.map { exercise in
            let exerciseEntity = toEntityExercise(exercise, groupId: domain.id)
            exerciseEntity.group = entity
            return exerciseEntity
        }

        return entity
    }

    /// Convert SwiftData Entity to Domain SessionExerciseGroup
    /// - Parameter entity: SwiftData entity
    /// - Returns: Domain session exercise group for business logic
    func toDomain(_ entity: SessionExerciseGroupEntity) -> SessionExerciseGroup {
        SessionExerciseGroup(
            id: entity.id,
            exercises: entity.exercises
                .sorted(by: { $0.orderIndex < $1.orderIndex })
                .map { toDomainSessionExercise($0) },
            groupIndex: entity.groupIndex,
            currentRound: entity.currentRound,
            totalRounds: entity.totalRounds,
            restAfterGroup: entity.restAfterGroup
        )
    }

    /// Update existing entity with domain data (for in-place updates)
    /// - Parameters:
    ///   - entity: Existing SwiftData entity
    ///   - domain: Domain session exercise group with updated data
    func updateEntity(_ entity: SessionExerciseGroupEntity, from domain: SessionExerciseGroup) {
        entity.groupIndex = domain.groupIndex
        entity.restAfterGroup = domain.restAfterGroup
        entity.currentRound = domain.currentRound
        entity.totalRounds = domain.totalRounds

        // Update exercises IN-PLACE to preserve SwiftData relationships
        for domainExercise in domain.exercises {
            if let existingExercise = entity.exercises.first(where: { $0.id == domainExercise.id })
            {
                // Update existing exercise
                updateExerciseEntity(existingExercise, from: domainExercise)
            } else {
                // Add new exercise (shouldn't happen during normal workflow)
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

    /// Convert SessionExerciseEntity to Domain SessionExercise
    private func toDomainSessionExercise(_ entity: SessionExerciseEntity) -> DomainSessionExercise {
        DomainSessionExercise(
            id: entity.id,
            exerciseId: entity.exerciseId,
            exerciseName: entity.exerciseName,
            sets: entity.sets.sorted(by: { $0.orderIndex < $1.orderIndex }).map {
                toDomainSessionSet($0)
            },
            notes: entity.notes,
            restTimeToNext: entity.restTimeToNext,
            orderIndex: entity.orderIndex,
            isFinished: entity.isFinished
        )
    }

    /// Convert SessionSetEntity to Domain SessionSet
    private func toDomainSessionSet(_ entity: SessionSetEntity) -> DomainSessionSet {
        DomainSessionSet(
            id: entity.id,
            weight: entity.weight,
            reps: entity.reps,
            completed: entity.completed,
            completedAt: entity.completedAt,
            orderIndex: entity.orderIndex,
            restTime: entity.restTime,
            isWarmup: entity.isWarmup
        )
    }

    /// Convert Domain SessionExercise to Entity (for group exercises)
    private func toEntityExercise(
        _ domain: DomainSessionExercise, groupId: UUID
    ) -> SessionExerciseEntity {
        let entity = SessionExerciseEntity(
            id: domain.id,
            exerciseId: domain.exerciseId,
            exerciseName: domain.exerciseName,
            notes: domain.notes,
            restTimeToNext: domain.restTimeToNext,
            orderIndex: domain.orderIndex,
            isFinished: domain.isFinished,
            sets: [],
            groupId: groupId
        )

        // Map sets
        entity.sets = domain.sets.map { set in
            let setEntity = SessionSetEntity(
                id: set.id,
                weight: set.weight,
                reps: set.reps,
                completed: set.completed,
                completedAt: set.completedAt,
                orderIndex: set.orderIndex,
                restTime: set.restTime,
                isWarmup: set.isWarmup
            )
            setEntity.exercise = entity
            return setEntity
        }

        return entity
    }

    /// Update existing exercise entity
    private func updateExerciseEntity(
        _ entity: SessionExerciseEntity, from domain: DomainSessionExercise
    ) {
        entity.exerciseId = domain.exerciseId
        entity.exerciseName = domain.exerciseName
        entity.notes = domain.notes
        entity.restTimeToNext = domain.restTimeToNext
        entity.orderIndex = domain.orderIndex
        entity.isFinished = domain.isFinished

        // Update sets IN-PLACE
        for domainSet in domain.sets {
            if let existingSet = entity.sets.first(where: { $0.id == domainSet.id }) {
                // Update existing set
                updateSetEntity(existingSet, from: domainSet)
            } else {
                // Add new set
                let newSet = SessionSetEntity(
                    id: domainSet.id,
                    weight: domainSet.weight,
                    reps: domainSet.reps,
                    completed: domainSet.completed,
                    completedAt: domainSet.completedAt,
                    orderIndex: domainSet.orderIndex,
                    restTime: domainSet.restTime,
                    isWarmup: domainSet.isWarmup
                )
                newSet.exercise = entity
                entity.sets.append(newSet)
            }
        }

        // Remove sets that are no longer in domain
        let domainSetIds = Set(domain.sets.map { $0.id })
        entity.sets.removeAll { !domainSetIds.contains($0.id) }
    }

    /// Update existing set entity
    private func updateSetEntity(_ entity: SessionSetEntity, from domain: DomainSessionSet) {
        entity.weight = domain.weight
        entity.reps = domain.reps
        entity.completed = domain.completed
        entity.completedAt = domain.completedAt
        entity.orderIndex = domain.orderIndex
        entity.restTime = domain.restTime
        entity.isWarmup = domain.isWarmup
    }

    // MARK: - Batch Mapping

    /// Convert array of SwiftData entities to Domain session exercise groups
    func toDomain(_ entities: [SessionExerciseGroupEntity]) -> [SessionExerciseGroup] {
        entities.map { toDomain($0) }
    }
}
