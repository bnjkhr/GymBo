//
//  SwiftDataUserProfileRepository.swift
//  GymBo
//
//  Created on 2025-10-27.
//  Data Layer - SwiftData Implementation of UserProfileRepository
//

import Foundation
import SwiftData

/// SwiftData implementation of UserProfileRepository
///
/// **Design:**
/// - Singleton pattern: Only one profile per user
/// - Auto-creates profile on first access
/// - Thread-safe with ModelContext
final class SwiftDataUserProfileRepository: UserProfileRepositoryProtocol {

    private let modelContext: ModelContext
    private let mapper: UserProfileMapper

    init(modelContext: ModelContext, mapper: UserProfileMapper = UserProfileMapper()) {
        self.modelContext = modelContext
        self.mapper = mapper
    }

    func fetchOrCreate() async throws -> DomainUserProfile {
        // Try to fetch existing profile with error recovery
        let descriptor = FetchDescriptor<UserProfileEntity>()

        do {
            let entities = try modelContext.fetch(descriptor)

            if let entity = entities.first {
                // Profile exists and loaded successfully
                return mapper.toDomain(entity)
            } else {
                // No profile exists - create new one
                let newProfile = DomainUserProfile()
                let entity = mapper.toEntity(newProfile)
                modelContext.insert(entity)
                try modelContext.save()

                print("✅ Created new user profile")
                return newProfile
            }
        } catch {
            // ⚠️ MIGRATION FIX: If fetch fails due to schema mismatch,
            // delete corrupted profile and create new one
            print("❌ Failed to fetch UserProfile (migration error): \(error)")
            print("🔧 Attempting to recover by deleting corrupted profile...")

            // Delete all existing profiles
            do {
                let deleteDescriptor = FetchDescriptor<UserProfileEntity>()
                if let corruptedEntities = try? modelContext.fetch(deleteDescriptor) {
                    for entity in corruptedEntities {
                        modelContext.delete(entity)
                    }
                }
                try modelContext.save()
                print("🗑️ Deleted corrupted profile(s)")
            } catch {
                print("⚠️ Could not delete corrupted profiles: \(error)")
            }

            // Create fresh profile
            let newProfile = DomainUserProfile()
            let entity = mapper.toEntity(newProfile)
            modelContext.insert(entity)
            try modelContext.save()

            print("✅ Created new user profile after recovery")
            return newProfile
        }
    }

    func update(_ profile: DomainUserProfile) async throws {
        // Fetch all profiles (should only be one) and find matching one
        let descriptor = FetchDescriptor<UserProfileEntity>()
        let entities = try modelContext.fetch(descriptor)

        guard let entity = entities.first(where: { $0.id == profile.id }) else {
            throw NSError(
                domain: "UserProfileRepository",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Profile not found"]
            )
        }

        mapper.updateEntity(entity, from: profile)
        try modelContext.save()

        print("✅ User profile updated")
    }

    func updateBodyMetrics(bodyMass: Double?, height: Double?) async throws {
        // Fetch or create profile
        var profile = try await fetchOrCreate()

        // Update metrics
        if let mass = bodyMass {
            profile.bodyMass = mass
        }
        if let h = height {
            profile.height = h
        }
        profile.lastHealthKitSync = Date()
        profile.updatedAt = Date()

        // Save
        try await update(profile)

        print(
            "✅ Body metrics updated: weight=\(bodyMass?.description ?? "unchanged") kg, height=\(height?.description ?? "unchanged") cm"
        )
    }

    func updateWeeklyWorkoutGoal(_ goal: Int) async throws {
        // Validate goal (1-7 workouts per week)
        guard goal >= 1 && goal <= 7 else {
            throw NSError(
                domain: "UserProfileRepository",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Weekly workout goal must be between 1 and 7"]
            )
        }

        // Fetch or create profile
        var profile = try await fetchOrCreate()

        // Update goal
        profile.weeklyWorkoutGoal = goal
        profile.updatedAt = Date()

        // Save
        try await update(profile)

        print("✅ Weekly workout goal updated: \(goal) workouts per week")
    }

    func updatePersonalInfo(
        name: String?,
        age: Int?,
        experienceLevel: ExperienceLevel?,
        fitnessGoal: FitnessGoal?
    ) async throws {
        var profile = try await fetchOrCreate()

        if let name = name { profile.name = name }
        if let age = age { profile.age = age }
        if let experience = experienceLevel { profile.experienceLevel = experience }
        if let goal = fitnessGoal { profile.fitnessGoal = goal }
        profile.updatedAt = Date()

        try await update(profile)
        print("✅ Personal info updated")
    }

    func updateProfileImage(_ imageData: Data?) async throws {
        var profile = try await fetchOrCreate()
        profile.profileImageData = imageData
        profile.updatedAt = Date()

        try await update(profile)
        print("✅ Profile image updated")
    }

    func updateSettings(
        healthKitEnabled: Bool?,
        appTheme: AppTheme?
    ) async throws {
        var profile = try await fetchOrCreate()

        if let enabled = healthKitEnabled { profile.healthKitEnabled = enabled }
        if let theme = appTheme { profile.appTheme = theme }
        profile.updatedAt = Date()

        try await update(profile)
        print("✅ Settings updated")
    }

    func updateNotificationSettings(
        notificationsEnabled: Bool?,
        liveActivityEnabled: Bool?
    ) async throws {
        var profile = try await fetchOrCreate()

        if let notifications = notificationsEnabled {
            profile.notificationsEnabled = notifications
        }
        if let liveActivity = liveActivityEnabled { profile.liveActivityEnabled = liveActivity }
        profile.updatedAt = Date()

        try await update(profile)
        print("✅ Notification settings updated")
    }
}
