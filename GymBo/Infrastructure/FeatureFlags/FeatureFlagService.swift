//
//  FeatureFlagService.swift
//  GymBo
//
//  Created on 2025-10-29.
//  Local feature flag storage using UserDefaults
//

import Foundation

// MARK: - Feature Flag Enum

enum FeatureFlag: String, CaseIterable {
    case exerciseSwap
    case widgets
    case liveActivities
    case dynamicIsland

    var defaultEnabled: Bool {
        switch self {
        case .exerciseSwap: return false
        case .widgets: return false
        case .liveActivities: return false
        case .dynamicIsland: return false
        }
    }
}

// MARK: - Protocol

protocol FeatureFlagServiceProtocol {
    func isEnabled(_ flag: FeatureFlag) -> Bool
    func setEnabled(_ flag: FeatureFlag, enabled: Bool)
    func allFlags() -> [(flag: FeatureFlag, enabled: Bool)]
}

// MARK: - Implementation

final class FeatureFlagService: FeatureFlagServiceProtocol {

    private let defaults: UserDefaults
    private let keyPrefix = "ff_"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        seedDefaultsIfNeeded()
    }

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        let key = storageKey(for: flag)
        if defaults.object(forKey: key) == nil {
            return flag.defaultEnabled
        }
        return defaults.bool(forKey: key)
    }

    func setEnabled(_ flag: FeatureFlag, enabled: Bool) {
        defaults.set(enabled, forKey: storageKey(for: flag))
    }

    func allFlags() -> [(flag: FeatureFlag, enabled: Bool)] {
        FeatureFlag.allCases.map { ($0, isEnabled($0)) }
    }

    // MARK: - Private

    private func storageKey(for flag: FeatureFlag) -> String {
        keyPrefix + flag.rawValue
    }

    private func seedDefaultsIfNeeded() {
        for flag in FeatureFlag.allCases {
            let key = storageKey(for: flag)
            if defaults.object(forKey: key) == nil {
                defaults.set(flag.defaultEnabled, forKey: key)
            }
        }
    }
}


