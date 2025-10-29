//
//  SessionHistoryStore.swift
//  GymBo
//
//  Created on 2025-10-29.
//  V2 Clean Architecture - Presentation Layer
//

import Foundation
import Observation

/// Store for managing session history and statistics state
///
/// **Responsibility:**
/// - Manage session history state
/// - Fetch history with different filters
/// - Calculate statistics for different periods
/// - Handle loading and error states
///
/// **Usage:**
/// ```swift
/// @Environment(SessionHistoryStore.self) private var historyStore
///
/// await historyStore.loadHistory(filter: .lastMonth)
/// await historyStore.loadStatistics(period: .week)
/// ```
@MainActor
@Observable
final class SessionHistoryStore {

    // MARK: - Published State

    /// Current session history
    private(set) var sessions: [DomainWorkoutSession] = []

    /// Current statistics
    private(set) var statistics: WorkoutStatistics?

    /// Current filter
    private(set) var currentFilter: SessionHistoryFilter = .recent(limit: 20)

    /// Current statistics period
    private(set) var currentPeriod: WorkoutStatistics.TimePeriod = .week

    /// Loading state for history
    private(set) var isLoadingHistory = false

    /// Loading state for statistics
    private(set) var isLoadingStatistics = false

    /// Error state
    private(set) var error: Error?

    // MARK: - Dependencies

    private let getHistoryUseCase: GetSessionHistoryUseCaseProtocol
    private let calculateStatsUseCase: CalculateStatisticsUseCaseProtocol

    // MARK: - Initialization

    init(
        getHistoryUseCase: GetSessionHistoryUseCaseProtocol,
        calculateStatsUseCase: CalculateStatisticsUseCaseProtocol
    ) {
        self.getHistoryUseCase = getHistoryUseCase
        self.calculateStatsUseCase = calculateStatsUseCase
    }

    // MARK: - Public Interface

    /// Load session history with a specific filter
    func loadHistory(filter: SessionHistoryFilter) async {
        isLoadingHistory = true
        error = nil
        currentFilter = filter

        do {
            sessions = try await getHistoryUseCase.execute(filter: filter)
        } catch {
            self.error = error
            sessions = []
        }

        isLoadingHistory = false
    }

    /// Refresh current history
    func refreshHistory() async {
        await loadHistory(filter: currentFilter)
    }

    /// Load statistics for a specific period
    func loadStatistics(period: WorkoutStatistics.TimePeriod) async {
        isLoadingStatistics = true
        error = nil
        currentPeriod = period

        do {
            statistics = try await calculateStatsUseCase.execute(
                period: period, referenceDate: Date())
        } catch {
            self.error = error
            statistics = nil
        }

        isLoadingStatistics = false
    }

    /// Refresh current statistics
    func refreshStatistics() async {
        await loadStatistics(period: currentPeriod)
    }

    /// Load both history and statistics
    func loadAll(filter: SessionHistoryFilter, period: WorkoutStatistics.TimePeriod) async {
        async let historyTask = loadHistory(filter: filter)
        async let statsTask = loadStatistics(period: period)

        await historyTask
        await statsTask
    }

    /// Clear error state
    func clearError() {
        error = nil
    }

    // MARK: - Computed Properties

    /// Grouped sessions by date
    var sessionsByDate: [(Date, [DomainWorkoutSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startDate)
        }

        return
            grouped
            .sorted { $0.key > $1.key }
            .map { ($0.key, $0.value.sorted { $0.startDate > $1.startDate }) }
    }

    /// Grouped sessions by month
    var sessionsByMonth: [(String, [DomainWorkoutSession])] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: sessions) { session in
            let components = calendar.dateComponents([.year, .month], from: session.startDate)
            return calendar.date(from: components)!
        }

        return
            grouped
            .sorted { $0.key > $1.key }
            .map {
                (
                    dateFormatter.string(from: $0.key),
                    $0.value.sorted { $0.startDate > $1.startDate }
                )
            }
    }

    /// Total number of completed workouts
    var totalWorkouts: Int {
        sessions.count
    }

    /// Check if there are any sessions
    var hasHistory: Bool {
        !sessions.isEmpty
    }
}

// MARK: - Preview Helpers

#if DEBUG
    extension SessionHistoryStore {
        /// Create store with mock data for previews
        static func preview(withData: Bool = true) -> SessionHistoryStore {
            let mockRepo = MockSessionRepository()
            let getHistoryUseCase = GetSessionHistoryUseCase(repository: mockRepo)
            let calculateStatsUseCase = CalculateStatisticsUseCase(repository: mockRepo)

            let store = SessionHistoryStore(
                getHistoryUseCase: getHistoryUseCase,
                calculateStatsUseCase: calculateStatsUseCase
            )

            if withData {
                // Pre-populate with preview data
                store.sessions = [
                    .preview,
                    .previewCompleted,
                ]
                store.statistics = .preview
            }

            return store
        }
    }
#endif
