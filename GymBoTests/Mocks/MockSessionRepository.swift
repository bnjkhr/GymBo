//
//  MockSessionRepository.swift
//  GymBoTests
//
//  Mock implementation of SessionRepositoryProtocol for testing
//

import Foundation

@testable import GymBo

/// Mock implementation of SessionRepositoryProtocol for testing
final class MockSessionRepository: SessionRepositoryProtocol {

    // MARK: - Storage

    private var sessions: [UUID: DomainWorkoutSession] = [:]

    // MARK: - Call Tracking

    private(set) var saveCallCount = 0
    private(set) var updateCallCount = 0
    private(set) var fetchCallCount = 0
    private(set) var fetchActiveSessionCallCount = 0
    private(set) var deleteCallCount = 0

    private(set) var lastSavedSession: DomainWorkoutSession?
    private(set) var lastUpdatedSession: DomainWorkoutSession?

    // MARK: - Result Injection

    var fetchActiveSessionResult: DomainWorkoutSession?

    // MARK: - Error Injection

    var saveError: Error?
    var updateError: Error?
    var fetchError: Error?
    var deleteError: Error?

    // MARK: - SessionRepositoryProtocol Methods

    func save(_ session: DomainWorkoutSession) async throws {
        saveCallCount += 1
        lastSavedSession = session

        if let error = saveError {
            throw error
        }

        sessions[session.id] = session
    }

    func update(_ session: DomainWorkoutSession) async throws {
        updateCallCount += 1
        lastUpdatedSession = session

        if let error = updateError {
            throw error
        }

        guard sessions[session.id] != nil else {
            throw RepositoryError.notFound(session.id)
        }

        sessions[session.id] = session
    }

    func fetch(id: UUID) async throws -> DomainWorkoutSession? {
        fetchCallCount += 1

        if let error = fetchError {
            throw error
        }

        return sessions[id]
    }

    func fetchActiveSession() async throws -> DomainWorkoutSession? {
        fetchActiveSessionCallCount += 1

        if let error = fetchError {
            throw error
        }

        // Use injected result if provided, otherwise search in storage
        if let injectedResult = fetchActiveSessionResult {
            return injectedResult
        }

        return sessions.values.first { $0.state == .active }
    }

    func fetchSessions(for workoutId: UUID) async throws -> [DomainWorkoutSession] {
        if let error = fetchError {
            throw error
        }

        return sessions.values
            .filter { $0.workoutId == workoutId }
            .sorted { $0.startDate > $1.startDate }
    }

    func fetchRecentSessions(limit: Int) async throws -> [DomainWorkoutSession] {
        if let error = fetchError {
            throw error
        }

        return sessions.values
            .sorted { $0.startDate > $1.startDate }
            .prefix(limit)
            .map { $0 }
    }

    func fetchCompletedSessions(from startDate: Date, to endDate: Date) async throws
        -> [DomainWorkoutSession]
    {
        if let error = fetchError {
            throw error
        }

        return sessions.values
            .filter { session in
                session.state == .completed
                    && session.startDate >= startDate
                    && session.startDate <= endDate
            }
            .sorted { $0.startDate > $1.startDate }
    }

    func delete(id: UUID) async throws {
        deleteCallCount += 1

        if let error = deleteError {
            throw error
        }

        guard sessions[id] != nil else {
            throw RepositoryError.notFound(id)
        }

        sessions.removeValue(forKey: id)
    }

    func deleteAll() async throws {
        if let error = deleteError {
            throw error
        }

        sessions.removeAll()
    }

    // MARK: - Test Helper Methods

    func reset() {
        saveCallCount = 0
        updateCallCount = 0
        fetchCallCount = 0
        fetchActiveSessionCallCount = 0
        deleteCallCount = 0

        lastSavedSession = nil
        lastUpdatedSession = nil

        fetchActiveSessionResult = nil

        saveError = nil
        updateError = nil
        fetchError = nil
        deleteError = nil

        sessions.removeAll()
    }

    func addSession(_ session: DomainWorkoutSession) {
        sessions[session.id] = session
    }

    func getAllSessions() -> [DomainWorkoutSession] {
        Array(sessions.values)
    }

    func hasSession(id: UUID) -> Bool {
        sessions[id] != nil
    }
}
