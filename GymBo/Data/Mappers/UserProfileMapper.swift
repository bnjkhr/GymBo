//
//  UserProfileMapper.swift
//  GymBo
//
//  Created on 2025-10-27.
//  Data Layer - Mapper for UserProfile
//

import Foundation

/// Mapper for converting between Domain and Data layer UserProfile entities
///
/// **Responsibility:**
/// - Map DomainUserProfile ↔ UserProfileEntity (SchemaV3)
/// - Ensure data integrity during conversion
/// - Handle optional fields correctly
/// - Map enum types to raw string values
struct UserProfileMapper {

    /// Convert domain model to SwiftData entity
    /// - Parameter domain: Domain user profile
    /// - Returns: SwiftData entity
    func toEntity(_ domain: DomainUserProfile) -> UserProfileEntity {
        UserProfileEntity(
            id: domain.id,
            displayName: domain.name,
            age: domain.age,
            experienceLevelRaw: domain.experienceLevel?.rawValue,
            fitnessGoalRaw: domain.fitnessGoal?.rawValue,
            weight: domain.bodyMass,
            height: domain.height,
            weeklyWorkoutGoal: domain.weeklyWorkoutGoal,
            lastHealthKitSync: domain.lastHealthKitSync,
            healthKitEnabled: domain.healthKitEnabled,
            appThemeRaw: domain.appTheme.rawValue,
            notificationsEnabled: domain.notificationsEnabled,
            liveActivityEnabled: domain.liveActivityEnabled,
            profileImageData: domain.profileImageData,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
    }

    /// Convert SwiftData entity to domain model
    /// - Parameter entity: SwiftData entity
    /// - Returns: Domain user profile
    func toDomain(_ entity: UserProfileEntity) -> DomainUserProfile {
        DomainUserProfile(
            id: entity.id,
            name: entity.displayName,
            profileImageData: entity.profileImageData,
            age: entity.age,
            experienceLevel: entity.experienceLevelRaw.flatMap { ExperienceLevel(rawValue: $0) },
            fitnessGoal: entity.fitnessGoalRaw.flatMap { FitnessGoal(rawValue: $0) },
            bodyMass: entity.weight,
            height: entity.height,
            weeklyWorkoutGoal: entity.weeklyWorkoutGoal,
            lastHealthKitSync: entity.lastHealthKitSync,
            healthKitEnabled: entity.healthKitEnabled,
            appTheme: AppTheme(rawValue: entity.appThemeRaw) ?? .system,
            notificationsEnabled: entity.notificationsEnabled,
            liveActivityEnabled: entity.liveActivityEnabled,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }

    /// Update existing entity with domain model values
    /// - Parameters:
    ///   - entity: Entity to update
    ///   - domain: Domain model with new values
    func updateEntity(_ entity: UserProfileEntity, from domain: DomainUserProfile) {
        entity.displayName = domain.name
        entity.profileImageData = domain.profileImageData
        entity.age = domain.age
        entity.experienceLevelRaw = domain.experienceLevel?.rawValue
        entity.fitnessGoalRaw = domain.fitnessGoal?.rawValue
        entity.weight = domain.bodyMass
        entity.height = domain.height
        entity.weeklyWorkoutGoal = domain.weeklyWorkoutGoal
        entity.lastHealthKitSync = domain.lastHealthKitSync
        entity.healthKitEnabled = domain.healthKitEnabled
        entity.appThemeRaw = domain.appTheme.rawValue
        entity.notificationsEnabled = domain.notificationsEnabled
        entity.liveActivityEnabled = domain.liveActivityEnabled
        entity.updatedAt = Date()
    }
}
