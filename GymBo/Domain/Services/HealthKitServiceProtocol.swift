//
//  HealthKitServiceProtocol.swift
//  GymBo
//
//  Created on 2025-10-27.
//  Domain Layer - HealthKit Service Protocol
//

import Foundation

/// Protocol für HealthKit-Integration (in Domain Layer)
/// Implementation in Infrastructure Layer
protocol HealthKitServiceProtocol {

    // MARK: - Permissions

    /// Request read/write permissions für alle benötigten Datentypen
    func requestAuthorization() async -> Result<Void, HealthKitError>

    /// Check ob Permissions bereits erteilt
    func isAuthorized() -> Bool

    // MARK: - Workout Session

    /// Start HKWorkoutSession (für Live Activities & Background support)
    func startWorkoutSession(
        type: WorkoutActivityType,
        startDate: Date
    ) async -> Result<String, HealthKitError>  // Returns session ID

    /// End HKWorkoutSession und speichere finales Workout
    func endWorkoutSession(
        sessionId: String,
        endDate: Date,
        totalEnergyBurned: Double,  // kcal
        totalDistance: Double?,  // meters (optional)
        metadata: [String: Any]
    ) async -> Result<Void, HealthKitError>

    /// Pause workout (für Pause-Feature)
    func pauseWorkoutSession(sessionId: String) async -> Result<Void, HealthKitError>

    /// Resume workout
    func resumeWorkoutSession(sessionId: String) async -> Result<Void, HealthKitError>

    // MARK: - Heart Rate Streaming (Apple Watch)

    /// Live Heart Rate während Workout (AsyncStream für SwiftUI)
    func observeHeartRate() -> AsyncStream<Int>

    // MARK: - Body Metrics Import

    /// Fetch latest body weight from Health
    func fetchBodyMass() async -> Result<Double, HealthKitError>  // kg

    /// Fetch height from Health
    func fetchHeight() async -> Result<Double, HealthKitError>  // cm

    // MARK: - Query Historical Data

    /// Fetch resting heart rate (für Analytics)
    func fetchRestingHeartRate() async -> Result<Int, HealthKitError>  // bpm
}

// MARK: - Supporting Types

/// Workout type mapping (Domain → HealthKit)
enum WorkoutActivityType {
    case traditionalStrengthTraining
    case functionalStrengthTraining
    case coreTraining
    case flexibility
    case other
}

/// Domain-level error type
enum HealthKitError: LocalizedError {
    case notAvailableOnDevice  // iPad, Mac
    case permissionDenied
    case dataNotAvailable
    case sessionAlreadyActive
    case sessionNotFound
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notAvailableOnDevice:
            return "Apple Health ist auf diesem Gerät nicht verfügbar"
        case .permissionDenied:
            return "Bitte erlaube Zugriff auf Apple Health in den Einstellungen"
        case .dataNotAvailable:
            return "Keine Daten in Apple Health verfügbar"
        case .sessionAlreadyActive:
            return "Es läuft bereits eine aktive Health-Session"
        case .sessionNotFound:
            return "Health-Session nicht gefunden"
        case .saveFailed(let error):
            return "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }
}

// MARK: - Mock for Testing/Previews

#if DEBUG
    /// Mock implementation of HealthKitService for testing and previews
    final class MockHealthKitService: HealthKitServiceProtocol {

        func requestAuthorization() async -> Result<Void, HealthKitError> {
            return .success(())
        }

        func isAuthorized() -> Bool {
            return true
        }

        func startWorkoutSession(
            type: WorkoutActivityType,
            startDate: Date
        ) async -> Result<String, HealthKitError> {
            return .success(UUID().uuidString)
        }

        func endWorkoutSession(
            sessionId: String,
            endDate: Date,
            totalEnergyBurned: Double,
            totalDistance: Double?,
            metadata: [String: Any]
        ) async -> Result<Void, HealthKitError> {
            return .success(())
        }

        func pauseWorkoutSession(sessionId: String) async -> Result<Void, HealthKitError> {
            return .success(())
        }

        func resumeWorkoutSession(sessionId: String) async -> Result<Void, HealthKitError> {
            return .success(())
        }

        func observeHeartRate() -> AsyncStream<Int> {
            AsyncStream { continuation in
                // Mock heart rate stream - simulate values
                Task {
                    var heartRate = 120
                    while true {
                        continuation.yield(heartRate)
                        heartRate += Int.random(in: -5...5)
                        heartRate = max(100, min(180, heartRate))
                        try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
                    }
                }
            }
        }

        func fetchBodyMass() async -> Result<Double, HealthKitError> {
            return .success(80.0)  // Mock: 80 kg
        }

        func fetchHeight() async -> Result<Double, HealthKitError> {
            return .success(180.0)  // Mock: 180 cm
        }

        func fetchRestingHeartRate() async -> Result<Int, HealthKitError> {
            return .success(65)  // Mock: 65 bpm
        }
    }
#endif
