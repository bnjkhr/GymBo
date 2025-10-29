//
//  DependencyContainer+History.swift
//  GymBo
//
//  Created on 2025-10-29.
//  Extension for Session History & Statistics dependencies
//

import Foundation

extension DependencyContainer {

    // MARK: - History & Statistics Use Cases

    /// Creates GetSessionHistoryUseCase
    /// - Returns: Use case for fetching session history
    func makeGetSessionHistoryUseCase() -> GetSessionHistoryUseCaseProtocol {
        return GetSessionHistoryUseCase(
            repository: makeSessionRepository()
        )
    }

    /// Creates CalculateStatisticsUseCase
    /// - Returns: Use case for calculating workout statistics
    func makeCalculateStatisticsUseCase() -> CalculateStatisticsUseCaseProtocol {
        return CalculateStatisticsUseCase(
            repository: makeSessionRepository()
        )
    }

    // MARK: - History Store

    /// Returns the singleton SessionHistoryStore instance
    /// - Returns: Shared SessionHistoryStore instance
    func makeSessionHistoryStore() -> SessionHistoryStore {
        return SessionHistoryStore(
            getHistoryUseCase: makeGetSessionHistoryUseCase(),
            calculateStatsUseCase: makeCalculateStatisticsUseCase()
        )
    }
}
