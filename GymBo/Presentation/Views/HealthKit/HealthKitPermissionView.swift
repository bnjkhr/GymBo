//
//  HealthKitPermissionView.swift
//  GymBo
//
//  Created on 2025-10-27.
//  Presentation Layer - HealthKit Permission Request
//

import SwiftUI

/// View for requesting HealthKit permissions during onboarding or from settings
struct HealthKitPermissionView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var isRequesting = false

    let onAuthorize: () async -> Void
    let onSkip: (() -> Void)?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
                .symbolRenderingMode(.hierarchical)

            // Title
            VStack(spacing: 8) {
                Text("Apple Health Integration")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Synchronisiere deine Workouts automatisch")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Benefits
            VStack(spacing: 20) {
                benefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Automatisches Tracking",
                    subtitle: "Alle Workouts werden in Health gespeichert"
                )

                benefitRow(
                    icon: "heart.fill",
                    title: "Herzfrequenz",
                    subtitle: "Live-Herzfrequenz mit Apple Watch"
                )

                benefitRow(
                    icon: "flame.fill",
                    title: "Kalorien",
                    subtitle: "Verbrannte Kalorien werden exportiert"
                )

                benefitRow(
                    icon: "figure.strengthtraining.traditional",
                    title: "Körpermaße",
                    subtitle: "Gewicht & Größe importieren"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button {
                    Task {
                        isRequesting = true
                        await onAuthorize()
                        isRequesting = false
                        dismiss()
                    }
                } label: {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isRequesting ? "Wird eingerichtet..." : "Zugriff erlauben")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isRequesting)

                if let onSkip = onSkip {
                    Button {
                        onSkip()
                        dismiss()
                    } label: {
                        Text("Später")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .disabled(isRequesting)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .padding()
    }

    // MARK: - Benefit Row

    private func benefitRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.black)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#if DEBUG
    #Preview {
        HealthKitPermissionView(
            onAuthorize: {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                print("Authorized")
            },
            onSkip: {
                print("Skipped")
            }
        )
    }
#endif
