//
//  SessionMapper.swift
//  GymTracker
//
//  Created on 2025-10-22.
//  V2 Clean Architecture - Data Layer
//

import Foundation
import SwiftData

/// Mapper for converting between Domain entities and SwiftData entities
///
/// **Responsibility:**
/// - Map Domain/Entities → Data/Entities (for persistence)
/// - Map Data/Entities → Domain/Entities (for business logic)
/// - Handle all type conversions
/// - Maintain relationship integrity
///
/// **Design Decisions:**
/// - Stateless struct - No stored state
/// - Pure functions - No side effects
/// - Bidirectional mapping - toDomain() and toEntity()
///
/// **Usage:**
/// ```swift
/// let mapper = SessionMapper()
/// let entity = mapper.toEntity(domainSession)
/// let domain = mapper.toDomain(entity)
/// ```
struct SessionMapper {

    // MARK: - DomainWorkoutSession Mapping

    /// Convert Domain DomainWorkoutSession to SwiftData Entity
    /// - Parameter domain: Domain entity
    /// - Returns: SwiftData entity ready for persistence
    func toEntity(_ domain: DomainWorkoutSession) -> WorkoutSessionEntity {
        let entity = WorkoutSessionEntity(
            id: domain.id,
            workoutId: domain.workoutId,
            startDate: domain.startDate,
            endDate: domain.endDate,
            state: domain.state.rawValue,
            workoutName: domain.workoutName,
            healthKitSessionId: domain.healthKitSessionId,
            exercises: []  // Will be set below
        )

        // Map exercises
        entity.exercises = domain.exercises.map { exercise in
            let exerciseEntity = toEntity(exercise)
            exerciseEntity.session = entity
            return exerciseEntity
        }

        return entity
    }

    /// Convert SwiftData Entity to Domain DomainWorkoutSession
    /// - Parameter entity: SwiftData entity
    /// - Returns: Domain entity for business logic
    func toDomain(_ entity: WorkoutSessionEntity) -> DomainWorkoutSession {
        DomainWorkoutSession(
            id: entity.id,
            workoutId: entity.workoutId,
            startDate: entity.startDate,
            endDate: entity.endDate,
            exercises: entity.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }).map {
                toDomain($0)
            },
            state: DomainWorkoutSession.SessionState(rawValue: entity.state) ?? .active,
            workoutName: entity.workoutName,
            healthKitSessionId: entity.healthKitSessionId
        )
    }

    /// Update existing entity with domain data
    /// - Parameters:
    ///   - entity: Existing SwiftData entity to update
    ///   - domain: Domain entity with new data
    func updateEntity(_ entity: WorkoutSessionEntity, from domain: DomainWorkoutSession) {
        entity.workoutId = domain.workoutId
        entity.startDate = domain.startDate
        entity.endDate = domain.endDate
        entity.state = domain.state.rawValue
        entity.workoutName = domain.workoutName
        entity.healthKitSessionId = domain.healthKitSessionId

        // Update exercises IN-PLACE to preserve SwiftData relationships
        // Match by ID and update existing entities
        for domainExercise in domain.exercises {
            if let existingExercise = entity.exercises.first(where: { $0.id == domainExercise.id })
            {
                // Update existing exercise
                updateExerciseEntity(existingExercise, from: domainExercise)
            } else {
                // Add new exercise (shouldn't happen during set completion, but handle it)
                let newExercise = toEntity(domainExercise)
                newExercise.session = entity
                entity.exercises.append(newExercise)
            }
        }

        // Remove exercises that are no longer in domain
        let domainExerciseIds = Set(domain.exercises.map { $0.id })
        entity.exercises.removeAll { !domainExerciseIds.contains($0.id) }
    }

    /// Update existing exercise entity with domain data
    private func updateExerciseEntity(
        _ entity: SessionExerciseEntity, from domain: DomainSessionExercise
    ) {
        entity.exerciseId = domain.exerciseId
        entity.notes = domain.notes
        entity.restTimeToNext = domain.restTimeToNext
        entity.orderIndex = domain.orderIndex  // ✅ Update orderIndex for reordering
        entity.isFinished = domain.isFinished

        // Update sets IN-PLACE
        for domainSet in domain.sets {
            if let existingSet = entity.sets.first(where: { $0.id == domainSet.id }) {
                // Update existing set
                updateSetEntity(existingSet, from: domainSet)
            } else {
                // Add new set
                let newSet = toEntity(domainSet)
                newSet.exercise = entity
                entity.sets.append(newSet)
            }
        }

        // Remove sets that are no longer in domain
        let domainSetIds = Set(domain.sets.map { $0.id })
        entity.sets.removeAll { !domainSetIds.contains($0.id) }
    }

    /// Update existing set entity with domain data
    private func updateSetEntity(_ entity: SessionSetEntity, from domain: DomainSessionSet) {
        entity.weight = domain.weight
        entity.reps = domain.reps
        entity.completed = domain.completed
        entity.completedAt = domain.completedAt
        entity.orderIndex = domain.orderIndex
        entity.restTime = domain.restTime
        entity.isWarmup = domain.isWarmup
    }

    // MARK: - DomainSessionExercise Mapping

    /// Convert Domain DomainSessionExercise to SwiftData Entity
    func toEntity(_ domain: DomainSessionExercise) -> SessionExerciseEntity {
        let entity = SessionExerciseEntity(
            id: domain.id,
            exerciseId: domain.exerciseId,
            notes: domain.notes,
            restTimeToNext: domain.restTimeToNext,
            orderIndex: domain.orderIndex,
            isFinished: domain.isFinished,
            sets: []  // Will be set below
        )

        // Map sets
        entity.sets = domain.sets.map { set in
            let setEntity = toEntity(set)
            setEntity.exercise = entity
            return setEntity
        }

        return entity
    }

    /// Convert SwiftData Entity to Domain DomainSessionExercise
    func toDomain(_ entity: SessionExerciseEntity) -> DomainSessionExercise {
        DomainSessionExercise(
            id: entity.id,
            exerciseId: entity.exerciseId,
            exerciseName: entity.exerciseName,  // Gets name from relationship or fallback
            sets: entity.sets.sorted(by: { $0.orderIndex < $1.orderIndex }).map { toDomain($0) },
            notes: entity.notes,
            restTimeToNext: entity.restTimeToNext,
            orderIndex: entity.orderIndex,
            isFinished: entity.isFinished
        )
    }

    // MARK: - DomainSessionSet Mapping

    /// Convert Domain DomainSessionSet to SwiftData Entity
    func toEntity(_ domain: DomainSessionSet) -> SessionSetEntity {
        SessionSetEntity(
            id: domain.id,
            weight: domain.weight,
            reps: domain.reps,
            completed: domain.completed,
            completedAt: domain.completedAt,
            orderIndex: domain.orderIndex,
            restTime: domain.restTime,
            isWarmup: domain.isWarmup
        )
    }

    /// Convert SwiftData Entity to Domain DomainSessionSet
    func toDomain(_ entity: SessionSetEntity) -> DomainSessionSet {
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
}

// MARK: - Mapping Extensions

extension SessionMapper {
    /// Batch convert multiple entities to domain
    func toDomain(_ entities: [WorkoutSessionEntity]) -> [DomainWorkoutSession] {
        entities.map { toDomain($0) }
    }

    /// Batch convert multiple domain objects to entities
    func toEntity(_ domains: [DomainWorkoutSession]) -> [WorkoutSessionEntity] {
        domains.map { toEntity($0) }
    }
}

// MARK: - Tests
// TODO: Move inline tests to separate Test target file
// Tests were removed from production code to avoid XCTest import issues
