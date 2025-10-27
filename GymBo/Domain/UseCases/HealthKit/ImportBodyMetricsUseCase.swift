//
//  ImportBodyMetricsUseCase.swift
//  GymBo
//
//  Created on 2025-10-27.
//  Apple Health Integration - Phase 4: Body Metrics Import
//

import Foundation

/// Use Case for importing body metrics (weight, height) from Apple Health
///
/// **Responsibility:**
/// - Fetch latest body mass and height from HealthKit
/// - Return structured result with optional values
/// - Handle errors gracefully
///
/// **Usage:**
/// ```swift
/// let useCase = DefaultImportBodyMetricsUseCase(healthKitService: healthKitService)
/// let result = await useCase.execute()
///
/// switch result {
/// case .success(let metrics):
///     print("Weight: \(metrics.bodyMass ?? 0) kg")
///     print("Height: \(metrics.height ?? 0) cm")
/// case .failure(let error):
///     print("Failed to import: \(error)")
/// }
/// ```
protocol ImportBodyMetricsUseCase {
    /// Execute body metrics import from HealthKit
    /// - Returns: Result containing BodyMetrics or HealthKitError
    func execute() async -> Result<BodyMetrics, HealthKitError>
}

// MARK: - Body Metrics Model

/// Body metrics imported from HealthKit
struct BodyMetrics: Equatable {
    /// Body mass in kilograms (nil if not available)
    let bodyMass: Double?

    /// Height in centimeters (nil if not available)
    let height: Double?

    /// Timestamp when metrics were fetched
    let fetchedAt: Date

    init(bodyMass: Double? = nil, height: Double? = nil, fetchedAt: Date = Date()) {
        self.bodyMass = bodyMass
        self.height = height
        self.fetchedAt = fetchedAt
    }
}

// MARK: - Default Implementation

final class DefaultImportBodyMetricsUseCase: ImportBodyMetricsUseCase {

    private let healthKitService: HealthKitServiceProtocol

    init(healthKitService: HealthKitServiceProtocol) {
        self.healthKitService = healthKitService
    }

    func execute() async -> Result<BodyMetrics, HealthKitError> {
        // Check if HealthKit is authorized
        guard healthKitService.isAuthorized() else {
            print("⚠️ HealthKit not authorized - cannot import body metrics")
            return .failure(.permissionDenied)
        }

        // Fetch body mass (weight)
        let bodyMassResult = await healthKitService.fetchBodyMass()
        var bodyMass: Double?
        switch bodyMassResult {
        case .success(let mass):
            bodyMass = mass
        case .failure(let error):
            print("⚠️ Failed to fetch body mass: \(error)")
            bodyMass = nil
        }

        // Fetch height
        let heightResult = await healthKitService.fetchHeight()
        var height: Double?
        switch heightResult {
        case .success(let h):
            height = h
        case .failure(let error):
            print("⚠️ Failed to fetch height: \(error)")
            height = nil
        }

        // Return metrics (even if some are nil)
        let metrics = BodyMetrics(
            bodyMass: bodyMass,
            height: height,
            fetchedAt: Date()
        )

        print(
            "✅ Body metrics imported: weight=\(bodyMass?.description ?? "nil") kg, height=\(height?.description ?? "nil") cm"
        )

        return .success(metrics)
    }
}
