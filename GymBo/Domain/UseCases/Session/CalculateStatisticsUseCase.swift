//
//  CalculateStatisticsUseCase.swift
//  GymBo
//
//  Created on 2025-10-29.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Use Case for calculating workout statistics
///
/// **Responsibility:**
/// - Fetch completed sessions from repository
/// - Compute statistics based on session data
/// - Return computed statistics for display
///
/// **Usage:**
/// ```swift
/// let useCase = CalculateStatisticsUseCase(repository: sessionRepository)
/// let stats = try await useCase.execute(period: .week)
/// ```
protocol CalculateStatisticsUseCaseProtocol {
    func execute(period: WorkoutStatistics.TimePeriod, referenceDate: Date, includeWarmupSets: Bool)
        async throws
        -> WorkoutStatistics
}

final class CalculateStatisticsUseCase: CalculateStatisticsUseCaseProtocol {

    // MARK: - Dependencies

    private let repository: SessionRepositoryProtocol

    // MARK: - Initialization

    init(repository: SessionRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Execute

    func execute(
        period: WorkoutStatistics.TimePeriod,
        referenceDate: Date = Date(),
        includeWarmupSets: Bool = false
    ) async throws -> WorkoutStatistics {
        // Get date range for the period
        let dateRange = period.dateRange(from: referenceDate)
        guard let dateRange = dateRange else {
            // Handle this as needed: for now we throw.
            throw NSError(
                domain: "CalculateStatisticsUseCase", code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Could not compute the date range for period \(period)"
                ])
        }

        // Fetch all completed sessions in this period
        let sessions = try await repository.fetchCompletedSessions(
            from: dateRange.start,
            to: dateRange.end
        )

        // Compute statistics from sessions
        let statistics = WorkoutStatistics.compute(
            from: sessions,
            period: period,
            referenceDate: referenceDate,
            includeWarmupSets: includeWarmupSets
        )

        return statistics
    }
}

// MARK: - Multi-Period Statistics

extension CalculateStatisticsUseCase {
    /// Calculate statistics for multiple periods at once
    /// Useful for comparison views
    func executeForPeriods(
        _ periods: [WorkoutStatistics.TimePeriod],
        referenceDate: Date = Date()
    ) async throws -> [WorkoutStatistics.TimePeriod: WorkoutStatistics] {
        var results: [WorkoutStatistics.TimePeriod: WorkoutStatistics] = [:]

        // Calculate all periods concurrently
        try await withThrowingTaskGroup(of: (WorkoutStatistics.TimePeriod, WorkoutStatistics).self)
        { group in
            for period in periods {
                group.addTask {
                    let stats = try await self.execute(period: period, referenceDate: referenceDate)
                    return (period, stats)
                }
            }

            for try await (period, stats) in group {
                results[period] = stats
            }
        }

        return results
    }
}

// MARK: - Unit Tests

#if DEBUG
    extension CalculateStatisticsUseCase {
        /// Test fixture with mock repository
        static func makeForTesting() -> CalculateStatisticsUseCase {
            let mockRepo = MockSessionRepository()
            return CalculateStatisticsUseCase(repository: mockRepo)
        }
    }
#endif
