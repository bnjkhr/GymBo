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

    // MARK: - Initialization

    init(sessionRepository: SessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
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

        // Trim and enforce max length
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = String(trimmedNotes.prefix(DomainSessionExercise.maxNotesLength))

        // Update notes (empty string = clear notes)
        session.exercises[exerciseIndex].notes = finalNotes.isEmpty ? nil : finalNotes

        // Persist changes
        do {
            try await sessionRepository.update(session)
            print("📝 Notes updated for exercise \(exerciseId): \"\(finalNotes)\"")
        } catch {
            throw UseCaseError.updateFailed(error)
        }
    }
}
