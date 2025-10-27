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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader

                    // HealthKit Settings
                    healthKitSection

                    // Placeholder for future sections
                    placeholderContent
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
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
}

// MARK: - Preview

#Preview {
    ProfileView()
}
