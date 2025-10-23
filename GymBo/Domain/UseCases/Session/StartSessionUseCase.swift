//
//  StartSessionUseCase.swift
//  GymTracker
//
//  Created on 2025-10-22.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use Case for starting a new workout session
///
/// **Responsibility:**
/// - Create a new DomainWorkoutSession from a workout template
/// - Load exercises from workout template
/// - Ensure no other active sessions exist
/// - Save session to repository
///
/// **Business Rules:**
/// - Only ONE active session allowed at a time
/// - Session starts with all sets marked as incomplete
/// - Session state is `.active` by default
/// - Start date is set to current time
///
/// **Usage:**
/// ```swift
/// let useCase = DefaultStartSessionUseCase(repository: repository)
/// let session = try await useCase.execute(workoutId: workoutId)
/// ```
protocol StartSessionUseCase {
    /// Start a new workout session
    /// - Parameter workoutId: ID of the workout template to use
    /// - Returns: The newly created session
    /// - Throws: UseCaseError if session cannot be started
    func execute(workoutId: UUID) async throws -> DomainWorkoutSession
}

// MARK: - Implementation

/// Default implementation of StartSessionUseCase
final class DefaultStartSessionUseCase: StartSessionUseCase {

    // MARK: - Properties

    private let sessionRepository: SessionRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let workoutRepository: WorkoutRepositoryProtocol

    // MARK: - Initialization

    init(
        sessionRepository: SessionRepositoryProtocol,
        exerciseRepository: ExerciseRepositoryProtocol,
        workoutRepository: WorkoutRepositoryProtocol
    ) {
        self.sessionRepository = sessionRepository
        self.exerciseRepository = exerciseRepository
        self.workoutRepository = workoutRepository
    }

    // MARK: - Execute

    func execute(workoutId: UUID) async throws -> DomainWorkoutSession {
        print("🔵 StartSessionUseCase: Starting execution for workout \(workoutId)")

        // BUSINESS RULE: Only one active session allowed
        if let existingSession = try await sessionRepository.fetchActiveSession() {
            print("❌ StartSessionUseCase: Active session already exists")
            throw UseCaseError.activeSessionExists(existingSession.id)
        }

        // Load workout template from repository
        print("🔵 StartSessionUseCase: Loading workout template")
        guard let workout = try await workoutRepository.fetch(id: workoutId) else {
            print("❌ StartSessionUseCase: Workout not found: \(workoutId)")
            throw UseCaseError.workoutNotFound(workoutId)
        }

        print(
            "✅ StartSessionUseCase: Loaded workout '\(workout.name)' with \(workout.exercises.count) exercises"
        )

        // Convert workout exercises to session exercises
        print("🔵 StartSessionUseCase: Converting workout to session exercises")
        let sessionExercises = await convertToSessionExercises(workout.exercises)
        print("   - Created \(sessionExercises.count) session exercises")

        // Create session
        let session = DomainWorkoutSession(
            workoutId: workoutId,
            startDate: Date(),
            exercises: sessionExercises,
            state: .active,
            workoutName: workout.name
        )

        print("   - Session created with ID: \(session.id.uuidString)")

        // Save session to repository
        print("🔵 StartSessionUseCase: Saving session to repository")
        do {
            try await sessionRepository.save(session)
            print("✅ StartSessionUseCase: Session saved successfully")
        } catch {
            print("❌ StartSessionUseCase: Failed to save session: \(error)")
            throw UseCaseError.saveFailed(error)
        }

        return session
    }

    // MARK: - Private Helpers

    /// Convert workout exercises to session exercises with progressive overload
    /// - Parameter workoutExercises: Exercises from workout template
    /// - Returns: Session exercises with last used values
    private func convertToSessionExercises(_ workoutExercises: [WorkoutExercise]) async
        -> [DomainSessionExercise]
    {
        var sessionExercises: [DomainSessionExercise] = []

        for workoutExercise in workoutExercises {
            // Load exercise from catalog to get last used values
            let exerciseEntity = try? await exerciseRepository.fetch(id: workoutExercise.exerciseId)

            // Use last used values if available, otherwise use template values
            let weight = exerciseEntity?.lastUsedWeight ?? workoutExercise.targetWeight ?? 0.0
            // For time-based exercises (targetReps == nil), use 0 reps as placeholder
            let reps = exerciseEntity?.lastUsedReps ?? workoutExercise.targetReps ?? 0

            print(
                "📊 Exercise: ID=\(workoutExercise.exerciseId), orderIndex=\(workoutExercise.orderIndex)"
            )
            print("   - Weight: \(weight)kg, Reps: \(reps), Sets: \(workoutExercise.targetSets)")

            // Create sets based on target count
            var sets: [DomainSessionSet] = []
            for setIndex in 0..<workoutExercise.targetSets {
                let set = DomainSessionSet(
                    weight: weight,
                    reps: reps,
                    orderIndex: setIndex
                )
                sets.append(set)
            }

            // Create session exercise - use explicit orderIndex from workout template
            let sessionExercise = DomainSessionExercise(
                exerciseId: workoutExercise.exerciseId,
                sets: sets,
                notes: workoutExercise.notes,
                restTimeToNext: workoutExercise.restTime,
                orderIndex: workoutExercise.orderIndex  // ✅ Use explicit orderIndex instead of array position
            )

            sessionExercises.append(sessionExercise)
        }

        return sessionExercises
    }
}

// MARK: - Use Case Errors

/// Errors that can occur during Use Case execution
enum UseCaseError: Error, LocalizedError {
    /// Another session is already active
    case activeSessionExists(UUID)

    /// Workout template not found
    case workoutNotFound(UUID)

    /// Session not found
    case sessionNotFound(UUID)

    /// Set not found in session
    case setNotFound(UUID)

    /// Exercise not found in session
    case exerciseNotFound(UUID)

    /// Invalid exercise order (IDs don't match)
    case invalidExerciseOrder

    /// Invalid input data
    case invalidInput(String)

    /// Failed to save to repository
    case saveFailed(Error)

    /// Failed to update in repository
    case updateFailed(Error)

    /// Invalid operation (e.g., completing already completed set)
    case invalidOperation(String)

    /// Repository error (wraps repository-specific errors)
    case repositoryError(Error)

    /// Unknown error
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .activeSessionExists(let id):
            return
                "Cannot start a new session. Another session (\(id.uuidString)) is already active. Please complete or pause the active session first."
        case .workoutNotFound(let id):
            return "Workout with ID \(id.uuidString) not found"
        case .sessionNotFound(let id):
            return "Session with ID \(id.uuidString) not found"
        case .setNotFound(let id):
            return "Set with ID \(id.uuidString) not found in session"
        case .exerciseNotFound(let id):
            return "Exercise with ID \(id.uuidString) not found in session"
        case .invalidExerciseOrder:
            return "Invalid exercise order: exercise IDs don't match workout"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update: \(error.localizedDescription)"
        case .invalidOperation(let message):
            return "Invalid operation: \(message)"
        case .repositoryError(let error):
            return "Repository error: \(error.localizedDescription)"
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Tests
// TODO: Move inline tests to separate Test target file
// Tests were removed from production code to avoid XCTest import issues
