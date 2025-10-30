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

/// Errors that can occur in WorkoutStore
enum WorkoutStoreError: LocalizedError {
    case workoutNotFound
    case exerciseNotFound

    var errorDescription: String? {
        switch self {
        case .workoutNotFound:
            return "Workout nicht gefunden"
        case .exerciseNotFound:
            return "Übung nicht gefunden"
        }
    }
}

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
    private let swapExerciseUseCase: SwapExerciseUseCase
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
        swapExerciseUseCase: SwapExerciseUseCase,
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
        self.swapExerciseUseCase = swapExerciseUseCase
        self.workoutRepository = workoutRepository
    }

    // MARK: - Public Methods

    /// Load all workout templates
    func loadWorkouts() async {
        isLoading = true
        error = nil

        do {
            workouts = try await getAllWorkoutsUseCase.execute()
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
            folders = try await workoutRepository.fetchAllFolders()
        } catch {
            self.error = error
            print("❌ Failed to load folders: \(error.localizedDescription)")
        }
    }

    /// Create a new workout folder
    func createFolder(name: String, color: String) async {
        do {
            let maxOrder = folders.map { $0.order }.max() ?? -1
            let folder = WorkoutFolder(
                name: name,
                color: color,
                order: maxOrder + 1
            )
            try await workoutRepository.createFolder(folder)
            await loadFolders()
            showSuccessMessage("Kategorie erstellt")
        } catch {
            self.error = error
            print("❌ Failed to create folder: \(error)")
        }
    }

    /// Update a folder
    func updateFolder(_ folder: WorkoutFolder) async {
        do {
            try await workoutRepository.updateFolder(folder)
            await loadFolders()
            showSuccessMessage("Kategorie aktualisiert")
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
        } catch {
            self.error = error
            print("❌ Failed to delete folder: \(error)")
        }
    }

    /// Reorder folders
    func reorderFolders(from source: IndexSet, to destination: Int) async {
        var updatedFolders = folders
        updatedFolders.move(fromOffsets: source, toOffset: destination)

        // Update order property for all folders
        for (index, folder) in updatedFolders.enumerated() {
            var updatedFolder = folder
            updatedFolder.order = index
            do {
                try await workoutRepository.updateFolder(updatedFolder)
            } catch {
                self.error = error
                print("❌ Failed to reorder folders: \(error)")
                return
            }
        }

        await loadFolders()
    }

    /// Move workout to a folder
    func moveWorkoutToFolder(workoutId: UUID, folderId: UUID?) async {
        do {
            try await workoutRepository.moveWorkoutToFolder(
                workoutId: workoutId, folderId: folderId)
            await loadWorkouts()
        } catch {
            self.error = error
            print("❌ Failed to move workout: \(error)")
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

            showSuccess("Workout gelöscht")

        } catch {
            self.error = error
            print("❌ Failed to delete workout: \(error.localizedDescription)")
        }
    }

    /// Update workout name and/or rest time
    /// Update warmup strategy for a workout
    func updateWarmupStrategy(workoutId: UUID, strategy: WarmupCalculator.Strategy) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Get current workout
            guard var workout = workouts.first(where: { $0.id == workoutId }) else {
                throw NSError(
                    domain: "WorkoutStore", code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Workout not found"])
            }

            // Update warmup strategy
            workout.warmupStrategy = strategy

            // Persist via repository
            try await workoutRepository.update(workout)

            // Update in local array
            if let index = workouts.firstIndex(where: { $0.id == workoutId }) {
                var newWorkouts: [Workout] = []
                for (i, w) in workouts.enumerated() {
                    if i == index {
                        newWorkouts.append(workout)  // Use the updated workout
                    } else {
                        newWorkouts.append(w)
                    }
                }
                workouts = newWorkouts
            }
        } catch {
            self.error = error
            print(
                "❌ WorkoutStore: Failed to update warmup strategy - \(error.localizedDescription)")
        }
    }

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
            } else {
            }

            // Update selection if updated workout was selected
            if selectedWorkout?.id == workoutId {
                selectedWorkout = updatedWorkout
            }

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
        } catch {
            self.error = error
            print("❌ Failed to update exercise: \(error.localizedDescription)")
        }
    }

    /// Swap an exercise with an alternative
    /// - Parameters:
    ///   - workoutId: Workout containing the exercise
    ///   - oldExerciseId: Exercise ID to replace
    ///   - newExerciseId: New exercise ID
    ///   - savePermanently: If true, saves to template; if false, only updates current view
    func swapExercise(
        in workoutId: UUID,
        oldExerciseId: UUID,
        newExerciseId: UUID,
        savePermanently: Bool
    ) async {
        do {
            if savePermanently {
                // Permanent swap: Update the template in repository
                let updatedWorkout = try await swapExerciseUseCase.execute(
                    workoutId: workoutId,
                    oldExerciseId: oldExerciseId,
                    newExerciseId: newExerciseId
                )

                // Update local workout list
                if let index = workouts.firstIndex(where: { $0.id == workoutId }) {
                    workouts[index] = updatedWorkout
                }

                showSuccess("Übung dauerhaft ersetzt")
            } else {
                // Temporary swap: Only update local workout list (not repository)
                guard let workoutIndex = workouts.firstIndex(where: { $0.id == workoutId }) else {
                    throw WorkoutStoreError.workoutNotFound
                }

                var workout = workouts[workoutIndex]

                // Find the exercise to swap
                guard
                    let exerciseIndex = workout.exercises.firstIndex(where: {
                        $0.exerciseId == oldExerciseId
                    })
                else {
                    throw WorkoutStoreError.exerciseNotFound
                }

                let oldWorkoutExercise = workout.exercises[exerciseIndex]

                // Create new WorkoutExercise with same settings but new exerciseId
                let newWorkoutExercise = WorkoutExercise(
                    id: oldWorkoutExercise.id,
                    exerciseId: newExerciseId,
                    targetSets: oldWorkoutExercise.targetSets,
                    targetReps: oldWorkoutExercise.targetReps,
                    targetTime: oldWorkoutExercise.targetTime,
                    targetWeight: oldWorkoutExercise.targetWeight,
                    restTime: oldWorkoutExercise.restTime,
                    perSetRestTimes: oldWorkoutExercise.perSetRestTimes,
                    orderIndex: oldWorkoutExercise.orderIndex,
                    notes: oldWorkoutExercise.notes
                )

                // Replace in local workout list (no repository update)
                workout.exercises[exerciseIndex] = newWorkoutExercise
                workouts[workoutIndex] = workout

                showSuccess("Übung temporär ersetzt")
            }
        } catch {
            self.error = error
            print("❌ Failed to swap exercise: \(error.localizedDescription)")
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
                swapExerciseUseCase: MockSwapExerciseUseCase(),
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

    private final class MockSwapExerciseUseCase: SwapExerciseUseCase {
        func execute(
            workoutId: UUID,
            oldExerciseId: UUID,
            newExerciseId: UUID
        ) async throws -> Workout {
            var workout = Workout(name: "Mock Workout")
            // Mock: return workout with swapped exercise
            return workout
        }
    }
#endif
