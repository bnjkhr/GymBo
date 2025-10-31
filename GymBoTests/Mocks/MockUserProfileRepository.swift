//
//  MockUserProfileRepository.swift
//  GymBoTests
//
//  Created for testing purposes
//  Mock implementation of UserProfileRepositoryProtocol
//

import Foundation

@testable import GymBo

/// Mock implementation of UserProfileRepositoryProtocol for testing
final class MockUserProfileRepository: UserProfileRepositoryProtocol {

    // MARK: - Storage

    private var profile: DomainUserProfile?

    // MARK: - Call Tracking

    private(set) var fetchOrCreateCallCount = 0
    private(set) var updateCallCount = 0
    private(set) var updateBodyMetricsCallCount = 0
    private(set) var updateWeeklyGoalCallCount = 0
    private(set) var lastUpdatedProfile: DomainUserProfile?

    // MARK: - Error Injection

    var fetchOrCreateError: Error?
    var updateError: Error?
    var updateBodyMetricsError: Error?
    var updateWeeklyGoalError: Error?

    // MARK: - Custom Behaviors

    var fetchOrCreateResult: DomainUserProfile?

    // MARK: - UserProfileRepositoryProtocol Methods

    func fetchOrCreate() async throws -> DomainUserProfile {
        fetchOrCreateCallCount += 1

        if let error = fetchOrCreateError {
            throw error
        }

        if let customResult = fetchOrCreateResult {
            return customResult
        }

        if let existingProfile = profile {
            return existingProfile
        }

        // Create default profile
        let defaultProfile = DomainUserProfile(
            id: UUID(),
            name: nil,
            profileImageData: nil,
            age: nil,
            experienceLevel: nil,
            fitnessGoal: nil,
            bodyMass: nil,
            height: nil,
            weeklyWorkoutGoal: 3,
            lastHealthKitSync: nil,
            healthKitEnabled: false,
            appTheme: .system,
            notificationsEnabled: true,
            liveActivityEnabled: true
        )
        profile = defaultProfile
        return defaultProfile
    }

    func update(_ profile: DomainUserProfile) async throws {
        updateCallCount += 1
        lastUpdatedProfile = profile

        if let error = updateError {
            throw error
        }

        self.profile = profile
    }

    func updateBodyMetrics(bodyMass: Double?, height: Double?) async throws {
        updateBodyMetricsCallCount += 1

        if let error = updateBodyMetricsError {
            throw error
        }

        guard var currentProfile = profile else {
            throw RepositoryError.notFound(UUID())
        }

        if let bodyMass = bodyMass {
            currentProfile.bodyMass = bodyMass
        }
        if let height = height {
            currentProfile.height = height
        }

        profile = currentProfile
    }

    func updateWeeklyWorkoutGoal(_ goal: Int) async throws {
        updateWeeklyGoalCallCount += 1

        if let error = updateWeeklyGoalError {
            throw error
        }

        guard var currentProfile = profile else {
            throw RepositoryError.notFound(UUID())
        }

        currentProfile.weeklyWorkoutGoal = goal
        profile = currentProfile
    }

    func updatePersonalInfo(
        name: String?,
        age: Int?,
        experienceLevel: ExperienceLevel?,
        fitnessGoal: FitnessGoal?
    ) async throws {
        guard var currentProfile = profile else {
            throw RepositoryError.notFound(UUID())
        }

        if let name = name {
            currentProfile.name = name
        }
        if let age = age {
            currentProfile.age = age
        }
        if let experienceLevel = experienceLevel {
            currentProfile.experienceLevel = experienceLevel
        }
        if let fitnessGoal = fitnessGoal {
            currentProfile.fitnessGoal = fitnessGoal
        }

        profile = currentProfile
    }

    func updateProfileImage(_ imageData: Data?) async throws {
        guard var currentProfile = profile else {
            throw RepositoryError.notFound(UUID())
        }

        currentProfile.profileImageData = imageData
        profile = currentProfile
    }

    func updateSettings(
        healthKitEnabled: Bool?,
        appTheme: AppTheme?
    ) async throws {
        guard var currentProfile = profile else {
            throw RepositoryError.notFound(UUID())
        }

        if let healthKitEnabled = healthKitEnabled {
            currentProfile.healthKitEnabled = healthKitEnabled
        }
        if let appTheme = appTheme {
            currentProfile.appTheme = appTheme
        }

        profile = currentProfile
    }

    func updateNotificationSettings(
        notificationsEnabled: Bool?,
        liveActivityEnabled: Bool?
    ) async throws {
        guard var currentProfile = profile else {
            throw RepositoryError.notFound(UUID())
        }

        if let notificationsEnabled = notificationsEnabled {
            currentProfile.notificationsEnabled = notificationsEnabled
        }
        if let liveActivityEnabled = liveActivityEnabled {
            currentProfile.liveActivityEnabled = liveActivityEnabled
        }

        profile = currentProfile
    }

    // MARK: - Test Helper Methods

    func reset() {
        fetchOrCreateCallCount = 0
        updateCallCount = 0
        updateBodyMetricsCallCount = 0
        updateWeeklyGoalCallCount = 0
        lastUpdatedProfile = nil

        fetchOrCreateError = nil
        updateError = nil
        updateBodyMetricsError = nil
        updateWeeklyGoalError = nil
        fetchOrCreateResult = nil

        profile = nil
    }

    func setProfile(_ profile: DomainUserProfile) {
        self.profile = profile
    }

    func getProfile() -> DomainUserProfile? {
        return profile
    }

    func hasProfile() -> Bool {
        return profile != nil
    }
}
