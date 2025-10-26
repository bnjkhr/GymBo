//
//  WorkoutStore.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Presentation Layer
//

import Foundation
import Observation
import SwiftUI

/// Presentation layer store for workout template management
///
/// **Responsibility:**
/// - Manage UI state for workout templates
/// - Coordinate between UI and Workout Use Cases
/// - Handle loading states and errors
/// - Uses iOS 17+ @Observable for better performance
///
/// **Design Decisions:**
/// - @MainActor for UI thread safety
/// - @Observable (iOS 17+) for fine-grained updates
/// - Delegates business logic to Use Cases
/// - No direct database access
///
/// **Usage:**
/// ```swift
/// struct WorkoutListView: View {
///     @State var workoutStore: WorkoutStore
///
///     var body: some View {
///         List(workoutStore.workouts) { workout in
///             Text(workout.name)
///         }
///         .task {
///             await workoutStore.loadWorkouts()
///         }
///     }
/// }
/// ```
@MainActor
@Observable
final class WorkoutStore {

    // MARK: - Observable State

    /// List of all workout templates
    var workouts: [Workout] = []

    /// List of all workout folders
    var folders: [WorkoutFolder] = []

    /// Currently selected workout (for detail view)
    var selectedWorkout: Workout?

    /// Loading state for async operations
    var isLoading: Bool = false

    /// Error state (cleared on next operation)
    var error: Error?

    /// Success message for user feedback (pill notification)
    var successMessage: String?
    var showSuccessPill: Bool = false

    /// Refresh trigger - increment to force views to reload data
    /// Used when workouts are modified outside normal flows (e.g., during active session)
    var refreshTrigger: Int = 0

    // MARK: - Dependencies (Injected)

    private let getAllWorkoutsUseCase: GetAllWorkoutsUseCase
    private let getWorkoutByIdUseCase: GetWorkoutByIdUseCase
    private let createWorkoutUseCase: CreateWorkoutUseCase
    private let deleteWorkoutUseCase: DeleteWorkoutUseCase
    private let updateWorkoutUseCase: UpdateWorkoutUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let addExerciseToWorkoutUseCase: AddExerciseToWorkoutUseCase
    private let removeExerciseFromWorkoutUseCase: RemoveExerciseFromWorkoutUseCase
    private let reorderWorkoutExercisesUseCase: ReorderWorkoutExercisesUseCase
    private let updateWorkoutExerciseUseCase: UpdateWorkoutExerciseUseCase
    private let workoutRepository: WorkoutRepositoryProtocol  // For direct folder access

    // MARK: - Private State

    private var successMessageTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        getAllWorkoutsUseCase: GetAllWorkoutsUseCase,
        getWorkoutByIdUseCase: GetWorkoutByIdUseCase,
        createWorkoutUseCase: CreateWorkoutUseCase,
        deleteWorkoutUseCase: DeleteWorkoutUseCase,
        updateWorkoutUseCase: UpdateWorkoutUseCase,
        toggleFavoriteUseCase: ToggleFavoriteUseCase,
        addExerciseToWorkoutUseCase: AddExerciseToWorkoutUseCase,
        removeExerciseFromWorkoutUseCase: RemoveExerciseFromWorkoutUseCase,
        reorderWorkoutExercisesUseCase: ReorderWorkoutExercisesUseCase,
        updateWorkoutExerciseUseCase: UpdateWorkoutExerciseUseCase,
        workoutRepository: WorkoutRepositoryProtocol
    ) {
        self.getAllWorkoutsUseCase = getAllWorkoutsUseCase
        self.getWorkoutByIdUseCase = getWorkoutByIdUseCase
        self.createWorkoutUseCase = createWorkoutUseCase
        self.deleteWorkoutUseCase = deleteWorkoutUseCase
        self.updateWorkoutUseCase = updateWorkoutUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.addExerciseToWorkoutUseCase = addExerciseToWorkoutUseCase
        self.removeExerciseFromWorkoutUseCase = removeExerciseFromWorkoutUseCase
        self.reorderWorkoutExercisesUseCase = reorderWorkoutExercisesUseCase
        self.updateWorkoutExerciseUseCase = updateWorkoutExerciseUseCase
        self.workoutRepository = workoutRepository
    }

    // MARK: - Public Methods

    /// Load all workout templates
    func loadWorkouts() async {
        isLoading = true
        error = nil

        do {
            workouts = try await getAllWorkoutsUseCase.execute()
            print("✅ Loaded \(workouts.count) workouts")
        } catch {
            self.error = error
            print("❌ Failed to load workouts: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Load a specific workout by ID
    /// - Parameter id: Workout ID
    func loadWorkout(id: UUID) async {
        isLoading = true
        error = nil

        do {
            selectedWorkout = try await getWorkoutByIdUseCase.execute(id: id)
            print("✅ Loaded workout: \(selectedWorkout?.name ?? "Unknown")")
        } catch {
            self.error = error
            print("❌ Failed to load workout: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Refresh workouts list
    func refresh() async {
        await loadWorkouts()
        await loadFolders()
    }

    // MARK: - Folder Management

    /// Load all workout folders
    func loadFolders() async {
        do {
            print("🔄 [WorkoutStore] Loading folders...")
            folders = try await workoutRepository.fetchAllFolders()
            print("✅ [WorkoutStore] Loaded \(folders.count) folders")
            for folder in folders {
                print("  - \(folder.name) (id: \(folder.id), color: \(folder.color))")
            }
        } catch {
            self.error = error
            print("❌ [WorkoutStore] Failed to load folders: \(error.localizedDescription)")
        }
    }

    /// Create a new workout folder
    func createFolder(name: String, color: String) async {
        do {
            print("📝 [WorkoutStore] Creating folder: name=\(name), color=\(color)")
            let maxOrder = folders.map { $0.order }.max() ?? -1
            print("📝 [WorkoutStore] Current max order: \(maxOrder), new order: \(maxOrder + 1)")
            let folder = WorkoutFolder(
                name: name,
                color: color,
                order: maxOrder + 1
            )
            print("📝 [WorkoutStore] Folder object created: \(folder)")
            try await workoutRepository.createFolder(folder)
            print("✅ [WorkoutStore] Folder created in repository, reloading folders...")
            await loadFolders()
            showSuccessMessage("Kategorie erstellt")
            print("✅ [WorkoutStore] Create folder complete")
        } catch {
            self.error = error
            print("❌ [WorkoutStore] Failed to create folder: \(error)")
        }
    }

    /// Update a folder
    func updateFolder(_ folder: WorkoutFolder) async {
        do {
            try await workoutRepository.updateFolder(folder)
            await loadFolders()
            showSuccessMessage("Kategorie aktualisiert")
            print("✅ Updated folder: \(folder.name)")
        } catch {
            self.error = error
            print("❌ Failed to update folder: \(error)")
        }
    }

    /// Delete a folder
    func deleteFolder(id: UUID) async {
        do {
            try await workoutRepository.deleteFolder(id: id)
            await loadFolders()
            await loadWorkouts()  // Reload workouts to update their folder references
            showSuccessMessage("Kategorie gelöscht")
            print("✅ Deleted folder")
        } catch {
            self.error = error
            print("❌ Failed to delete folder: \(error)")
        }
    }

    /// Move workout to a folder
    func moveWorkoutToFolder(workoutId: UUID, folderId: UUID?) async {
        do {
            print(
                "📦 [WorkoutStore] Moving workout \(workoutId) to folder \(folderId?.uuidString ?? "none")"
            )
            try await workoutRepository.moveWorkoutToFolder(
                workoutId: workoutId, folderId: folderId)
            await loadWorkouts()
            print("✅ [WorkoutStore] Moved workout to folder, reloaded workouts")
            // Debug: Print workout folder assignments
            for workout in workouts {
                print(
                    "  - Workout '\(workout.name)': folderId=\(workout.folderId?.uuidString ?? "nil")"
                )
            }
        } catch {
            self.error = error
            print("❌ [WorkoutStore] Failed to move workout: \(error)")
        }
    }

    /// Trigger a refresh in observing views (e.g., WorkoutDetailView)
    /// Call this when workouts are modified outside normal Store operations
    func triggerRefresh() {
        refreshTrigger += 1
        Task {
            await loadWorkouts()
        }
    }

    // MARK: - Private Helpers

    /// Show success message with auto-dismiss
    private func showSuccessMessage(_ message: String) {
        successMessage = message
        showSuccessPill = true

        // Cancel previous task
        successMessageTask?.cancel()

        // Auto-clear after 3 seconds
        successMessageTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            successMessage = nil
            showSuccessPill = false
        }
    }

    /// Create a new workout template
    /// - Parameters:
    ///   - name: Workout name
    ///   - defaultRestTime: Default rest time in seconds
    /// - Returns: The created workout
    @discardableResult
    func createWorkout(name: String, defaultRestTime: TimeInterval = 90) async throws -> Workout {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let workout = try await createWorkoutUseCase.execute(
                name: name,
                defaultRestTime: defaultRestTime
            )

            // Add to local array
            workouts.append(workout)

            // Set as selected workout
            selectedWorkout = workout

            print("✅ Created workout: \(workout.name)")
            return workout

        } catch {
            self.error = error
            print("❌ Failed to create workout: \(error.localizedDescription)")
            throw error
        }
    }

    /// Delete a workout
    func deleteWorkout(workoutId: UUID) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await deleteWorkoutUseCase.execute(workoutId: workoutId)

            // Remove from local array
            workouts.removeAll { $0.id == workoutId }

            // Clear selection if deleted workout was selected
            if selectedWorkout?.id == workoutId {
                selectedWorkout = nil
            }

            print("✅ Deleted workout")
            showSuccess("Workout gelöscht")

        } catch {
            self.error = error
            print("❌ Failed to delete workout: \(error.localizedDescription)")
        }
    }

    /// Update workout name and/or rest time
    func updateWorkout(workoutId: UUID, name: String?, defaultRestTime: TimeInterval?) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let updatedWorkout = try await updateWorkoutUseCase.execute(
                workoutId: workoutId,
                name: name,
                defaultRestTime: defaultRestTime
            )

            // Update in local array - create completely new array to force @Observable detection
            if let index = workouts.firstIndex(where: { $0.id == workoutId }) {
                print(
                    "📝 WorkoutStore: Found workout at index \(index), old name: '\(workouts[index].name)', new name: '\(updatedWorkout.name)'"
                )

                // Create brand new array (not just copy reference)
                var newWorkouts: [Workout] = []
                for (i, workout) in workouts.enumerated() {
                    if i == index {
                        newWorkouts.append(updatedWorkout)
                    } else {
                        newWorkouts.append(workout)
                    }
                }
                workouts = newWorkouts

                print(
                    "📝 WorkoutStore: Created new array, workouts[\(index)].name = '\(workouts[index].name)'"
                )
                print("📝 WorkoutStore: New array identity, workouts.count = \(workouts.count)")
            } else {
                print("⚠️ WorkoutStore: Workout not found in local array!")
            }

            // Update selection if updated workout was selected
            if selectedWorkout?.id == workoutId {
                selectedWorkout = updatedWorkout
            }

            print("✅ Updated workout: \(updatedWorkout.name)")
            showSuccess("Workout aktualisiert")

        } catch {
            self.error = error
            print("❌ Failed to update workout: \(error.localizedDescription)")
        }
    }

    /// Toggle favorite status of a workout
    /// - Parameter workoutId: ID of the workout to toggle
    func toggleFavorite(workoutId: UUID) async {
        do {
            let updatedWorkout = try await toggleFavoriteUseCase.execute(workoutId: workoutId)

            // Update in local array
            if let index = workouts.firstIndex(where: { $0.id == workoutId }) {
                workouts[index] = updatedWorkout
            }

            // Update selected workout if it's the same
            if selectedWorkout?.id == workoutId {
                selectedWorkout = updatedWorkout
            }

            print("✅ Toggled favorite: \(updatedWorkout.name) → \(updatedWorkout.isFavorite)")
        } catch {
            self.error = error
            print("❌ Failed to toggle favorite: \(error.localizedDescription)")
        }
    }

    /// Add exercise to a workout
    /// - Parameters:
    ///   - exerciseId: ID of exercise from catalog
    ///   - workoutId: ID of workout to add to
    func addExercise(exerciseId: UUID, to workoutId: UUID) async {
        do {
            let updatedWorkout = try await addExerciseToWorkoutUseCase.execute(
                exerciseId: exerciseId,
                workoutId: workoutId
            )

            // Update in local array
            if let index = workouts.firstIndex(where: { $0.id == workoutId }) {
                workouts[index] = updatedWorkout
            }

            // Update selected workout if it's the same
            if selectedWorkout?.id == workoutId {
                selectedWorkout = updatedWorkout
            }

            showSuccess("Übung hinzugefügt")
            print("✅ Added exercise to workout: \(updatedWorkout.name)")
        } catch {
            self.error = error
            print("❌ Failed to add exercise: \(error.localizedDescription)")
        }
    }

    /// Remove exercise from a workout
    /// - Parameters:
    ///   - exerciseId: ID of WorkoutExercise to remove
    ///   - workoutId: ID of workout to remove from
    func removeExercise(exerciseId: UUID, from workoutId: UUID) async {
        do {
            let updatedWorkout = try await removeExerciseFromWorkoutUseCase.execute(
                exerciseId: exerciseId,
                from: workoutId
            )

            // Update in local array
            if let index = workouts.firstIndex(where: { $0.id == workoutId }) {
                workouts[index] = updatedWorkout
            }

            // Update selected workout if it's the same
            if selectedWorkout?.id == workoutId {
                selectedWorkout = updatedWorkout
            }

            showSuccess("Übung entfernt")
            print("✅ Removed exercise from workout: \(updatedWorkout.name)")
        } catch {
            self.error = error
            print("❌ Failed to remove exercise: \(error.localizedDescription)")
        }
    }

    /// Reorder exercises in a workout
    /// - Parameters:
    ///   - workoutId: ID of workout
    ///   - exerciseIds: Array of exercise IDs in new order
    func reorderExercises(in workoutId: UUID, exerciseIds: [UUID]) async {
        do {
            let updatedWorkout = try await reorderWorkoutExercisesUseCase.execute(
                workoutId: workoutId,
                exerciseIds: exerciseIds
            )

            // Reload all workouts from database to get fresh data
            await loadWorkouts()

            print("✅ Reordered exercises in workout: \(updatedWorkout.name)")
        } catch {
            self.error = error
            print("❌ Failed to reorder exercises: \(error.localizedDescription)")
        }
    }

    /// Update exercise details in a workout
    func updateExercise(
        in workoutId: UUID,
        exerciseId: UUID,
        targetSets: Int,
        targetReps: Int?,
        targetTime: TimeInterval?,
        targetWeight: Double?,
        restTime: TimeInterval?,
        perSetRestTimes: [TimeInterval]?,
        notes: String?
    ) async {
        do {
            let updatedWorkout = try await updateWorkoutExerciseUseCase.execute(
                workoutId: workoutId,
                exerciseId: exerciseId,
                targetSets: targetSets,
                targetReps: targetReps,
                targetTime: targetTime,
                targetWeight: targetWeight,
                restTime: restTime,
                perSetRestTimes: perSetRestTimes,
                notes: notes
            )

            // Update local workout list
            if let index = workouts.firstIndex(where: { $0.id == workoutId }) {
                workouts[index] = updatedWorkout
            }

            showSuccess("Übung aktualisiert")
            print("✅ Updated exercise in workout: \(updatedWorkout.name)")
        } catch {
            self.error = error
            print("❌ Failed to update exercise: \(error.localizedDescription)")
        }
    }

    /// Clear current error
    func clearError() {
        error = nil
    }

    /// Show success message (auto-clears after 2 seconds)
    /// - Parameter message: Message to display
    func showSuccess(_ message: String) {
        successMessage = message
        showSuccessPill = true

        // Cancel previous task if exists
        successMessageTask?.cancel()

        // Auto-clear after 2 seconds
        successMessageTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !Task.isCancelled {
                showSuccessPill = false
                successMessage = nil
            }
        }
    }

    // MARK: - Computed Properties

    /// Favorite workouts only
    var favoriteWorkouts: [Workout] {
        workouts.filter { $0.isFavorite }
    }

    /// Regular (non-favorite) workouts
    var regularWorkouts: [Workout] {
        workouts.filter { !$0.isFavorite }
    }

    /// Check if any workouts exist
    var hasWorkouts: Bool {
        !workouts.isEmpty
    }
}

// MARK: - Preview Helpers

#if DEBUG
    extension WorkoutStore {
        /// Create store with mock data for previews
        static var preview: WorkoutStore {
            let store = WorkoutStore(
                getAllWorkoutsUseCase: MockGetAllWorkoutsUseCase(),
                getWorkoutByIdUseCase: MockGetWorkoutByIdUseCase(),
                createWorkoutUseCase: MockCreateWorkoutUseCase(),
                deleteWorkoutUseCase: MockDeleteWorkoutUseCase(),
                updateWorkoutUseCase: MockUpdateWorkoutUseCase(),
                toggleFavoriteUseCase: MockToggleFavoriteUseCase(),
                addExerciseToWorkoutUseCase: MockAddExerciseToWorkoutUseCase(),
                removeExerciseFromWorkoutUseCase: MockRemoveExerciseFromWorkoutUseCase(),
                reorderWorkoutExercisesUseCase: MockReorderWorkoutExercisesUseCase(),
                updateWorkoutExerciseUseCase: MockUpdateWorkoutExerciseUseCase(),
                workoutRepository: MockWorkoutRepository()
            )

            // Populate with sample data
            store.workouts = [
                Workout(name: "Push Day", isFavorite: true),
                Workout(name: "Pull Day", isFavorite: false),
                Workout(name: "Leg Day", isFavorite: true),
            ]

            return store
        }
    }

    // Mock Use Cases for Previews
    private final class MockGetAllWorkoutsUseCase: GetAllWorkoutsUseCase {
        func execute() async throws -> [Workout] {
            [
                Workout(name: "Push Day", isFavorite: true),
                Workout(name: "Pull Day"),
                Workout(name: "Leg Day", isFavorite: true),
            ]
        }
    }

    private final class MockGetWorkoutByIdUseCase: GetWorkoutByIdUseCase {
        func execute(id: UUID) async throws -> Workout {
            Workout(name: "Mock Workout")
        }
    }

    private final class MockCreateWorkoutUseCase: CreateWorkoutUseCase {
        func execute(name: String, defaultRestTime: TimeInterval) async throws -> Workout {
            Workout(name: name, defaultRestTime: defaultRestTime)
        }
    }

    private final class MockDeleteWorkoutUseCase: DeleteWorkoutUseCase {
        func execute(workoutId: UUID) async throws {
            // Mock: do nothing
        }
    }

    private final class MockUpdateWorkoutUseCase: UpdateWorkoutUseCase {
        func execute(workoutId: UUID, name: String?, defaultRestTime: TimeInterval?) async throws
            -> Workout
        {
            var workout = Workout(name: "Mock Workout")
            if let newName = name {
                workout.name = newName
            }
            if let newRestTime = defaultRestTime {
                workout.defaultRestTime = newRestTime
            }
            return workout
        }
    }

    private final class MockToggleFavoriteUseCase: ToggleFavoriteUseCase {
        func execute(workoutId: UUID) async throws -> Workout {
            var workout = Workout(name: "Mock Workout", isFavorite: false)
            workout.isFavorite.toggle()
            return workout
        }
    }

    private final class MockAddExerciseToWorkoutUseCase: AddExerciseToWorkoutUseCase {
        func execute(exerciseId: UUID, workoutId: UUID) async throws -> Workout {
            var workout = Workout(name: "Mock Workout")
            workout.exercises.append(
                WorkoutExercise(
                    exerciseId: exerciseId,
                    targetSets: 3,
                    targetReps: 10,
                    orderIndex: 0
                )
            )
            return workout
        }
    }

    private final class MockRemoveExerciseFromWorkoutUseCase: RemoveExerciseFromWorkoutUseCase {
        func execute(exerciseId: UUID, from workoutId: UUID) async throws -> Workout {
            var workout = Workout(name: "Mock Workout")
            // Mock: return workout with exercise removed
            return workout
        }
    }

    private final class MockReorderWorkoutExercisesUseCase: ReorderWorkoutExercisesUseCase {
        func execute(workoutId: UUID, exerciseIds: [UUID]) async throws -> Workout {
            var workout = Workout(name: "Mock Workout")
            // Mock: return workout with reordered exercises
            return workout
        }
    }

    private final class MockUpdateWorkoutExerciseUseCase: UpdateWorkoutExerciseUseCase {
        func execute(
            workoutId: UUID,
            exerciseId: UUID,
            targetSets: Int,
            targetReps: Int?,
            targetTime: TimeInterval?,
            targetWeight: Double?,
            restTime: TimeInterval?,
            perSetRestTimes: [TimeInterval]?,
            notes: String?
        ) async throws -> Workout {
            var workout = Workout(name: "Mock Workout")
            // Mock: return workout with updated exercise
            return workout
        }
    }
#endif
