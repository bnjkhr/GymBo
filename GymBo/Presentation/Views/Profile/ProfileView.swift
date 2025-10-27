//
//  ProfileView.swift
//  GymBo
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Profile View
//

import SwiftUI

/// Profile view for user settings and information
///
/// **Features:**
/// - Profile image display (or default icon)
/// - User information (name, stats)
/// - Settings and preferences
/// - Sign out option
///
/// **Design:**
/// - Modern card-based layout
/// - iOS 26 design standards
/// - Clean, minimalist interface
struct ProfileView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore
    @State private var showHealthKitPermission = false
    @State private var userProfile: DomainUserProfile?
    @State private var isLoadingMetrics = false

    private let userProfileRepository: UserProfileRepositoryProtocol
    private let importBodyMetricsUseCase: ImportBodyMetricsUseCase

    init(
        userProfileRepository: UserProfileRepositoryProtocol,
        importBodyMetricsUseCase: ImportBodyMetricsUseCase
    ) {
        self.userProfileRepository = userProfileRepository
        self.importBodyMetricsUseCase = importBodyMetricsUseCase
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader

                    // Body Metrics Section
                    bodyMetricsSection

                    // HealthKit Settings
                    healthKitSection

                    // Placeholder for future sections
                    placeholderContent
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .task {
                await loadUserProfile()
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showHealthKitPermission) {
                HealthKitPermissionView(
                    onAuthorize: {
                        await sessionStore.requestHealthKitPermission()
                        showHealthKitPermission = false
                    },
                    onSkip: {
                        showHealthKitPermission = false
                    }
                )
            }
        }
    }

    // MARK: - Subviews

    private var bodyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Körpermaße")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 12) {
                // Weight Row
                HStack {
                    Image(systemName: "scalemass.fill")
                        .font(.body)
                        .foregroundStyle(.blue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gewicht")
                            .font(.body)
                            .foregroundStyle(.primary)

                        if let weight = userProfile?.bodyMass {
                            Text("\(weight, specifier: "%.1f") kg")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Nicht festgelegt")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)

                // Height Row
                HStack {
                    Image(systemName: "ruler.fill")
                        .font(.body)
                        .foregroundStyle(.green)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Größe")
                            .font(.body)
                            .foregroundStyle(.primary)

                        if let height = userProfile?.height {
                            Text("\(height, specifier: "%.0f") cm")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Nicht festgelegt")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)

                // Import Button
                if sessionStore.healthKitAuthorized {
                    Button {
                        Task {
                            await importBodyMetrics()
                        }
                    } label: {
                        HStack {
                            if isLoadingMetrics {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                            }
                            Text("Aus Apple Health importieren")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoadingMetrics)

                    if let lastSync = userProfile?.lastHealthKitSync {
                        Text("Zuletzt aktualisiert: \(lastSync, style: .relative)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 4)
                    }
                }
            }
        }
    }

    private var healthKitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Apple Health")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "heart.circle.fill")
                        .font(.body)
                        .foregroundStyle(.red)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Health")
                            .font(.body)
                            .foregroundStyle(.primary)

                        Text(sessionStore.healthKitAuthorized ? "Verbunden" : "Nicht verbunden")
                            .font(.caption)
                            .foregroundStyle(sessionStore.healthKitAuthorized ? .green : .secondary)
                    }

                    Spacer()

                    if sessionStore.healthKitAvailable {
                        if sessionStore.healthKitAuthorized {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Button("Verbinden") {
                                showHealthKitPermission = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    } else {
                        Text("Nicht verfügbar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)

                if sessionStore.healthKitAuthorized {
                    Text("Trainings werden automatisch mit Apple Health synchronisiert")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Image or Icon
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.primary)

            // User Name Placeholder
            Text("Benutzer")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Profil wird geladen...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var placeholderContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Einstellungen")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 8) {
                placeholderRow(icon: "person.fill", title: "Persönliche Daten")
                placeholderRow(icon: "chart.bar.fill", title: "Trainingsstatistiken")
                placeholderRow(icon: "gear", title: "Einstellungen")
                placeholderRow(icon: "bell.fill", title: "Benachrichtigungen")
            }

            Text("Details werden später hinzugefügt")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .padding(.top, 4)
        }
    }

    private func placeholderRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(width: 24)

            Text(title)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Helper Methods

    private func loadUserProfile() async {
        do {
            userProfile = try await userProfileRepository.fetchOrCreate()
            print(
                "✅ User profile loaded: weight=\(userProfile?.bodyMass?.description ?? "nil"), height=\(userProfile?.height?.description ?? "nil")"
            )
        } catch {
            print("❌ Failed to load user profile: \(error)")
        }
    }

    private func importBodyMetrics() async {
        isLoadingMetrics = true
        defer { isLoadingMetrics = false }

        // Import from HealthKit
        let result = await importBodyMetricsUseCase.execute()

        switch result {
        case .success(let metrics):
            // Save to repository
            do {
                try await userProfileRepository.updateBodyMetrics(
                    bodyMass: metrics.bodyMass,
                    height: metrics.height
                )

                // Reload profile
                await loadUserProfile()

                print("✅ Body metrics imported and saved")
            } catch {
                print("❌ Failed to save body metrics: \(error)")
            }

        case .failure(let error):
            print("❌ Failed to import body metrics: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var mockRepository = MockUserProfileRepository()
    @Previewable @State var mockUseCase = MockImportBodyMetricsUseCase()

    ProfileView(
        userProfileRepository: mockRepository,
        importBodyMetricsUseCase: mockUseCase
    )
    .environment(SessionStore.preview)
}

// MARK: - Mock Implementations for Preview

private class MockUserProfileRepository: UserProfileRepositoryProtocol {
    func fetchOrCreate() async throws -> DomainUserProfile {
        DomainUserProfile(bodyMass: 75.0, height: 180.0)
    }

    func update(_ profile: DomainUserProfile) async throws {}

    func updateBodyMetrics(bodyMass: Double?, height: Double?) async throws {}
}

private class MockImportBodyMetricsUseCase: ImportBodyMetricsUseCase {
    func execute() async -> Result<BodyMetrics, HealthKitError> {
        .success(BodyMetrics(bodyMass: 75.0, height: 180.0))
    }
}
