//
//  WorkoutCreationModeSheet.swift
//  GymBo
//
//  Created on 2025-10-26.
//  Quick-Setup Feature - Mode Selection
//

import SwiftUI

/// Sheet to select workout creation mode
struct WorkoutCreationModeSheet: View {

    @Environment(\.dismiss) private var dismiss

    let onSelectEmpty: () -> Void
    let onSelectQuickSetup: () -> Void
    let onSelectWizard: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Empty Workout
                    ModeCard(
                        icon: "square.and.pencil",
                        title: "Leeres Workout",
                        description: "Erstelle ein Workout von Grund auf",
                        badge: nil,
                        isEnabled: true,
                        action: {
                            dismiss()
                            onSelectEmpty()
                        }
                    )

                    // Quick-Setup
                    ModeCard(
                        icon: "bolt.fill",
                        title: "Quick-Setup",
                        description: "Schnelles Workout für unterwegs",
                        badge: nil,
                        isEnabled: true,
                        action: {
                            dismiss()
                            onSelectQuickSetup()
                        }
                    )

                    // Workout Wizard (Coming Soon)
                    ModeCard(
                        icon: "wand.and.stars",
                        title: "Workout Wizard",
                        description: "AI-gesteuerter Workout-Assistent",
                        badge: "Kommt bald",
                        isEnabled: false,
                        action: onSelectWizard
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .navigationTitle("Workout erstellen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Mode Card

private struct ModeCard: View {
    let icon: String
    let title: String
    let description: String
    let badge: String?
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            if isEnabled {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                action()
            }
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isEnabled ? .appOrange : .secondary)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )

                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.appOrange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.appOrange.opacity(0.15))
                                )
                        }
                    }

                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Chevron (only if enabled)
                if isEnabled {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Preview

#Preview {
    WorkoutCreationModeSheet(
        onSelectEmpty: { print("Empty selected") },
        onSelectQuickSetup: { print("Quick-Setup selected") },
        onSelectWizard: { print("Wizard selected") }
    )
}
