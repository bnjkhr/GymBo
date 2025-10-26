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
    private let folderMapper: WorkoutFolderMapper

    // MARK: - Initialization

    init(
        modelContext: ModelContext, mapper: WorkoutMapper = WorkoutMapper(),
        folderMapper: WorkoutFolderMapper = WorkoutFolderMapper()
    ) {
        self.modelContext = modelContext
        self.mapper = mapper
        self.folderMapper = folderMapper
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

    func updateExerciseOrder(workoutId: UUID, exerciseOrder: [UUID]) async throws {
        do {
            // Fetch existing workout entity
            guard let entity = try await fetchEntity(id: workoutId) else {
                throw WorkoutRepositoryError.workoutNotFound(workoutId)
            }

            print("🔄 BEFORE Reorder: Workout '\(entity.name)'")
            for ex in entity.exercises.sorted(by: { $0.order < $1.order }) {
                print("   - Order \(ex.order): \(ex.id)")
            }

            print("🔄 NEW ORDER requested:")
            for (idx, id) in exerciseOrder.enumerated() {
                print("   - \(idx): \(id)")
            }

            // Update orderIndex of each exercise WITHOUT recreating them
            // Note: exerciseId is the WorkoutExerciseEntity.id, not ExerciseEntity.id
            var foundCount = 0
            for (newIndex, exerciseId) in exerciseOrder.enumerated() {
                if let exercise = entity.exercises.first(where: { $0.id == exerciseId }) {
                    exercise.order = newIndex
                    foundCount += 1
                    print("💾 Updated exercise order: \(exerciseId) → index \(newIndex)")
                } else {
                    print("❌ Exercise not found in workout: \(exerciseId)")
                }
            }

            print("🔄 Updated \(foundCount) of \(exerciseOrder.count) exercises")

            // Save changes to SwiftData
            try modelContext.save()

            print("🔄 AFTER Save: Workout '\(entity.name)'")
            for ex in entity.exercises.sorted(by: { $0.order < $1.order }) {
                print("   - Order \(ex.order): \(ex.id)")
            }

            // Verify data was actually persisted by fetching again
            let verifyDescriptor = FetchDescriptor<WorkoutEntity>(
                predicate: #Predicate { $0.id == workoutId }
            )
            if let verifiedEntity = try modelContext.fetch(verifyDescriptor).first {
                print("🔄 VERIFICATION Fetch from DB:")
                for ex in verifiedEntity.exercises.sorted(by: { $0.order < $1.order }) {
                    print("   - Order \(ex.order): \(ex.id)")
                }
            }

            print("✅ Exercise order saved to SwiftData")
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

    // MARK: - Folder Management

    func fetchAllFolders() async throws -> [WorkoutFolder] {
        do {
            print("🔍 [Repository] Fetching all folders from database...")
            let descriptor = FetchDescriptor<WorkoutFolderEntity>(
                sortBy: [SortDescriptor(\.order, order: .forward)]
            )
            let entities = try modelContext.fetch(descriptor)
            print("🔍 [Repository] Found \(entities.count) folder entities in database")
            for entity in entities {
                print(
                    "  - Folder: id=\(entity.id), name=\(entity.name), color=\(entity.color), order=\(entity.order)"
                )
            }
            let domains = folderMapper.toDomain(entities)
            print("✅ [Repository] Converted to \(domains.count) domain folders")
            return domains
        } catch {
            print("❌ [Repository] Failed to fetch folders: \(error)")
            throw WorkoutRepositoryError.fetchFailed(error)
        }
    }

    func createFolder(_ folder: WorkoutFolder) async throws {
        do {
            print(
                "💾 [Repository] Creating folder: id=\(folder.id), name=\(folder.name), color=\(folder.color)"
            )
            let entity = folderMapper.toEntity(folder)
            print("💾 [Repository] Created entity: id=\(entity.id), name=\(entity.name)")
            modelContext.insert(entity)
            print("💾 [Repository] Entity inserted into context")
            try modelContext.save()
            print("✅ [Repository] ModelContext saved successfully")

            // Verify the save worked
            let folderId = folder.id
            let descriptor = FetchDescriptor<WorkoutFolderEntity>(
                predicate: #Predicate { $0.id == folderId }
            )
            let savedEntities = try modelContext.fetch(descriptor)
            print(
                "🔍 [Repository] Verification: Found \(savedEntities.count) entities with id \(folderId)"
            )
        } catch {
            print("❌ [Repository] Failed to create folder: \(error)")
            throw WorkoutRepositoryError.saveFailed(error)
        }
    }

    func updateFolder(_ folder: WorkoutFolder) async throws {
        do {
            guard let entity = try await fetchFolderEntity(id: folder.id) else {
                throw WorkoutRepositoryError.workoutNotFound(folder.id)
            }
            folderMapper.updateEntity(entity, from: folder)
            try modelContext.save()
        } catch let error as WorkoutRepositoryError {
            throw error
        } catch {
            throw WorkoutRepositoryError.updateFailed(error)
        }
    }

    func deleteFolder(id: UUID) async throws {
        do {
            print("🗑️ [Repository] Deleting folder \(id)")
            guard let entity = try await fetchFolderEntity(id: id) else {
                throw WorkoutRepositoryError.workoutNotFound(id)
            }

            print(
                "🗑️ [Repository] Found folder entity, removing from \(entity.workouts.count) workouts"
            )
            // Remove folder reference from all workouts in this folder
            for workout in entity.workouts {
                print("  - Removing folder from workout: \(workout.name)")
                workout.folder = nil
            }

            modelContext.delete(entity)
            try modelContext.save()
            print("✅ [Repository] Folder deleted and changes saved")
        } catch let error as WorkoutRepositoryError {
            throw error
        } catch {
            throw WorkoutRepositoryError.deleteFailed(error)
        }
    }

    func moveWorkoutToFolder(workoutId: UUID, folderId: UUID?) async throws {
        do {
            guard let workoutEntity = try await fetchEntity(id: workoutId) else {
                throw WorkoutRepositoryError.workoutNotFound(workoutId)
            }

            if let folderId = folderId {
                // Move to folder
                guard let folderEntity = try await fetchFolderEntity(id: folderId) else {
                    throw WorkoutRepositoryError.workoutNotFound(folderId)
                }
                workoutEntity.folder = folderEntity
            } else {
                // Remove from folder
                workoutEntity.folder = nil
            }

            try modelContext.save()
        } catch let error as WorkoutRepositoryError {
            throw error
        } catch {
            throw WorkoutRepositoryError.updateFailed(error)
        }
    }

    // MARK: - Private Helpers

    private func fetchEntity(id: UUID) async throws -> WorkoutEntity? {
        let descriptor = FetchDescriptor<WorkoutEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func fetchFolderEntity(id: UUID) async throws -> WorkoutFolderEntity? {
        let descriptor = FetchDescriptor<WorkoutFolderEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
}
