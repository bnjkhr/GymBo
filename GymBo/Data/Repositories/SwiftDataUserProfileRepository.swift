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
        // Try to fetch existing profile
        let descriptor = FetchDescriptor<UserProfileEntity>()
        let entities = try modelContext.fetch(descriptor)

        if let entity = entities.first {
            // Profile exists
            return mapper.toDomain(entity)
        } else {
            // Create new profile
            let newProfile = DomainUserProfile()
            let entity = mapper.toEntity(newProfile)
            modelContext.insert(entity)
            try modelContext.save()

            print("✅ Created new user profile")
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
}
