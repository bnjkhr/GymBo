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
}
