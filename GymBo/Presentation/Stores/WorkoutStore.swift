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

    /// Currently selected workout (for detail view)
    var selectedWorkout: Workout?

    /// Loading state for async operations
    var isLoading: Bool = false

    /// Error state (cleared on next operation)
    var error: Error?

    /// Success message for user feedback (pill notification)
    var successMessage: String?
    var showSuccessPill: Bool = false

    // MARK: - Dependencies (Injected)

    private let getAllWorkoutsUseCase: GetAllWorkoutsUseCase
    private let getWorkoutByIdUseCase: GetWorkoutByIdUseCase
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let addExerciseToWorkoutUseCase: AddExerciseToWorkoutUseCase

    // MARK: - Private State

    private var successMessageTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        getAllWorkoutsUseCase: GetAllWorkoutsUseCase,
        getWorkoutByIdUseCase: GetWorkoutByIdUseCase,
        toggleFavoriteUseCase: ToggleFavoriteUseCase,
        addExerciseToWorkoutUseCase: AddExerciseToWorkoutUseCase
    ) {
        self.getAllWorkoutsUseCase = getAllWorkoutsUseCase
        self.getWorkoutByIdUseCase = getWorkoutByIdUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.addExerciseToWorkoutUseCase = addExerciseToWorkoutUseCase
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
                toggleFavoriteUseCase: MockToggleFavoriteUseCase(),
                addExerciseToWorkoutUseCase: MockAddExerciseToWorkoutUseCase()
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
#endif
