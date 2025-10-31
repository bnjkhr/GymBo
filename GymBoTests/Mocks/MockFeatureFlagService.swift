//
//  MockFeatureFlagService.swift
//  GymBoTests
//
//  Created for testing purposes
//  Mock implementation of FeatureFlagServiceProtocol
//

import Foundation

@testable import GymBo

/// Mock implementation of FeatureFlagServiceProtocol for testing
final class MockFeatureFlagService: FeatureFlagServiceProtocol {

    // MARK: - Storage

    private var flags: [FeatureFlag: Bool] = [:]

    // MARK: - Call Tracking

    private(set) var isEnabledCallCount = 0
    private(set) var lastCheckedFlag: FeatureFlag?

    // MARK: - FeatureFlagServiceProtocol Methods

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        isEnabledCallCount += 1
        lastCheckedFlag = flag
        return flags[flag] ?? false
    }

    func setEnabled(_ flag: FeatureFlag, enabled: Bool) {
        flags[flag] = enabled
    }

    func allFlags() -> [(flag: FeatureFlag, enabled: Bool)] {
        return FeatureFlag.allCases.map { ($0, flags[$0] ?? false) }
    }

    // MARK: - Test Helper Methods

    func setFlag(_ flag: FeatureFlag, enabled: Bool) {
        flags[flag] = enabled
    }

    func enableFlag(_ flag: FeatureFlag) {
        flags[flag] = true
    }

    func disableFlag(_ flag: FeatureFlag) {
        flags[flag] = false
    }

    func reset() {
        flags.removeAll()
        isEnabledCallCount = 0
        lastCheckedFlag = nil
    }

    func enableAllFlags() {
        for flag in FeatureFlag.allCases {
            flags[flag] = true
        }
    }

    func disableAllFlags() {
        for flag in FeatureFlag.allCases {
            flags[flag] = false
        }
    }
}

// MARK: - Feature Flags (if not already defined in main app)

extension FeatureFlag: CaseIterable {
    static var allCases: [FeatureFlag] {
        return [.dynamicIsland, .liveActivities, .widgets]
    }
}
