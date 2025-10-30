//
//  GetPersonalRecordsUseCase.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Protocol for getting personal records use case
protocol GetPersonalRecordsUseCaseProtocol {
    /// Get all personal records from sessions
    func execute() async throws -> [WorkoutStatistics.PersonalRecord]

    /// Get recent personal records (last N days)
    func getRecent(days: Int) async throws -> [WorkoutStatistics.PersonalRecord]

    /// Get count of total PRs
    func getCount() async throws -> Int

    /// Get count of recent PRs
    func getRecentCount(days: Int) async throws -> Int
}

/// Use case for retrieving and managing personal records
///
/// **Responsibility:**
/// - Fetch sessions from repository
/// - Use PersonalRecordService to detect PRs
/// - Return PR data to presentation layer
///
/// **Usage:**
/// ```swift
/// let useCase = GetPersonalRecordsUseCase(repository: sessionRepository)
/// let allPRs = try await useCase.execute()
/// let weekPRs = try await useCase.getRecent(days: 7)
/// ```
struct GetPersonalRecordsUseCase: GetPersonalRecordsUseCaseProtocol {

    private let sessionRepository: SessionRepositoryProtocol
    private let prService: PersonalRecordService

    init(sessionRepository: SessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
        self.prService = PersonalRecordService()
    }

    /// Get all personal records from all sessions
    func execute() async throws -> [WorkoutStatistics.PersonalRecord] {
        let sessions = try await sessionRepository.getAllSessions()
        return prService.detectPersonalRecords(in: sessions)
    }

    /// Get personal records from the last N days
    /// - Parameter days: Number of days to look back (default: 7)
    /// - Returns: Array of recent personal records
    func getRecent(days: Int = 7) async throws -> [WorkoutStatistics.PersonalRecord] {
        let sessions = try await sessionRepository.getAllSessions()
        return prService.getRecentPRs(from: sessions, days: days)
    }

    /// Get total count of all personal records
    func getCount() async throws -> Int {
        let prs = try await execute()
        return prs.count
    }

    /// Get count of recent personal records (last N days)
    /// - Parameter days: Number of days to look back (default: 7)
    /// - Returns: Count of recent PRs
    func getRecentCount(days: Int = 7) async throws -> Int {
        let recentPRs = try await getRecent(days: days)
        return recentPRs.count
    }
}
