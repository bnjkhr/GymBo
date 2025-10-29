//
//  AppSettings.swift
//  GymBo
//
//  Created on 2025-10-27.
//  App-wide settings management
//

import SwiftUI

/// App-wide settings store
@Observable
final class AppSettings {

    var colorScheme: ColorScheme?
    var currentTheme: AppTheme = .system
    var featureFlagStates: [FeatureFlag: Bool] = [:]

    private let userProfileRepository: UserProfileRepositoryProtocol
    private let featureFlagService: FeatureFlagServiceProtocol

    init(
        userProfileRepository: UserProfileRepositoryProtocol,
        featureFlagService: FeatureFlagServiceProtocol
    ) {
        self.userProfileRepository = userProfileRepository
        self.featureFlagService = featureFlagService

        // Load theme from profile
        Task {
            await loadTheme()
        }

        // Load feature flags
        loadFeatureFlags()
    }

    func loadTheme() async {
        do {
            let profile = try await userProfileRepository.fetchOrCreate()
            await MainActor.run {
                currentTheme = profile.appTheme
                switch profile.appTheme {
                case .light:
                    colorScheme = .light
                case .dark:
                    colorScheme = .dark
                case .system:
                    colorScheme = nil
                }
            }
        } catch {
            print("❌ Failed to load theme: \(error)")
        }
    }

    func updateTheme(_ theme: AppTheme) async {
        do {
            try await userProfileRepository.updateSettings(
                healthKitEnabled: nil,
                appTheme: theme
            )

            await MainActor.run {
                currentTheme = theme
                switch theme {
                case .light:
                    colorScheme = .light
                case .dark:
                    colorScheme = .dark
                case .system:
                    colorScheme = nil
                }
            }

            print("✅ Theme updated to: \(theme.rawValue)")
        } catch {
            print("❌ Failed to update theme: \(error)")
        }
    }

    // MARK: - Feature Flags

    func isFeatureEnabled(_ flag: FeatureFlag) -> Bool {
        featureFlagStates[flag] ?? featureFlagService.isEnabled(flag)
    }

    func setFeature(_ flag: FeatureFlag, enabled: Bool) {
        featureFlagService.setEnabled(flag, enabled: enabled)
        featureFlagStates[flag] = enabled
    }

    func loadFeatureFlags() {
        var map: [FeatureFlag: Bool] = [:]
        for entry in featureFlagService.allFlags() {
            map[entry.flag] = entry.enabled
        }
        featureFlagStates = map
    }
}
