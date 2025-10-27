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

    private let userProfileRepository: UserProfileRepositoryProtocol

    init(userProfileRepository: UserProfileRepositoryProtocol) {
        self.userProfileRepository = userProfileRepository

        // Load theme from profile
        Task {
            await loadTheme()
        }
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
}
