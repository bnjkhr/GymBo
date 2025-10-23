//
//  SwiftDataWorkoutRepository.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Data Layer
//

import Foundation
import SwiftData

/// SwiftData implementation of WorkoutRepositoryProtocol
///
/// **Responsibility:**
/// - Persist Workout to SwiftData
/// - Fetch Workout from SwiftData
/// - Convert between Domain and Data entities using WorkoutMapper
///
/// **Design Decisions:**
/// - Uses WorkoutMapper for all conversions
/// - Async/await for all operations
/// - Proper error handling with WorkoutRepositoryError
/// - No business logic - pure data access
///
/// **Usage:**
/// ```swift
/// let repository = SwiftDataWorkoutRepository(modelContext: context)
/// try await repository.save(workout)
/// let workouts = try await repository.fetchAll()
/// ```
@MainActor
final class SwiftDataWorkoutRepository: WorkoutRepositoryProtocol {

    // MARK: - Properties

    private let modelContext: ModelContext
    private let mapper: WorkoutMapper

    // MARK: - Initialization

    init(modelContext: ModelContext, mapper: WorkoutMapper = WorkoutMapper()) {
        self.modelContext = modelContext
        self.mapper = mapper
    }

    // MARK: - Create & Update

    func save(_ workout: Workout) async throws {
        do {
            let entity = mapper.toEntity(workout)
            modelContext.insert(entity)
            try modelContext.save()
        } catch {
            throw WorkoutRepositoryError.saveFailed(error)
        }
    }

    func update(_ workout: Workout) async throws {
        do {
            // Fetch existing entity
            guard let entity = try await fetchEntity(id: workout.id) else {
                throw WorkoutRepositoryError.workoutNotFound(workout.id)
            }

            // Update entity with new data
            mapper.updateEntity(entity, from: workout)

            // Save changes
            try modelContext.save()
        } catch let error as WorkoutRepositoryError {
            throw error
        } catch {
            throw WorkoutRepositoryError.updateFailed(error)
        }
    }

    // MARK: - Read

    func fetch(id: UUID) async throws -> Workout? {
        do {
            guard let entity = try await fetchEntity(id: id) else {
                return nil
            }
            return mapper.toDomain(entity)
        } catch {
            throw WorkoutRepositoryError.fetchFailed(error)
        }
    }

    func fetchAll() async throws -> [Workout] {
        do {
            let descriptor = FetchDescriptor<WorkoutEntity>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )

            let entities = try modelContext.fetch(descriptor)
            return mapper.toDomain(entities)
        } catch {
            throw WorkoutRepositoryError.fetchFailed(error)
        }
    }

    func fetchFavorites() async throws -> [Workout] {
        do {
            let descriptor = FetchDescriptor<WorkoutEntity>(
                predicate: #Predicate { $0.isFavorite == true },
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )

            let entities = try modelContext.fetch(descriptor)
            return mapper.toDomain(entities)
        } catch {
            throw WorkoutRepositoryError.fetchFailed(error)
        }
    }

    func search(query: String) async throws -> [Workout] {
        do {
            let descriptor = FetchDescriptor<WorkoutEntity>(
                predicate: #Predicate { entity in
                    entity.name.localizedStandardContains(query)
                },
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )

            let entities = try modelContext.fetch(descriptor)
            return mapper.toDomain(entities)
        } catch {
            throw WorkoutRepositoryError.fetchFailed(error)
        }
    }

    // MARK: - Delete

    func delete(id: UUID) async throws {
        do {
            guard let entity = try await fetchEntity(id: id) else {
                throw WorkoutRepositoryError.workoutNotFound(id)
            }

            modelContext.delete(entity)
            try modelContext.save()
        } catch let error as WorkoutRepositoryError {
            throw error
        } catch {
            throw WorkoutRepositoryError.deleteFailed(error)
        }
    }

    func deleteAll() async throws {
        do {
            let descriptor = FetchDescriptor<WorkoutEntity>()
            let entities = try modelContext.fetch(descriptor)

            for entity in entities {
                modelContext.delete(entity)
            }

            try modelContext.save()
        } catch {
            throw WorkoutRepositoryError.deleteFailed(error)
        }
    }

    // MARK: - Private Helpers

    private func fetchEntity(id: UUID) async throws -> WorkoutEntity? {
        let descriptor = FetchDescriptor<WorkoutEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
}
