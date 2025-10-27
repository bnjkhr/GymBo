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
/// - Map DomainUserProfile ↔ UserProfileEntity
/// - Ensure data integrity during conversion
/// - Handle optional fields correctly
struct UserProfileMapper {

    /// Convert domain model to SwiftData entity
    /// - Parameter domain: Domain user profile
    /// - Returns: SwiftData entity
    func toEntity(_ domain: DomainUserProfile) -> UserProfileEntity {
        UserProfileEntity(
            id: domain.id,
            weight: domain.bodyMass,
            height: domain.height,
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
            bodyMass: entity.weight,
            height: entity.height,
            lastHealthKitSync: nil,  // Not tracked in existing entity
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }

    /// Update existing entity with domain model values
    /// - Parameters:
    ///   - entity: Entity to update
    ///   - domain: Domain model with new values
    func updateEntity(_ entity: UserProfileEntity, from domain: DomainUserProfile) {
        entity.weight = domain.bodyMass
        entity.height = domain.height
        entity.updatedAt = Date()
    }
}
