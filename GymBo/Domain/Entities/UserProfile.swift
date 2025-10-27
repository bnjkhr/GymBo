//
//  UserProfile.swift
//  GymBo
//
//  Created on 2025-10-27.
//  Domain Layer - User Profile Entity
//

import Foundation

// MARK: - Supporting Types

/// User's fitness experience level
enum ExperienceLevel: String, Codable, CaseIterable {
    case beginner = "Weniger als 1 Jahr"
    case intermediate = "1-3 Jahre"
    case advanced = "Mehr als 3 Jahre"
}

/// User's primary fitness goal
enum FitnessGoal: String, Codable, CaseIterable {
    case fitness = "Fitness"
    case weightLoss = "Gewichtsverlust"
    case muscleGain = "Muskelgewinnung"
}

/// App display theme preference
enum AppTheme: String, Codable, CaseIterable {
    case light = "Hell"
    case dark = "Dunkel"
    case system = "System"
}

/// Domain entity representing user profile and body metrics
///
/// **Responsibility:**
/// - Store user's personal information and preferences
/// - Store user's body metrics (weight, height)
/// - Track last sync with Apple Health
/// - Manage app settings and notifications
///
/// **Design:**
/// - Single source of truth for user data
/// - Persisted in SwiftData
/// - Updated from HealthKit or manual input
struct DomainUserProfile: Identifiable, Equatable {

    /// Unique identifier (singleton - only one profile per user)
    let id: UUID

    // MARK: - Personal Information

    /// User's display name
    var name: String?

    /// Profile image data (PNG/JPEG)
    var profileImageData: Data?

    /// User's age in years
    var age: Int?

    /// User's fitness experience level
    var experienceLevel: ExperienceLevel?

    /// User's primary fitness goal
    var fitnessGoal: FitnessGoal?

    // MARK: - Body Metrics

    /// Body mass in kilograms (nil if not set)
    var bodyMass: Double?

    /// Height in centimeters (nil if not set)
    var height: Double?

    /// Weekly workout goal (number of workouts per week)
    var weeklyWorkoutGoal: Int

    /// Last time metrics were synced from HealthKit
    var lastHealthKitSync: Date?

    // MARK: - Settings

    /// Apple Health integration enabled
    var healthKitEnabled: Bool

    /// App display theme (light, dark, system)
    var appTheme: AppTheme

    // MARK: - Notifications

    /// Push notifications enabled
    var notificationsEnabled: Bool

    /// Live Activity enabled for active workouts
    var liveActivityEnabled: Bool

    // MARK: - Metadata

    /// When profile was created
    let createdAt: Date

    /// Last time profile was updated
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String? = nil,
        profileImageData: Data? = nil,
        age: Int? = nil,
        experienceLevel: ExperienceLevel? = nil,
        fitnessGoal: FitnessGoal? = nil,
        bodyMass: Double? = nil,
        height: Double? = nil,
        weeklyWorkoutGoal: Int = 3,
        lastHealthKitSync: Date? = nil,
        healthKitEnabled: Bool = false,
        appTheme: AppTheme = .system,
        notificationsEnabled: Bool = false,
        liveActivityEnabled: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.profileImageData = profileImageData
        self.age = age
        self.experienceLevel = experienceLevel
        self.fitnessGoal = fitnessGoal
        self.bodyMass = bodyMass
        self.height = height
        self.weeklyWorkoutGoal = weeklyWorkoutGoal
        self.lastHealthKitSync = lastHealthKitSync
        self.healthKitEnabled = healthKitEnabled
        self.appTheme = appTheme
        self.notificationsEnabled = notificationsEnabled
        self.liveActivityEnabled = liveActivityEnabled
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
                name: "Max Mustermann",
                age: 28,
                experienceLevel: .intermediate,
                fitnessGoal: .muscleGain,
                bodyMass: 75.5,
                height: 180.0,
                weeklyWorkoutGoal: 4,
                lastHealthKitSync: Date().addingTimeInterval(-3600),
                healthKitEnabled: true,
                appTheme: .system,
                notificationsEnabled: true,
                liveActivityEnabled: true
            )
        }

        static var previewEmpty: DomainUserProfile {
            DomainUserProfile()
        }
    }
#endif
