//
//  EndSessionUseCase.swift
//  GymTracker
//
//  Created on 2025-10-22.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use Case for ending a workout session
///
/// **Responsibility:**
/// - Mark session as completed
/// - Set end timestamp
/// - Calculate final statistics
/// - Persist changes to repository
/// - Export to HealthKit (optional)
///
/// **Business Rules:**
/// - Session must be in `.active` or `.paused` state
/// - End date is set to current time
/// - Session state changes to `.completed`
/// - All incomplete sets remain incomplete (not auto-completed)
///
/// **Usage:**
/// ```swift
/// let useCase = DefaultEndSessionUseCase(repository: repository)
/// let completedSession = try await useCase.execute(sessionId: sessionId)
/// ```
protocol EndSessionUseCase {
    /// End a workout session
    /// - Parameter sessionId: ID of the session to end
    /// - Returns: The completed session with updated statistics
    /// - Throws: UseCaseError if session cannot be ended
    func execute(sessionId: UUID) async throws -> DomainWorkoutSession
}

// MARK: - Implementation

/// Default implementation of EndSessionUseCase
final class DefaultEndSessionUseCase: EndSessionUseCase {

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

    func execute(sessionId: UUID) async throws -> DomainWorkoutSession {
        // Fetch session
        guard var session = try await sessionRepository.fetch(id: sessionId) else {
            throw UseCaseError.sessionNotFound(sessionId)
        }

        // BUSINESS RULE: Session must be active or paused
        guard session.state == .active || session.state == .paused else {
            throw UseCaseError.invalidOperation(
                "Cannot end session in state: \(session.state). Session must be active or paused."
            )
        }

        // Mark session as completed
        session.endDate = Date()
        session.state = .completed

        // Update session in repository
        do {
            try await sessionRepository.update(session)
        } catch {
            throw UseCaseError.updateFailed(error)
        }

        // Export to HealthKit (background, non-blocking)
        if let healthKitSessionId = session.healthKitSessionId {
            Task.detached(priority: .background) { [weak self] in
                guard let self = self else { return }

                print("🔵 EndSessionUseCase: Ending HealthKit session")

                // Calculate estimated calories (simple formula)
                let duration = session.duration  // seconds
                let totalVolume = session.totalVolume  // kg
                let estimatedCalories = self.calculateCalories(
                    duration: duration,
                    volume: totalVolume
                )

                // Prepare metadata
                let metadata: [String: Any] = [
                    "totalVolume": totalVolume,
                    "exerciseCount": session.exercises.count,
                    "workoutName": session.workoutName ?? "Workout",
                ]

                let result = await self.healthKitService.endWorkoutSession(
                    sessionId: healthKitSessionId,
                    endDate: session.endDate!,
                    totalEnergyBurned: estimatedCalories,
                    totalDistance: nil,
                    metadata: metadata
                )

                switch result {
                case .success:
                    print("✅ HealthKit workout saved successfully")
                case .failure(let error):
                    print("⚠️ HealthKit save failed: \(error.localizedDescription)")
                }
            }
        }

        return session
    }

    // MARK: - Private Helpers

    /// Simplified calorie estimation
    /// Source: MET (Metabolic Equivalent of Task) for strength training
    /// MET for strength training: ~6.0 (moderate) to 8.0 (vigorous)
    private func calculateCalories(duration: TimeInterval, volume: Double) -> Double {
        let hours = duration / 3600.0
        let met: Double = 6.0  // Conservative estimate
        let bodyWeight: Double = 80.0  // TODO: Get from user profile

        // Formula: Calories = MET × body weight (kg) × time (hours)
        let calories = met * bodyWeight * hours

        return calories
    }
}

// MARK: - Additional Use Case: Pause Session

/// Use Case for pausing a workout session
protocol PauseSessionUseCase {
    /// Pause an active session
    /// - Parameter sessionId: ID of the session to pause
    /// - Throws: UseCaseError if session cannot be paused
    func execute(sessionId: UUID) async throws
}

/// Default implementation of PauseSessionUseCase
final class DefaultPauseSessionUseCase: PauseSessionUseCase {

    private let sessionRepository: SessionRepositoryProtocol

    init(sessionRepository: SessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
    }

    func execute(sessionId: UUID) async throws {
        guard var session = try await sessionRepository.fetch(id: sessionId) else {
            throw UseCaseError.sessionNotFound(sessionId)
        }

        guard session.state == .active else {
            throw UseCaseError.invalidOperation(
                "Cannot pause session in state: \(session.state). Session must be active."
            )
        }

        session.state = .paused
        try await sessionRepository.update(session)
    }
}

// MARK: - Additional Use Case: Resume Session

/// Use Case for resuming a paused workout session
protocol ResumeSessionUseCase {
    /// Resume a paused session
    /// - Parameter sessionId: ID of the session to resume
    /// - Throws: UseCaseError if session cannot be resumed
    func execute(sessionId: UUID) async throws
}

/// Default implementation of ResumeSessionUseCase
final class DefaultResumeSessionUseCase: ResumeSessionUseCase {

    private let sessionRepository: SessionRepositoryProtocol

    init(sessionRepository: SessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
    }

    func execute(sessionId: UUID) async throws {
        guard var session = try await sessionRepository.fetch(id: sessionId) else {
            throw UseCaseError.sessionNotFound(sessionId)
        }

        guard session.state == .paused else {
            throw UseCaseError.invalidOperation(
                "Cannot resume session in state: \(session.state). Session must be paused."
            )
        }

        session.state = .active
        try await sessionRepository.update(session)
    }
}

// MARK: - Tests
// TODO: Move inline tests to separate Test target file
// Tests were removed from production code to avoid XCTest import issues
