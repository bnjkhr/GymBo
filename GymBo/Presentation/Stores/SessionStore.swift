//
//  SessionStore.swift
//  GymTracker
//
//  Created on 2025-10-22.
//  V2 Clean Architecture - Presentation Layer
//

import Combine
import Foundation
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

    /// Loading state for async operations
    var isLoading: Bool = false

    /// Error state (cleared on next operation)
    var error: Error?

    /// Success message for user feedback (auto-clears after 3s)
    var successMessage: String?

    // MARK: - Dependencies (Injected)

    private let startSessionUseCase: StartSessionUseCase
    private let completeSetUseCase: CompleteSetUseCase
    private let endSessionUseCase: EndSessionUseCase
    private let pauseSessionUseCase: PauseSessionUseCase
    private let resumeSessionUseCase: ResumeSessionUseCase
    private let updateSetUseCase: UpdateSetUseCase
    private let updateAllSetsUseCase: UpdateAllSetsUseCase
    private let sessionRepository: SessionRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol

    // MARK: - Private State

    private var successMessageTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        startSessionUseCase: StartSessionUseCase,
        completeSetUseCase: CompleteSetUseCase,
        endSessionUseCase: EndSessionUseCase,
        pauseSessionUseCase: PauseSessionUseCase,
        resumeSessionUseCase: ResumeSessionUseCase,
        updateSetUseCase: UpdateSetUseCase,
        updateAllSetsUseCase: UpdateAllSetsUseCase,
        sessionRepository: SessionRepositoryProtocol,
        exerciseRepository: ExerciseRepositoryProtocol
    ) {
        self.startSessionUseCase = startSessionUseCase
        self.completeSetUseCase = completeSetUseCase
        self.endSessionUseCase = endSessionUseCase
        self.pauseSessionUseCase = pauseSessionUseCase
        self.resumeSessionUseCase = resumeSessionUseCase
        self.updateSetUseCase = updateSetUseCase
        self.updateAllSetsUseCase = updateAllSetsUseCase
        self.sessionRepository = sessionRepository
        self.exerciseRepository = exerciseRepository
    }

    // MARK: - Public Actions

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
            let completedSession = try await endSessionUseCase.execute(sessionId: sessionId)
            currentSession = completedSession

            // Note: We keep currentSession set to allow UI to show summary
            // The View will set currentSession = nil when appropriate

            showSuccessMessage("Workout abgeschlossen! 🎉")
        } catch {
            self.error = error
            print("❌ Failed to end session: \(error)")
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
    func markAllSetsComplete(exerciseId: UUID) async {
        guard let sessionId = currentSession?.id else {
            error = NSError(
                domain: "SessionStore", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No active session"]
            )
            return
        }

        // Find all incomplete sets for this exercise
        guard let exercise = currentSession?.exercises.first(where: { $0.id == exerciseId }) else {
            print("❌ Exercise not found: \(exerciseId)")
            return
        }

        let incompleteSets = exercise.sets.filter { !$0.completed }

        guard !incompleteSets.isEmpty else {
            print("ℹ️ All sets already completed for exercise")
            return
        }

        print("🔵 Marking \(incompleteSets.count) sets as complete")

        // Complete each set
        for set in incompleteSets {
            await completeSet(exerciseId: exerciseId, setId: set.id)
        }

        // Force UI update by fetching fresh session from DB
        do {
            let freshSession = try await sessionRepository.fetch(id: sessionId)
            currentSession = nil
            currentSession = freshSession
        } catch {
            print("❌ Failed to refresh session after marking complete: \(error)")
        }

        print("✅ All sets marked complete")
    }

    // MARK: - Private Helpers

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
            print("✏️ Updated local weight: \(session.exercises[exerciseIndex].sets[setIndex].weight)")
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
            return SessionStore(
                startSessionUseCase: DefaultStartSessionUseCase(
                    sessionRepository: repository,
                    exerciseRepository: exerciseRepository
                ),
                completeSetUseCase: DefaultCompleteSetUseCase(sessionRepository: repository),
                endSessionUseCase: DefaultEndSessionUseCase(sessionRepository: repository),
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
                sessionRepository: repository,
                exerciseRepository: exerciseRepository
            )
        }

        /// Create a preview SessionStore with active session
        static var previewWithSession: SessionStore {
            let store = SessionStore.preview
            store.currentSession = .preview
            return store
        }
    }
#endif
