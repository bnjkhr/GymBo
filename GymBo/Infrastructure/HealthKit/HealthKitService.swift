//
//  HealthKitService.swift
//  GymBo
//
//  Created on 2025-10-27.
//  Infrastructure Layer - HealthKit Service Implementation
//

import Foundation
import HealthKit

final class HealthKitService: HealthKitServiceProtocol {

    // MARK: - Properties

    private let healthStore: HKHealthStore
    private var activeWorkoutBuilder: HKLiveWorkoutBuilder?
    private var activeWorkoutSession: HKWorkoutSession?
    private var activeWorkoutSessionId: String?  // Track session ID ourselves
    private var heartRateContinuation: AsyncStream<Int>.Continuation?

    // MARK: - Init

    init() {
        self.healthStore = HKHealthStore()
    }

    // MARK: - Permissions

    func requestAuthorization() async -> Result<Void, HealthKitError> {
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            return .failure(.notAvailableOnDevice)
        }

        // Define data types to write
        let typesToWrite: Set<HKSampleType> = [
            HKWorkoutType.workoutType(),
            HKQuantityType(.activeEnergyBurned),
        ]

        // Define data types to read
        let typesToRead: Set<HKObjectType> = [
            HKWorkoutType.workoutType(),
            HKQuantityType(.heartRate),
            HKQuantityType(.bodyMass),
            HKQuantityType(.height),
            HKQuantityType(.restingHeartRate),
        ]

        // Request authorization
        do {
            try await healthStore.requestAuthorization(
                toShare: typesToWrite,
                read: typesToRead
            )
            return .success(())
        } catch {
            return .failure(.permissionDenied)
        }
    }

    func isAuthorized() -> Bool {
        let status = healthStore.authorizationStatus(
            for: HKWorkoutType.workoutType()
        )
        return status == .sharingAuthorized
    }

    // MARK: - Workout Session

    func startWorkoutSession(
        type: WorkoutActivityType,
        startDate: Date
    ) async -> Result<String, HealthKitError> {
        // Check if session already active
        guard activeWorkoutSession == nil else {
            return .failure(.sessionAlreadyActive)
        }

        // Map domain type to HKWorkoutActivityType
        let hkActivityType = type.toHKWorkoutActivityType()

        // Create configuration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = hkActivityType
        configuration.locationType = .indoor

        do {
            // Create session
            let session = try HKWorkoutSession(
                healthStore: healthStore,
                configuration: configuration
            )

            // Create builder
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            // Start session
            session.startActivity(with: startDate)
            try await builder.beginCollection(at: startDate)

            // Generate and store session ID
            let sessionId = UUID().uuidString

            // Store references
            self.activeWorkoutSession = session
            self.activeWorkoutBuilder = builder
            self.activeWorkoutSessionId = sessionId

            print("✅ HealthKit session started: \(sessionId)")

            return .success(sessionId)

        } catch {
            print("❌ HealthKit session start failed: \(error)")
            return .failure(.saveFailed(underlying: error))
        }
    }

    func endWorkoutSession(
        sessionId: String,
        endDate: Date,
        totalEnergyBurned: Double,
        totalDistance: Double?,
        metadata: [String: Any]
    ) async -> Result<Void, HealthKitError> {
        guard let session = activeWorkoutSession,
            let builder = activeWorkoutBuilder,
            activeWorkoutSessionId == sessionId
        else {
            return .failure(.sessionNotFound)
        }

        do {
            // End collection
            try await builder.endCollection(at: endDate)

            // End session
            session.end()

            // Finalize workout
            let workout = try await builder.finishWorkout()

            // Add metadata (optional)
            let metadataToSave = metadata.compactMapValues { $0 as? String }
            if !metadataToSave.isEmpty {
                // Note: addMetadata is not directly available, metadata should be added during workout creation
                // For now, we'll add it as a comment in the implementation plan
                print("📝 Metadata for workout: \(metadataToSave)")
            }

            // Clean up
            self.activeWorkoutSession = nil
            self.activeWorkoutBuilder = nil
            self.activeWorkoutSessionId = nil

            print("✅ HealthKit workout saved: \(workout?.uuid.uuidString ?? "unknown")")

            return .success(())

        } catch {
            print("❌ HealthKit workout save failed: \(error)")
            return .failure(.saveFailed(underlying: error))
        }
    }

    func pauseWorkoutSession(sessionId: String) async -> Result<Void, HealthKitError> {
        guard let session = activeWorkoutSession,
            activeWorkoutSessionId == sessionId
        else {
            return .failure(.sessionNotFound)
        }

        session.pause()
        print("⏸️ HealthKit session paused")
        return .success(())
    }

    func resumeWorkoutSession(sessionId: String) async -> Result<Void, HealthKitError> {
        guard let session = activeWorkoutSession,
            activeWorkoutSessionId == sessionId
        else {
            return .failure(.sessionNotFound)
        }

        session.resume()
        print("▶️ HealthKit session resumed")
        return .success(())
    }

    // MARK: - Heart Rate Streaming

    func observeHeartRate() -> AsyncStream<Int> {
        AsyncStream { continuation in
            self.heartRateContinuation = continuation

            let heartRateType = HKQuantityType(.heartRate)

            let query = HKAnchoredObjectQuery(
                type: heartRateType,
                predicate: nil,
                anchor: nil,
                limit: HKObjectQueryNoLimit
            ) { query, samples, deletedObjects, anchor, error in
                self.processHeartRateSamples(samples, continuation: continuation)
            }

            query.updateHandler = { query, samples, deletedObjects, anchor, error in
                self.processHeartRateSamples(samples, continuation: continuation)
            }

            self.healthStore.execute(query)

            continuation.onTermination = { @Sendable _ in
                self.healthStore.stop(query)
            }
        }
    }

    private func processHeartRateSamples(
        _ samples: [HKSample]?,
        continuation: AsyncStream<Int>.Continuation
    ) {
        guard let samples = samples as? [HKQuantitySample] else { return }

        let heartRates = samples.compactMap { sample -> Int? in
            let unit = HKUnit.count().unitDivided(by: .minute())
            return Int(sample.quantity.doubleValue(for: unit))
        }

        if let latest = heartRates.last {
            continuation.yield(latest)
        }
    }

    // MARK: - Body Metrics

    func fetchBodyMass() async -> Result<Double, HealthKitError> {
        let bodyMassType = HKQuantityType(.bodyMass)

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(returning: .failure(.saveFailed(underlying: error)))
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: .failure(.dataNotAvailable))
                    return
                }

                let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: .success(kg))
            }

            self.healthStore.execute(query)
        }
    }

    func fetchHeight() async -> Result<Double, HealthKitError> {
        let heightType = HKQuantityType(.height)

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(returning: .failure(.saveFailed(underlying: error)))
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: .failure(.dataNotAvailable))
                    return
                }

                let cm = sample.quantity.doubleValue(for: .meterUnit(with: .centi))
                continuation.resume(returning: .success(cm))
            }

            self.healthStore.execute(query)
        }
    }

    func fetchRestingHeartRate() async -> Result<Int, HealthKitError> {
        let restingHRType = HKQuantityType(.restingHeartRate)

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: restingHRType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(returning: .failure(.saveFailed(underlying: error)))
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: .failure(.dataNotAvailable))
                    return
                }

                let unit = HKUnit.count().unitDivided(by: .minute())
                let bpm = Int(sample.quantity.doubleValue(for: unit))
                continuation.resume(returning: .success(bpm))
            }

            self.healthStore.execute(query)
        }
    }
}

// MARK: - Helper Extensions

extension WorkoutActivityType {
    func toHKWorkoutActivityType() -> HKWorkoutActivityType {
        switch self {
        case .traditionalStrengthTraining:
            return .traditionalStrengthTraining
        case .functionalStrengthTraining:
            return .functionalStrengthTraining
        case .coreTraining:
            return .coreTraining
        case .flexibility:
            return .flexibility
        case .other:
            return .other
        }
    }
}
