//
//  UserProfileRepositoryProtocol.swift
//  GymBo
//
//  Created on 2025-10-27.
//  Domain Layer - Repository Protocol for User Profile
//

import Foundation

/// Protocol defining user profile persistence operations
///
/// **Responsibility:**
/// - CRUD operations for user profile
/// - Singleton pattern (one profile per user)
/// - Abstract away persistence details
///
/// **Design Pattern:** Repository Pattern
/// - Domain layer defines interface
/// - Data layer implements with SwiftData
/// - Presentation layer uses via Dependency Injection
protocol UserProfileRepositoryProtocol {

    /// Fetch the user profile (creates default if not exists)
    /// - Returns: User profile (never nil - creates if needed)
    /// - Throws: Repository error if fetch/create fails
    func fetchOrCreate() async throws -> DomainUserProfile

    /// Update existing user profile
    /// - Parameter profile: Updated profile data
    /// - Throws: Repository error if update fails
    func update(_ profile: DomainUserProfile) async throws

    /// Update body metrics from HealthKit import
    /// - Parameters:
    ///   - bodyMass: Body mass in kg (nil to keep existing)
    ///   - height: Height in cm (nil to keep existing)
    /// - Throws: Repository error if update fails
    func updateBodyMetrics(bodyMass: Double?, height: Double?) async throws

    /// Update weekly workout goal
    /// - Parameter goal: Number of workouts per week (1-7)
    /// - Throws: Repository error if update fails
    func updateWeeklyWorkoutGoal(_ goal: Int) async throws

    /// Update personal information
    /// - Parameters:
    ///   - name: User's display name
    ///   - age: User's age in years
    ///   - experienceLevel: Fitness experience level
    ///   - fitnessGoal: Primary fitness goal
    /// - Throws: Repository error if update fails
    func updatePersonalInfo(
        name: String?,
        age: Int?,
        experienceLevel: ExperienceLevel?,
        fitnessGoal: FitnessGoal?
    ) async throws

    /// Update profile image
    /// - Parameter imageData: Image data (PNG/JPEG)
    /// - Throws: Repository error if update fails
    func updateProfileImage(_ imageData: Data?) async throws

    /// Update app settings
    /// - Parameters:
    ///   - healthKitEnabled: Enable HealthKit integration
    ///   - appTheme: App display theme
    /// - Throws: Repository error if update fails
    func updateSettings(
        healthKitEnabled: Bool?,
        appTheme: AppTheme?
    ) async throws

    /// Update notification preferences
    /// - Parameters:
    ///   - notificationsEnabled: Enable push notifications
    ///   - liveActivityEnabled: Enable Live Activity for workouts
    /// - Throws: Repository error if update fails
    func updateNotificationSettings(
        notificationsEnabled: Bool?,
        liveActivityEnabled: Bool?
    ) async throws
}
