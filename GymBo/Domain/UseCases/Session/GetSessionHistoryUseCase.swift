//
//  GetSessionHistoryUseCase.swift
//  GymBo
//
//  Created on 2025-10-29.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use Case for fetching workout session history
///
/// **Responsibility:**
/// - Fetch completed sessions from repository
/// - Filter and sort sessions based on criteria
/// - Return domain entities for presentation layer
///
/// **Usage:**
/// ```swift
/// let useCase = GetSessionHistoryUseCase(repository: sessionRepository)
/// let sessions = try await useCase.execute(filter: .lastMonth)
/// ```
protocol GetSessionHistoryUseCaseProtocol {
    func execute(filter: SessionHistoryFilter) async throws -> [DomainWorkoutSession]
}

final class GetSessionHistoryUseCase: GetSessionHistoryUseCaseProtocol {

    // MARK: - Dependencies

    private let repository: SessionRepositoryProtocol

    // MARK: - Initialization

    init(repository: SessionRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Execute

    func execute(filter: SessionHistoryFilter) async throws -> [DomainWorkoutSession] {
        let sessions: [DomainWorkoutSession]

        switch filter {
        case .all:
            // Fetch all completed sessions
            sessions = try await repository.fetchCompletedSessions(
                from: Date.distantPast,
                to: Date()
            )

        case .lastWeek:
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
            sessions = try await repository.fetchCompletedSessions(
                from: startDate,
                to: endDate
            )

        case .lastMonth:
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
            sessions = try await repository.fetchCompletedSessions(
                from: startDate,
                to: endDate
            )

        case .lastThreeMonths:
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .month, value: -3, to: endDate) ?? endDate
            sessions = try await repository.fetchCompletedSessions(
                from: startDate,
                to: endDate
            )

        case .lastYear:
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
            sessions = try await repository.fetchCompletedSessions(
                from: startDate,
                to: endDate
            )

        case .dateRange(let start, let end):
            sessions = try await repository.fetchCompletedSessions(
                from: start,
                to: end
            )

        case .forWorkout(let workoutId):
            sessions = try await repository.fetchSessions(for: workoutId)
                .filter { $0.state == .completed }

        case .recent(let limit):
            sessions = try await repository.fetchRecentSessions(limit: limit)
                .filter { $0.state == .completed }
        }

        // Always return sorted by most recent first
        return sessions.sorted { $0.startDate > $1.startDate }
    }
}

// MARK: - Filter Types

enum SessionHistoryFilter {
    /// All completed sessions
    case all

    /// Sessions from the last 7 days
    case lastWeek

    /// Sessions from the last 30 days
    case lastMonth

    /// Sessions from the last 3 months
    case lastThreeMonths

    /// Sessions from the last year
    case lastYear

    /// Sessions within a specific date range
    case dateRange(start: Date, end: Date)

    /// Sessions for a specific workout
    case forWorkout(UUID)

    /// Most recent N sessions
    case recent(limit: Int)

    var displayName: String {
        switch self {
        case .all:
            return "Alle"
        case .lastWeek:
            return "Letzte Woche"
        case .lastMonth:
            return "Letzter Monat"
        case .lastThreeMonths:
            return "Letzte 3 Monate"
        case .lastYear:
            return "Letztes Jahr"
        case .dateRange:
            return "Zeitraum"
        case .forWorkout:
            return "Workout"
        case .recent(let limit):
            return "Letzte \(limit)"
        }
    }
}

// MARK: - Unit Tests

#if DEBUG
    extension GetSessionHistoryUseCase {
        /// Test fixture with mock repository
        static func makeForTesting(sessions: [DomainWorkoutSession] = [])
            -> GetSessionHistoryUseCase
        {
            let mockRepo = MockSessionRepository()
            // Pre-populate mock repository would go here if needed
            return GetSessionHistoryUseCase(repository: mockRepo)
        }
    }
#endif
