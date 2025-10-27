//
//  UserProfile.swift
//  GymBo
//
//  Created on 2025-10-27.
//  Domain Layer - User Profile Entity
//

import Foundation

/// Domain entity representing user profile and body metrics
///
/// **Responsibility:**
/// - Store user's body metrics (weight, height)
/// - Track last sync with Apple Health
/// - Provide defaults for calculations when metrics unavailable
///
/// **Design:**
/// - Single source of truth for user data
/// - Persisted in SwiftData
/// - Updated from HealthKit or manual input
struct DomainUserProfile: Identifiable, Equatable {

    /// Unique identifier (singleton - only one profile per user)
    let id: UUID

    /// Body mass in kilograms (nil if not set)
    var bodyMass: Double?

    /// Height in centimeters (nil if not set)
    var height: Double?

    /// Weekly workout goal (number of workouts per week)
    var weeklyWorkoutGoal: Int

    /// Last time metrics were synced from HealthKit
    var lastHealthKitSync: Date?

    /// When profile was created
    let createdAt: Date

    /// Last time profile was updated
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        bodyMass: Double? = nil,
        height: Double? = nil,
        weeklyWorkoutGoal: Int = 3,
        lastHealthKitSync: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.bodyMass = bodyMass
        self.height = height
        self.weeklyWorkoutGoal = weeklyWorkoutGoal
        self.lastHealthKitSync = lastHealthKitSync
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Default body mass for calculations (80kg if not set)
    var bodyMassOrDefault: Double {
        bodyMass ?? 80.0
    }

    /// Default height for calculations (175cm if not set)
    var heightOrDefault: Double {
        height ?? 175.0
    }

    /// Check if metrics are available
    var hasBodyMetrics: Bool {
        bodyMass != nil || height != nil
    }

    /// BMI calculation (if both weight and height available)
    var bmi: Double? {
        guard let mass = bodyMass, let h = height else { return nil }
        let heightInMeters = h / 100.0
        return mass / (heightInMeters * heightInMeters)
    }
}

// MARK: - Preview Helpers

#if DEBUG
    extension DomainUserProfile {
        static var preview: DomainUserProfile {
            DomainUserProfile(
                bodyMass: 75.5,
                height: 180.0,
                weeklyWorkoutGoal: 4,
                lastHealthKitSync: Date().addingTimeInterval(-3600)
            )
        }

        static var previewEmpty: DomainUserProfile {
            DomainUserProfile()
        }
    }
#endif
