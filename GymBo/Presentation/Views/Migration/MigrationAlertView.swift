//
//  MigrationAlertView.swift
//  GymBo
//
//  Created on 2025-10-27.
//  Alert view for v1.0 → v2.4.0 database migration
//

import SwiftUI

/// Alert view shown to users upgrading from v1.0
///
/// **Purpose:**
/// - Inform users about major v2.0 redesign
/// - Explain that data cannot be migrated
/// - Get user confirmation before database reset
///
/// **UX:**
/// - Clear, friendly explanation
/// - Positive framing (new features)
/// - Single "Verstanden" button (no choice - data will be reset)
struct MigrationAlertView: View {

    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Alert card
            VStack(spacing: 24) {
                // Icon
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundColor(.black)
                        .symbolEffect(.pulse)

                    Text("GymBo 2.0")
                        .font(.title)
                        .fontWeight(.bold)
                }

                // Message
                VStack(spacing: 16) {
                    Text("Willkommen zur neuen Version!")
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text("GymBo wurde von Grund auf neu entwickelt mit vielen neuen Features:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    // Features list
                    VStack(alignment: .leading, spacing: 12) {
                        featureRow(icon: "folder.fill", text: "Workout-Ordner")
                        featureRow(icon: "heart.fill", text: "Apple Health Integration")
                        featureRow(icon: "clock.fill", text: "Individuelle Pausenzeiten")
                        featureRow(icon: "sparkles", text: "Quick-Setup Workouts")
                        featureRow(icon: "paintbrush.fill", text: "Neues Design")
                    }
                    .padding(.vertical, 8)

                    Divider()

                    Text(
                        "Deine bisherigen Daten können leider nicht übernommen werden. Die App startet mit einer frischen Datenbank."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }

                // Button
                Button {
                    onConfirm()
                } label: {
                    Text("Verstanden, weiter")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(32)
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.black)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()
        }
    }
}

// MARK: - Preview

#if DEBUG
    #Preview {
        MigrationAlertView {
            print("Migration confirmed")
        }
    }
#endif
