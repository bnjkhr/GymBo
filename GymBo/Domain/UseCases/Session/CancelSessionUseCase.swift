//
//  CancelSessionUseCase.swift
//  GymBo
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use Case for canceling (discarding) a workout session
///
/// **Responsibility:**
/// - Delete session without saving
/// - Remove from repository
/// - No summary, no statistics
///
/// **Business Rules:**
/// - Session must be in `.active` or `.paused` state
/// - Session is deleted, not marked as completed
/// - Used when user wants to discard workout without saving
///
/// **Usage:**
/// ```swift
/// let useCase = DefaultCancelSessionUseCase(repository: repository)
/// try await useCase.execute(sessionId: sessionId)
/// ```
protocol CancelSessionUseCase {
    /// Cancel (discard) a workout session
    /// - Parameter sessionId: ID of the session to cancel
    /// - Throws: UseCaseError if session cannot be canceled
    func execute(sessionId: UUID) async throws
}

// MARK: - Implementation

/// Default implementation of CancelSessionUseCase
final class DefaultCancelSessionUseCase: CancelSessionUseCase {

    // MARK: - Properties

    private let sessionRepository: SessionRepositoryProtocol
    private let healthKitService: HealthKitServiceProtocol

    // MARK: - Initialization

    init(
        sessionRepository: SessionRepositoryProtocol,
        healthKitService: HealthKitServiceProtocol
    ) {
        self.sessionRepository = sessionRepository
        self.healthKitService = healthKitService
    }

    // MARK: - Execute

    func execute(sessionId: UUID) async throws {
        // Fetch session to verify it exists
        guard let session = try await sessionRepository.fetch(id: sessionId) else {
            throw UseCaseError.sessionNotFound(sessionId)
        }

        // BUSINESS RULE: Can only cancel active or paused sessions
        guard session.state == .active || session.state == .paused else {
            throw UseCaseError.invalidOperation(
                "Cannot cancel session in state: \(session.state). Session must be active or paused."
            )
        }

        // Cancel HealthKit session if active (to close Dynamic Island)
        if let healthKitSessionId = session.healthKitSessionId {
            print("🔵 CancelSessionUseCase: Cancelling HealthKit session")
            let result = await healthKitService.cancelWorkoutSession(sessionId: healthKitSessionId)

            switch result {
            case .success:
                print("✅ HealthKit session cancelled (Dynamic Island closed)")
            case .failure(let error):
                print("⚠️ Failed to cancel HealthKit session: \(error)")
            // Continue anyway - still delete from DB
            }
        }

        // Delete session from repository (no save, no statistics)
        do {
            try await sessionRepository.delete(id: sessionId)
            print("🗑️ Session canceled (discarded): \(sessionId)")
        } catch {
            throw UseCaseError.deleteFailed(error)
        }
    }
}
