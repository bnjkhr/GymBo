//
//  MockHealthKitService.swift
//  GymBoTests
//
//  Created for testing purposes
//  Mock implementation of HealthKitServiceProtocol
//

import Foundation

@testable import GymBo

/// Mock implementation of HealthKitServiceProtocol for testing
final class MockHealthKitService: HealthKitServiceProtocol {

    // MARK: - Call Tracking

    private(set) var requestAuthorizationCallCount = 0
    private(set) var isAuthorizedCallCount = 0
    private(set) var startWorkoutSessionCallCount = 0
    private(set) var endWorkoutSessionCallCount = 0
    private(set) var cancelWorkoutSessionCallCount = 0
    private(set) var pauseWorkoutSessionCallCount = 0
    private(set) var resumeWorkoutSessionCallCount = 0
    private(set) var fetchBodyMassCallCount = 0
    private(set) var fetchHeightCallCount = 0
    private(set) var fetchDateOfBirthCallCount = 0

    // MARK: - Return Values

    var isHealthKitAvailable = true
    var requestAuthorizationResult: Result<Void, HealthKitError> = .success(())
    var isAuthorizedResult = false
    var startWorkoutSessionResult: Result<String, HealthKitError> = .success(UUID().uuidString)
    var endWorkoutSessionResult: Result<Void, HealthKitError> = .success(())
    var cancelWorkoutSessionResult: Result<Void, HealthKitError> = .success(())
    var pauseWorkoutSessionResult: Result<Void, HealthKitError> = .success(())
    var resumeWorkoutSessionResult: Result<Void, HealthKitError> = .success(())
    var fetchBodyMassResult: Result<Double, HealthKitError> = .success(75.0)
    var fetchHeightResult: Result<Double, HealthKitError> = .success(180.0)
    var fetchDateOfBirthResult: Result<Int, HealthKitError> = .success(30)
    var fetchRestingHeartRateResult: Result<Int, HealthKitError> = .success(60)

    // MARK: - HealthKitServiceProtocol Methods

    func requestAuthorization() async -> Result<Void, HealthKitError> {
        requestAuthorizationCallCount += 1
        return requestAuthorizationResult
    }

    func isAuthorized() -> Bool {
        isAuthorizedCallCount += 1
        return isAuthorizedResult
    }

    func startWorkoutSession(type: WorkoutActivityType, startDate: Date) async -> Result<
        String, HealthKitError
    > {
        startWorkoutSessionCallCount += 1
        return startWorkoutSessionResult
    }

    func endWorkoutSession(
        sessionId: String,
        endDate: Date,
        totalEnergyBurned: Double,
        totalDistance: Double?,
        metadata: [String: Any]
    ) async -> Result<Void, HealthKitError> {
        endWorkoutSessionCallCount += 1
        return endWorkoutSessionResult
    }

    func cancelWorkoutSession(sessionId: String) async -> Result<Void, HealthKitError> {
        cancelWorkoutSessionCallCount += 1
        return cancelWorkoutSessionResult
    }

    func pauseWorkoutSession(sessionId: String) async -> Result<Void, HealthKitError> {
        pauseWorkoutSessionCallCount += 1
        return pauseWorkoutSessionResult
    }

    func resumeWorkoutSession(sessionId: String) async -> Result<Void, HealthKitError> {
        resumeWorkoutSessionCallCount += 1
        return resumeWorkoutSessionResult
    }

    func observeHeartRate() -> AsyncStream<Int> {
        // Return empty stream for testing
        return AsyncStream { continuation in
            continuation.finish()
        }
    }

    func fetchBodyMass() async -> Result<Double, HealthKitError> {
        fetchBodyMassCallCount += 1
        return fetchBodyMassResult
    }

    func fetchHeight() async -> Result<Double, HealthKitError> {
        fetchHeightCallCount += 1
        return fetchHeightResult
    }

    func fetchDateOfBirth() async -> Result<Int, HealthKitError> {
        fetchDateOfBirthCallCount += 1
        return fetchDateOfBirthResult
    }

    func fetchRestingHeartRate() async -> Result<Int, HealthKitError> {
        return fetchRestingHeartRateResult
    }

    // MARK: - Test Helper Methods

    func reset() {
        requestAuthorizationCallCount = 0
        isAuthorizedCallCount = 0
        startWorkoutSessionCallCount = 0
        endWorkoutSessionCallCount = 0
        cancelWorkoutSessionCallCount = 0
        pauseWorkoutSessionCallCount = 0
        resumeWorkoutSessionCallCount = 0
        fetchBodyMassCallCount = 0
        fetchHeightCallCount = 0
        fetchDateOfBirthCallCount = 0

        isHealthKitAvailable = true
        requestAuthorizationResult = .success(())
        isAuthorizedResult = false
        startWorkoutSessionResult = .success(UUID().uuidString)
        endWorkoutSessionResult = .success(())
        cancelWorkoutSessionResult = .success(())
        pauseWorkoutSessionResult = .success(())
        resumeWorkoutSessionResult = .success(())
        fetchBodyMassResult = .success(75.0)
        fetchHeightResult = .success(180.0)
        fetchDateOfBirthResult = .success(30)
        fetchRestingHeartRateResult = .success(60)
    }
}
