//
//  SessionStore.swift
//  GymTracker
//
//  Created on 2025-10-22.
//  V2 Clean Architecture - Presentation Layer
//

import Combine
import Foundation
import HealthKit
import Observation
import SwiftUI

/// Presentation layer store for workout session management
///
/// **Responsibility:**
/// - Manage UI state for active workout session
/// - Coordinate between UI and Use Cases
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
/// struct ContentView: View {
///     @State var sessionStore: SessionStore
///
///     var body: some View {
///         if let session = sessionStore.currentSession {
///             ActiveWorkoutSheetView()
///                 .environment(sessionStore)
///         }
///     }
/// }
/// ```
@MainActor
@Observable
final class SessionStore {

    // MARK: - Observable State (automatically tracked)

    /// Currently active workout session (nil if no active session)
    var currentSession: DomainWorkoutSession?

    /// Completed session for summary display (nil if no completed session)
    var completedSession: DomainWorkoutSession?

    /// Loading state for async operations
    var isLoading: Bool = false

    /// Error state (cleared on next operation)
    var error: Error?

    /// Success message for user feedback (auto-clears after 3s)
    var successMessage: String?

    /// HealthKit availability status
    var healthKitAvailable: Bool = false

    /// HealthKit authorization status
    var healthKitAuthorized: Bool = false

    // MARK: - Dependencies (Injected)

    private let startSessionUseCase: StartSessionUseCase
    private let completeSetUseCase: CompleteSetUseCase
    private let endSessionUseCase: EndSessionUseCase
    private let cancelSessionUseCase: CancelSessionUseCase
    private let pauseSessionUseCase: PauseSessionUseCase
    private let resumeSessionUseCase: ResumeSessionUseCase
    private let updateSetUseCase: UpdateSetUseCase
    private let updateAllSetsUseCase: UpdateAllSetsUseCase
    private let updateExerciseNotesUseCase: UpdateExerciseNotesUseCase
    private let addSetUseCase: AddSetUseCase
    private let removeSetUseCase: RemoveSetUseCase
    private let reorderExercisesUseCase: ReorderExercisesUseCase
    private let finishExerciseUseCase: FinishExerciseUseCase
    private let addExerciseToSessionUseCase: AddExerciseToSessionUseCase
    private let sessionRepository: SessionRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let workoutRepository: WorkoutRepositoryProtocol
    private let healthKitService: HealthKitServiceProtocol
    private weak var restTimerManager: RestTimerStateManager?

    // MARK: - Private State

    private var successMessageTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        startSessionUseCase: StartSessionUseCase,
        completeSetUseCase: CompleteSetUseCase,
        endSessionUseCase: EndSessionUseCase,
        cancelSessionUseCase: CancelSessionUseCase,
        pauseSessionUseCase: PauseSessionUseCase,
        resumeSessionUseCase: ResumeSessionUseCase,
        updateSetUseCase: UpdateSetUseCase,
        updateAllSetsUseCase: UpdateAllSetsUseCase,
        updateExerciseNotesUseCase: UpdateExerciseNotesUseCase,
        addSetUseCase: AddSetUseCase,
        removeSetUseCase: RemoveSetUseCase,
        reorderExercisesUseCase: ReorderExercisesUseCase,
        finishExerciseUseCase: FinishExerciseUseCase,
        addExerciseToSessionUseCase: AddExerciseToSessionUseCase,
        sessionRepository: SessionRepositoryProtocol,
        exerciseRepository: ExerciseRepositoryProtocol,
        workoutRepository: WorkoutRepositoryProtocol,
        healthKitService: HealthKitServiceProtocol,
        restTimerManager: RestTimerStateManager? = nil
    ) {
        self.startSessionUseCase = startSessionUseCase
        self.completeSetUseCase = completeSetUseCase
        self.endSessionUseCase = endSessionUseCase
        self.cancelSessionUseCase = cancelSessionUseCase
        self.pauseSessionUseCase = pauseSessionUseCase
        self.resumeSessionUseCase = resumeSessionUseCase
        self.updateSetUseCase = updateSetUseCase
        self.updateAllSetsUseCase = updateAllSetsUseCase
        self.updateExerciseNotesUseCase = updateExerciseNotesUseCase
        self.addSetUseCase = addSetUseCase
        self.removeSetUseCase = removeSetUseCase
        self.reorderExercisesUseCase = reorderExercisesUseCase
        self.finishExerciseUseCase = finishExerciseUseCase
        self.addExerciseToSessionUseCase = addExerciseToSessionUseCase
        self.workoutRepository = workoutRepository
        self.sessionRepository = sessionRepository
        self.exerciseRepository = exerciseRepository
        self.healthKitService = healthKitService
        self.restTimerManager = restTimerManager

        // Initialize HealthKit availability
        self.healthKitAvailable = HKHealthStore.isHealthDataAvailable()
        self.healthKitAuthorized = healthKitService.isAuthorized()
    }

    // MARK: - Public Actions

    /// Set the rest timer manager (called from ActiveWorkoutSheetView)
    func setRestTimerManager(_ manager: RestTimerStateManager) {
        self.restTimerManager = manager
    }

    /// Request HealthKit permissions
    func requestHealthKitPermission() async {
        let result = await healthKitService.requestAuthorization()

        switch result {
        case .success:
            healthKitAuthorized = true
            showSuccessMessage("Apple Health verbunden")
            print("✅ HealthKit authorization granted")
        case .failure(let error):
            healthKitAuthorized = false
            print("❌ HealthKit authorization failed: \(error)")
        }
    }

    /// Start a new workout session
    /// - Parameter workoutId: ID of the workout template to start
    /// - Throws: UseCaseError if session cannot be started
    func startSession(workoutId: UUID) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            currentSession = try await startSessionUseCase.execute(workoutId: workoutId)
            showSuccessMessage("Workout gestartet!")
        } catch {
            self.error = error
            print("❌ Failed to start session: \(error)")
        }
    }

    /// Complete a set in the current session
    /// - Parameters:
    ///   - exerciseId: ID of the exercise containing the set
    ///   - setId: ID of the set to complete
    func completeSet(exerciseId: UUID, setId: UUID) async {
        guard let sessionId = currentSession?.id else {
            error = NSError(
                domain: "SessionStore", code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "No active session"
                ])
            return
        }

        // OPTIMISTIC UPDATE: Update UI immediately (before await)
        print("🔵 BEFORE updateLocalSet - currentSession exists: \(currentSession != nil)")
        updateLocalSet(exerciseId: exerciseId, setId: setId, completed: true)
        print("🔵 AFTER updateLocalSet - currentSession updated")

        do {
            // Execute use case (async - happens in background)
            try await completeSetUseCase.execute(
                sessionId: sessionId,
                exerciseId: exerciseId,
                setId: setId
            )

            // Refresh from repository to ensure consistency
            await refreshCurrentSession()

            // Check if exercise is now complete (AFTER refresh to get accurate state)
            let exerciseCompleted = checkIfExerciseCompleted(exerciseId: exerciseId)
            print("🔍 Exercise completed check: \(exerciseCompleted) for exerciseId: \(exerciseId)")

            // Show notification if exercise was just completed
            if exerciseCompleted {
                // Check if this was the last exercise
                let isLastExercise = checkIfAllExercisesCompleted()
                let message = isLastExercise ? "Workout done! 💪🏼" : "Nächste Übung"
                print("✅ Showing notification: \(message)")
                showSuccessMessage(message)
            }

        } catch {
            self.error = error
            print("❌ Failed to complete set: \(error)")

            // Revert optimistic update on error
            await refreshCurrentSession()
        }
    }

    /// End the current workout session
    func endSession() async {
        guard let sessionId = currentSession?.id else {
            error = NSError(
                domain: "SessionStore", code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "No active session"
                ])
            return
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let finishedSession = try await endSessionUseCase.execute(sessionId: sessionId)

            // Cancel any pending rest timer notifications
            restTimerManager?.cancelRest()
            print("🔕 Rest timer notification cancelled on workout end")

            // Save completed session for summary display
            completedSession = finishedSession

            // Clear active session immediately
            currentSession = nil

            showSuccessMessage("Workout abgeschlossen! 🎉")
        } catch {
            self.error = error
            print("❌ Failed to end session: \(error)")
        }
    }

    /// Cancel (discard) the current workout session without saving
    func cancelSession() async {
        guard let sessionId = currentSession?.id else {
            error = NSError(
                domain: "SessionStore", code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "No active session"
                ])
            return
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await cancelSessionUseCase.execute(sessionId: sessionId)

            // Cancel any pending rest timer notifications
            restTimerManager?.cancelRest()
            print("🔕 Rest timer notification cancelled on workout cancel")

            // Clear active session immediately (no completedSession, no summary)
            currentSession = nil

            showSuccessMessage("Workout abgebrochen")
            print("🗑️ Session canceled successfully")
        } catch {
            self.error = error
            print("❌ Failed to cancel session: \(error)")
        }
    }

    /// Pause the current workout session
    func pauseSession() async {
        guard let sessionId = currentSession?.id else { return }

        do {
            try await pauseSessionUseCase.execute(sessionId: sessionId)
            await refreshCurrentSession()
            showSuccessMessage("Workout pausiert")
        } catch {
            self.error = error
            print("❌ Failed to pause session: \(error)")
        }
    }

    /// Resume the current workout session
    func resumeSession() async {
        guard let sessionId = currentSession?.id else { return }

        do {
            try await resumeSessionUseCase.execute(sessionId: sessionId)
            await refreshCurrentSession()
            showSuccessMessage("Workout fortgesetzt")
        } catch {
            self.error = error
            print("❌ Failed to resume session: \(error)")
        }
    }

    /// Load the currently active session (if any)
    /// Call this on app launch to restore active session
    func loadActiveSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            currentSession = try await sessionRepository.fetchActiveSession()
        } catch {
            self.error = error
            print("❌ Failed to load active session: \(error)")
        }
    }

    /// Update weight and/or reps of a set
    /// - Parameters:
    ///   - exerciseId: ID of the exercise containing the set
    ///   - setId: ID of the set to update
    ///   - weight: New weight value (optional)
    ///   - reps: New reps value (optional)
    func updateSet(
        exerciseId: UUID,
        setId: UUID,
        weight: Double? = nil,
        reps: Int? = nil
    ) async {
        guard let sessionId = currentSession?.id else {
            error = NSError(
                domain: "SessionStore", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No active session"]
            )
            return
        }

        // OPTIMISTIC UPDATE: Update UI immediately
        updateLocalSetValues(exerciseId: exerciseId, setId: setId, weight: weight, reps: reps)

        do {
            let updatedSession = try await updateSetUseCase.execute(
                sessionId: sessionId,
                exerciseId: exerciseId,
                setId: setId,
                weight: weight,
                reps: reps
            )

            // Update with persisted session
            currentSession = updatedSession

        } catch {
            self.error = error
            print("❌ Failed to update set: \(error)")

            // Revert optimistic update on error
            await refreshCurrentSession()
        }
    }

    /// Update weight and/or reps for ALL incomplete sets in an exercise
    /// - Parameters:
    ///   - exerciseId: ID of the exercise
    ///   - weight: New weight value (optional)
    ///   - reps: New reps value (optional)
    func updateAllSets(
        exerciseId: UUID,
        weight: Double? = nil,
        reps: Int? = nil
    ) async {
        guard let sessionId = currentSession?.id else {
            error = NSError(
                domain: "SessionStore", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No active session"]
            )
            return
        }

        do {
            let updatedSession = try await updateAllSetsUseCase.execute(
                sessionId: sessionId,
                exerciseId: exerciseId,
                weight: weight,
                reps: reps
            )

            // Force UI update
            currentSession = nil
            currentSession = updatedSession

            print("✅ All sets updated successfully")

        } catch {
            self.error = error
            print("❌ Failed to update all sets: \(error)")
        }
    }

    /// Update notes for an exercise
    /// - Parameters:
    ///   - exerciseId: ID of the exercise
    ///   - notes: New notes text (overwrites existing)
    func updateExerciseNotes(exerciseId: UUID, notes: String) async {
        guard let sessionId = currentSession?.id else {
            error = NSError(
                domain: "SessionStore", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No active session"]
            )
            return
        }

        do {
            try await updateExerciseNotesUseCase.execute(
                sessionId: sessionId,
                exerciseId: exerciseId,
                notes: notes
            )

            // Refresh session to get updated notes
            await refreshCurrentSession()

            showSuccessMessage("Notiz gespeichert")
            print("✅ Exercise notes updated successfully")

        } catch {
            self.error = error
            print("❌ Failed to update exercise notes: \(error)")
        }
    }

    /// Add a new set to an exercise
    /// - Parameters:
    ///   - exerciseId: ID of the exercise
    ///   - weight: Weight for the new set (optional, defaults to last set's weight)
    ///   - reps: Reps for the new set (optional, defaults to last set's reps)
    func addSet(
        exerciseId: UUID,
        weight: Double? = nil,
        reps: Int? = nil
    ) async {
        guard let sessionId = currentSession?.id else {
            error = NSError(
                domain: "SessionStore", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No active session"]
            )
            return
        }

        do {
            let updatedSession = try await addSetUseCase.execute(
                sessionId: sessionId,
                exerciseId: exerciseId,
                weight: weight,
                reps: reps
            )

            // Force UI update
            currentSession = nil
            currentSession = updatedSession

            print("✅ Set added successfully")

        } catch {
            self.error = error
            print("❌ Failed to add set: \(error)")
        }
    }

    /// Add warmup sets to an exercise
    /// - Parameters:
    ///   - exerciseId: ID of the exercise
    ///   - warmupSets: Array of warmup sets to add
    func addWarmupSets(
        exerciseId: UUID,
        warmupSets: [WarmupCalculator.WarmupSet]
    ) async {
        guard let sessionId = currentSession?.id,
            var session = currentSession
        else {
            error = NSError(
                domain: "SessionStore", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No active session"]
            )
            return
        }

        // Find the exercise
        guard let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId })
        else {
            error = NSError(
                domain: "SessionStore", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Exercise not found"]
            )
            return
        }

        var exercise = session.exercises[exerciseIndex]

        // Create warmup set entities
        let newSets = warmupSets.enumerated().map { index, warmupSet in
            DomainSessionSet(
                weight: warmupSet.weight,
                reps: warmupSet.reps,
                completed: false,
                orderIndex: index,  // Warmup sets come first
                isWarmup: true
            )
        }

        // Update orderIndex for existing sets (shift them down)
        var updatedExistingSets = exercise.sets.map { set in
            var updatedSet = set
            updatedSet.orderIndex += warmupSets.count  // Shift down by number of warmup sets
            return updatedSet
        }

        // Combine warmup + existing sets
        exercise.sets = newSets + updatedExistingSets
        session.exercises[exerciseIndex] = exercise

        // Save to repository
        do {
            try await sessionRepository.update(session)

            // Force UI update
            currentSession = nil
            currentSession = try await sessionRepository.fetch(id: sessionId)

            showSuccessMessage("Aufwärmsätze hinzugefügt")
            print("✅ Added \(warmupSets.count) warmup sets")

        } catch {
            self.error = error
            print("❌ Failed to add warmup sets: \(error)")
        }
    }

    /// Remove a set from an exercise
    /// - Parameters:
    ///   - exerciseId: ID of the exercise
    ///   - setId: ID of the set to remove
    func removeSet(
        exerciseId: UUID,
        setId: UUID
    ) async {
        guard let sessionId = currentSession?.id else {
            error = NSError(
                domain: "SessionStore", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No active session"]
            )
            return
        }

        do {
            let updatedSession = try await removeSetUseCase.execute(
                sessionId: sessionId,
                exerciseId: exerciseId,
                setId: setId
            )

            // Force UI update
            currentSession = nil
            currentSession = updatedSession

            print("✅ Set removed successfully")

        } catch {
            self.error = error
            print("❌ Failed to remove set: \(error)")
        }
    }

    /// Refresh current session from repository
    /// Useful after background operations or app returning from background
    func refreshCurrentSession() async {
        guard let sessionId = currentSession?.id else { return }

        do {
            currentSession = try await sessionRepository.fetch(id: sessionId)
        } catch {
            self.error = error
            print("❌ Failed to refresh session: \(error)")
        }
    }

    /// Get exercise name for a given exercise ID
    /// - Parameter exerciseId: ID of the exercise
    /// - Returns: Exercise name or "Übung" as fallback
    func getExerciseName(for exerciseId: UUID) async -> String {
        do {
            guard let exercise = try await exerciseRepository.fetch(id: exerciseId) else {
                print("⚠️ Exercise not found: \(exerciseId)")
                return "Übung"
            }
            return exercise.name
        } catch {
            print("❌ Failed to fetch exercise name: \(error)")
            return "Übung"
        }
    }

    /// Get exercise equipment for a given exercise ID
    /// - Parameter exerciseId: ID of the exercise
    /// - Returns: Equipment type or nil if not found
    func getExerciseEquipment(for exerciseId: UUID) async -> String? {
        do {
            guard let exercise = try await exerciseRepository.fetch(id: exerciseId) else {
                return nil
            }
            return exercise.equipmentTypeRaw
        } catch {
            print("❌ Failed to fetch exercise equipment: \(error)")
            return nil
        }
    }

    /// Mark all sets of an exercise as complete
    /// - Parameter exerciseId: ID of the exercise
    /// Finish an exercise (mark as done, move to next)
    /// Sets remain in their current state (may be incomplete)
    func finishExercise(exerciseId: UUID) async {
        guard let sessionId = currentSession?.id else {
            error = NSError(
                domain: "SessionStore", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No active session"]
            )
            return
        }

        do {
            // Execute and get updated session directly (no refresh needed!)
            let updatedSession = try await finishExerciseUseCase.execute(
                sessionId: sessionId,
                exerciseId: exerciseId
            )

            // Update UI immediately
            currentSession = updatedSession

            print("✅ Exercise finished: \(exerciseId)")

            // Check if this was the last exercise
            let allExercisesFinished = updatedSession.exercises.allSatisfy { $0.isFinished }

            if allExercisesFinished {
                // All exercises finished
                showSuccessMessage("Workout done! 💪🏼")
            } else {
                // More exercises to go
                showSuccessMessage("Nächste Übung")
                print("➡️ Exercise finished, more to go - showing next exercise message")
            }
        } catch {
            self.error = error
            print("❌ Failed to finish exercise: \(error)")
        }
    }

    /// Reorder exercises in the current session
    /// - Parameters:
    ///   - source: Source indices of exercises to move
    ///   - destination: Destination index
    func reorderExercises(reorderedExercises: [DomainSessionExercise], savePermanently: Bool) async
    {
        print("🔄 reorderExercises called - savePermanently: \(savePermanently)")
        print("🔄 Received \(reorderedExercises.count) exercises")

        guard let sessionId = currentSession?.id else {
            error = NSError(
                domain: "SessionStore", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No active session"]
            )
            return
        }

        // OPTIMISTIC UPDATE: Update UI immediately
        guard var session = currentSession else { return }

        print("🔄 Current session has \(session.exercises.count) exercises")
        print(
            "🔄 Old order: \(session.exercises.sorted { $0.orderIndex < $1.orderIndex }.map { $0.exerciseId })"
        )

        // Update orderIndex based on new order
        var updatedExercises = reorderedExercises
        for (index, var exercise) in updatedExercises.enumerated() {
            exercise.orderIndex = index
            updatedExercises[index] = exercise
        }

        print("🔄 New order: \(updatedExercises.map { $0.exerciseId })")

        session.exercises = updatedExercises

        // Force SwiftUI to detect the change by setting to nil first
        let updatedSession = session
        currentSession = nil
        currentSession = updatedSession

        print("✅ UI updated optimistically")

        // Persist changes to session
        do {
            try await sessionRepository.update(session)
            print("✅ Session updated in repository")

            // If savePermanently is enabled, also update the workout template
            if savePermanently {
                print("💾 Saving permanently to workout template...")
                await updateWorkoutOrder(
                    workoutId: session.workoutId,
                    exerciseOrder: updatedExercises.map { $0.exerciseId }
                )
            } else {
                print("⚠️ NOT saving permanently (toggle was OFF)")
            }

            // DO NOT refresh - we already updated UI optimistically
            // Refreshing would reload from DB and overwrite our changes
            // await refreshCurrentSession()

            print("✅ Exercises reordered successfully")
        } catch {
            self.error = error
            print("❌ Failed to reorder exercises: \(error)")

            // Revert optimistic update on error
            await refreshCurrentSession()
        }
    }

    /// Add exercise to active session (with optional workout template update)
    ///
    /// **Parameters:**
    /// - exerciseId: Exercise from catalog to add
    /// - savePermanently: If true, also adds exercise to workout template
    func addExerciseToSession(exerciseId: UUID, savePermanently: Bool) async {
        guard let sessionId = currentSession?.id else {
            error = NSError(
                domain: "SessionStore", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No active session"]
            )
            return
        }

        guard let workoutId = currentSession?.workoutId else {
            error = NSError(
                domain: "SessionStore", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No workout ID in session"]
            )
            return
        }

        do {
            // 1. Add to session
            let updatedSession = try await addExerciseToSessionUseCase.execute(
                sessionId: sessionId,
                exerciseId: exerciseId
            )

            // 2. Update UI immediately
            currentSession = nil
            currentSession = updatedSession

            // 3. If permanent save requested, add to workout template
            if savePermanently {
                try await addExerciseToWorkoutTemplate(
                    workoutId: workoutId,
                    exerciseId: exerciseId
                )
            }

            showSuccessMessage("Übung hinzugefügt")
            print("✅ Exercise added to session (permanent: \(savePermanently))")

        } catch {
            self.error = error
            print("❌ Failed to add exercise: \(error)")
        }
    }

    // MARK: - Private Helpers

    /// Update workout template exercise order (for permanent save)
    private func updateWorkoutOrder(workoutId: UUID, exerciseOrder: [UUID]) async {
        do {
            print("💾 Updating workout order directly in SwiftData...")
            print("💾 Workout ID: \(workoutId)")
            print("💾 Requested order: \(exerciseOrder)")

            // Use new method that updates orderIndex WITHOUT recreating exercises
            try await workoutRepository.updateExerciseOrder(
                workoutId: workoutId,
                exerciseOrder: exerciseOrder
            )

            print("✅ Workout template order updated permanently")
        } catch {
            print("❌ Failed to update workout order: \(error)")
            self.error = error
        }
    }

    /// Add exercise to workout template (for permanent save)
    private func addExerciseToWorkoutTemplate(workoutId: UUID, exerciseId: UUID) async throws {
        print("💾 Adding exercise to workout template...")
        print("💾 Workout ID: \(workoutId)")
        print("💾 Exercise ID: \(exerciseId)")

        // Fetch exercise to get default values
        guard let exercise = try? await exerciseRepository.fetch(id: exerciseId) else {
            throw NSError(
                domain: "SessionStore",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Exercise not found"]
            )
        }

        // Fetch current workout
        guard let workout = try? await workoutRepository.fetch(id: workoutId) else {
            throw NSError(
                domain: "SessionStore",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Workout not found"]
            )
        }

        // Determine next orderIndex
        let maxOrderIndex = workout.exercises.map { $0.orderIndex }.max() ?? -1
        let newOrderIndex = maxOrderIndex + 1

        // Create new workout exercise
        let newWorkoutExercise = WorkoutExercise(
            exerciseId: exerciseId,
            targetSets: exercise.lastUsedSetCount ?? 3,
            targetReps: exercise.lastUsedReps ?? 8,
            targetTime: nil,
            targetWeight: exercise.lastUsedWeight,
            restTime: exercise.lastUsedRestTime ?? 90.0,
            orderIndex: newOrderIndex,
            notes: nil
        )

        // Add to workout
        var updatedWorkout = workout
        updatedWorkout.exercises.append(newWorkoutExercise)

        // Save workout
        try await workoutRepository.update(updatedWorkout)

        print("✅ Exercise added to workout template permanently")
    }

    /// Optimistic update of set completion in local state
    /// This provides instant UI feedback while async operation completes
    private func updateLocalSet(exerciseId: UUID, setId: UUID, completed: Bool) {
        guard var session = currentSession else {
            print("❌ updateLocalSet: No current session")
            return
        }

        // Find exercise index
        guard let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId })
        else {
            print("❌ updateLocalSet: Exercise not found: \(exerciseId)")
            return
        }

        // Find set index
        guard
            let setIndex = session.exercises[exerciseIndex].sets.firstIndex(where: {
                $0.id == setId
            })
        else {
            print("❌ updateLocalSet: Set not found: \(setId)")
            return
        }

        print("✅ updateLocalSet: Found exercise[\(exerciseIndex)] set[\(setIndex)]")
        print(
            "   - Before: completed = \(session.exercises[exerciseIndex].sets[setIndex].completed)")

        // Update set
        session.exercises[exerciseIndex].sets[setIndex].completed = completed
        session.exercises[exerciseIndex].sets[setIndex].completedAt = completed ? Date() : nil

        print(
            "   - After: completed = \(session.exercises[exerciseIndex].sets[setIndex].completed)")

        // Update published state (TRIGGERS @Published)
        currentSession = session
        print("✅ updateLocalSet: currentSession @Published updated!")
    }

    /// Check if an exercise is now fully completed (all sets done)
    /// - Parameter exerciseId: ID of the exercise to check
    /// - Returns: true if all sets are completed, false otherwise
    private func checkIfExerciseCompleted(exerciseId: UUID) -> Bool {
        guard let session = currentSession else {
            print("⚠️ checkIfExerciseCompleted: No current session")
            return false
        }

        guard let exercise = session.exercises.first(where: { $0.id == exerciseId }) else {
            print("⚠️ checkIfExerciseCompleted: Exercise not found")
            return false
        }

        let completedSets = exercise.sets.filter { $0.completed }.count
        let totalSets = exercise.sets.count
        let isCompleted = exercise.isCompleted

        print(
            "🔍 checkIfExerciseCompleted: \(completedSets)/\(totalSets) sets, isCompleted: \(isCompleted)"
        )

        // Check if all sets are completed
        return isCompleted
    }

    /// Check if all exercises in the current session are completed
    /// - Returns: true if all exercises are completed, false otherwise
    private func checkIfAllExercisesCompleted() -> Bool {
        guard let session = currentSession else { return false }

        let allCompleted = session.exercises.allSatisfy { $0.isCompleted }
        print("🔍 checkIfAllExercisesCompleted: \(allCompleted)")
        return allCompleted
    }

    /// Optimistic update of set weight/reps in local state
    private func updateLocalSetValues(
        exerciseId: UUID,
        setId: UUID,
        weight: Double?,
        reps: Int?
    ) {
        guard var session = currentSession else {
            print("❌ updateLocalSetValues: No current session")
            return
        }

        // Find exercise index
        guard let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId })
        else {
            print("❌ updateLocalSetValues: Exercise not found: \(exerciseId)")
            return
        }

        // Find set index
        guard
            let setIndex = session.exercises[exerciseIndex].sets.firstIndex(where: {
                $0.id == setId
            })
        else {
            print("❌ updateLocalSetValues: Set not found: \(setId)")
            return
        }

        // Update weight if provided
        if let newWeight = weight {
            session.exercises[exerciseIndex].sets[setIndex].weight = newWeight
            print(
                "✏️ Updated local weight: \(session.exercises[exerciseIndex].sets[setIndex].weight)")
        }

        // Update reps if provided
        if let newReps = reps {
            session.exercises[exerciseIndex].sets[setIndex].reps = newReps
            print("✏️ Updated local reps: \(session.exercises[exerciseIndex].sets[setIndex].reps)")
        }

        // Force UI update by creating a new session instance
        // This ensures @Observable triggers properly for nested struct changes
        currentSession = nil
        currentSession = session
        print("✅ updateLocalSetValues: Forced UI update with new session instance")
    }

    /// Show success message with auto-dismiss
    private func showSuccessMessage(_ message: String) {
        successMessage = message

        // Cancel previous task
        successMessageTask?.cancel()

        // Auto-clear after 3 seconds
        successMessageTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            successMessage = nil
        }
    }
}

// MARK: - Computed Properties

extension SessionStore {
    /// Check if there is an active session
    var hasActiveSession: Bool {
        currentSession != nil
    }

    /// Current session duration (live updating)
    var currentDuration: TimeInterval {
        currentSession?.duration ?? 0
    }

    /// Current session progress (0.0 to 1.0)
    var currentProgress: Double {
        currentSession?.progress ?? 0
    }

    /// Total sets in current session
    var totalSets: Int {
        currentSession?.totalSets ?? 0
    }

    /// Completed sets in current session
    var completedSets: Int {
        currentSession?.completedSets ?? 0
    }

    /// Check if current session is paused
    var isPaused: Bool {
        currentSession?.state == .paused
    }
}

// MARK: - Preview Helpers

#if DEBUG
    extension SessionStore {
        /// Create a mock SessionStore for previews
        static var preview: SessionStore {
            let repository = MockSessionRepository()
            let exerciseRepository = MockExerciseRepository()
            let workoutRepository = MockWorkoutRepository()
            let healthKitService = MockHealthKitService()
            return SessionStore(
                startSessionUseCase: DefaultStartSessionUseCase(
                    sessionRepository: repository,
                    exerciseRepository: exerciseRepository,
                    workoutRepository: workoutRepository,
                    healthKitService: healthKitService
                ),
                completeSetUseCase: DefaultCompleteSetUseCase(sessionRepository: repository),
                endSessionUseCase: DefaultEndSessionUseCase(
                    sessionRepository: repository,
                    healthKitService: healthKitService,
                    userProfileRepository: MockUserProfileRepository()
                ),
                cancelSessionUseCase: DefaultCancelSessionUseCase(
                    sessionRepository: repository,
                    healthKitService: MockHealthKitService()
                ),
                pauseSessionUseCase: DefaultPauseSessionUseCase(sessionRepository: repository),
                resumeSessionUseCase: DefaultResumeSessionUseCase(sessionRepository: repository),
                updateSetUseCase: DefaultUpdateSetUseCase(
                    repository: repository,
                    exerciseRepository: exerciseRepository
                ),
                updateAllSetsUseCase: DefaultUpdateAllSetsUseCase(
                    repository: repository,
                    exerciseRepository: exerciseRepository
                ),
                updateExerciseNotesUseCase: DefaultUpdateExerciseNotesUseCase(
                    sessionRepository: repository,
                    workoutRepository: workoutRepository
                ),
                addSetUseCase: DefaultAddSetUseCase(
                    repository: repository,
                    exerciseRepository: exerciseRepository
                ),
                removeSetUseCase: DefaultRemoveSetUseCase(
                    repository: repository
                ),
                reorderExercisesUseCase: DefaultReorderExercisesUseCase(
                    sessionRepository: repository
                ),
                finishExerciseUseCase: DefaultFinishExerciseUseCase(
                    sessionRepository: repository
                ),
                addExerciseToSessionUseCase: DefaultAddExerciseToSessionUseCase(
                    sessionRepository: repository,
                    exerciseRepository: exerciseRepository
                ),
                sessionRepository: repository,
                exerciseRepository: exerciseRepository,
                workoutRepository: workoutRepository,
                healthKitService: healthKitService
            )
        }

        /// Create a preview SessionStore with active session
        static var previewWithSession: SessionStore {
            let store = SessionStore.preview
            store.currentSession = .preview
            return store
        }
    }

    /// Mock UserProfileRepository for previews
    private class MockUserProfileRepository: UserProfileRepositoryProtocol {
        func fetchOrCreate() async throws -> DomainUserProfile {
            DomainUserProfile(bodyMass: 80.0, height: 175.0, weeklyWorkoutGoal: 3)
        }

        func update(_ profile: DomainUserProfile) async throws {}

        func updateBodyMetrics(bodyMass: Double?, height: Double?) async throws {}

        func updateWeeklyWorkoutGoal(_ goal: Int) async throws {}

        func updatePersonalInfo(
            name: String?, age: Int?, experienceLevel: ExperienceLevel?,
            fitnessGoal: FitnessGoal?
        ) async throws {}

        func updateProfileImage(_ imageData: Data?) async throws {}

        func updateSettings(
            healthKitEnabled: Bool?,
            appTheme: AppTheme?
        ) async throws {}

        func updateNotificationSettings(notificationsEnabled: Bool?, liveActivityEnabled: Bool?)
            async throws
        {}
    }
#endif
