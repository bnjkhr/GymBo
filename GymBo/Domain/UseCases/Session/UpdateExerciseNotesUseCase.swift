//
//  UpdateExerciseNotesUseCase.swift
//  GymBo
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use case for updating exercise notes in an active session
///
/// **Responsibility:**
/// - Update notes for a specific exercise
/// - Enforce max length constraint
/// - Persist changes to repository
///
/// **Business Rules:**
/// - New note overwrites old note
/// - Max length: 200 characters (enforced)
/// - Empty string clears the note
///
/// **Usage:**
/// ```swift
/// try await useCase.execute(
///     sessionId: sessionId,
///     exerciseId: exerciseId,
///     notes: "Focus on form today"
/// )
/// ```
protocol UpdateExerciseNotesUseCase {
    /// Update notes for an exercise
    /// - Parameters:
    ///   - sessionId: ID of the session
    ///   - exerciseId: ID of the exercise
    ///   - notes: New notes text (overwrites existing)
    /// - Throws: UseCaseError if session or exercise not found
    func execute(sessionId: UUID, exerciseId: UUID, notes: String) async throws
}

// MARK: - Implementation

final class DefaultUpdateExerciseNotesUseCase: UpdateExerciseNotesUseCase {

    // MARK: - Properties

    private let sessionRepository: SessionRepositoryProtocol
    private let workoutRepository: WorkoutRepositoryProtocol

    // MARK: - Initialization

    init(
        sessionRepository: SessionRepositoryProtocol,
        workoutRepository: WorkoutRepositoryProtocol
    ) {
        self.sessionRepository = sessionRepository
        self.workoutRepository = workoutRepository
    }

    // MARK: - Execute

    func execute(sessionId: UUID, exerciseId: UUID, notes: String) async throws {
        // Fetch session
        guard var session = try await sessionRepository.fetch(id: sessionId) else {
            throw UseCaseError.sessionNotFound(sessionId)
        }

        // Find exercise
        guard let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId })
        else {
            throw UseCaseError.exerciseNotFound(exerciseId)
        }

        // Get the catalog exercise ID from session exercise
        let catalogExerciseId = session.exercises[exerciseIndex].exerciseId

        // Trim and enforce max length
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = String(trimmedNotes.prefix(DomainSessionExercise.maxNotesLength))

        // Update notes in session (for immediate display)
        session.exercises[exerciseIndex].notes = finalNotes.isEmpty ? nil : finalNotes

        // Persist to session
        do {
            try await sessionRepository.update(session)
            print("📝 Notes updated in session for exercise \(exerciseId): \"\(finalNotes)\"")
        } catch {
            throw UseCaseError.updateFailed(error)
        }

        // Also persist to workout template (for future sessions)
        print("🔍 Attempting to persist notes to workout template...")
        print("   - Workout ID: \(session.workoutId)")
        print("   - Catalog Exercise ID: \(catalogExerciseId)")

        do {
            guard var workout = try await workoutRepository.fetch(id: session.workoutId) else {
                print("⚠️ Workout not found, skipping template update")
                return
            }

            print("✅ Workout fetched: '\(workout.name)' with \(workout.exercises.count) exercises")

            // Find the workout exercise by catalog exercise ID
            if let workoutExerciseIndex = workout.exercises.firstIndex(where: {
                $0.exerciseId == catalogExerciseId
            }) {
                print("✅ Found exercise at index \(workoutExerciseIndex)")
                print(
                    "   - Old notes: \"\(workout.exercises[workoutExerciseIndex].notes ?? "nil")\"")
                print("   - New notes: \"\(finalNotes)\"")

                workout.exercises[workoutExerciseIndex].notes =
                    finalNotes.isEmpty ? nil : finalNotes

                try await workoutRepository.update(workout)
                print("✅ Notes persisted to workout template successfully!")
            } else {
                print("❌ Exercise not found in workout template")
                print("   - Looking for exerciseId: \(catalogExerciseId)")
                print("   - Available exercises:")
                for (idx, ex) in workout.exercises.enumerated() {
                    print("     [\(idx)] exerciseId: \(ex.exerciseId)")
                }
            }
        } catch {
            print("❌ Failed to update workout template (session notes still saved): \(error)")
            // Don't throw - session notes are already saved
        }
    }
}
