//
//  CreateWorkoutView.swift
//  GymBo
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Presentation Layer
//

import SwiftUI

/// View for creating a new workout template
///
/// **Features:**
/// - Text field for workout name
/// - Picker for default rest time
/// - Validation feedback
/// - Loading state during creation
///
/// **iOS HIG Compliance:**
/// - Standard form layout
/// - Proper toolbar placement
/// - Accessibility labels
/// - Disabled state when invalid
struct CreateWorkoutView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutStore.self) private var workoutStore

    // MARK: - Callback

    let onWorkoutCreated: (Workout) -> Void

    // MARK: - State

    @State private var workoutName = ""
    @State private var defaultRestTime: Int = 90  // Default: 90 seconds
    @State private var isLoading = false
    @FocusState private var isNameFieldFocused: Bool

    // MARK: - Constants

    private let restTimeOptions = [
        (value: 30, label: "30 Sekunden"),
        (value: 60, label: "60 Sekunden"),
        (value: 90, label: "90 Sekunden"),
        (value: 120, label: "2 Minuten"),
        (value: 180, label: "3 Minuten"),
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    nameSection
                    restTimeSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Neues Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    cancelButton
                }

                ToolbarItem(placement: .confirmationAction) {
                    createButton
                }
            }
            .disabled(isLoading)
            .onAppear {
                // Auto-focus name field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isNameFieldFocused = true
                }
            }
        }
    }

    // MARK: - Sections (Modern iOS 26 Design)

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            TextField("z.B. Push Day", text: $workoutName)
                .focused($isNameFieldFocused)
                .autocorrectionDisabled()
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .accessibilityLabel("Workout Name")
        }
    }

    private var restTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Standard-Pausenzeit")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 8) {
                ForEach(restTimeOptions, id: \.value) { option in
                    Button {
                        defaultRestTime = option.value
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack {
                            Text(option.label)
                                .font(.body)
                                .foregroundColor(.primary)

                            Spacer()

                            if defaultRestTime == option.value {
                                Image(systemName: "checkmark")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                }
            }

            Text("Diese Pausenzeit wird als Standard für alle Übungen verwendet")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
    }

    // MARK: - Toolbar Buttons

    private var cancelButton: some View {
        Button("Abbrechen") {
            dismiss()
        }
        .disabled(isLoading)
        .accessibilityLabel("Erstellen abbrechen")
    }

    private var createButton: some View {
        Button("Erstellen") {
            Task {
                await createWorkout()
            }
        }
        .fontWeight(.semibold)
        .disabled(workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        .accessibilityLabel("Workout erstellen")
        .accessibilityHint(workoutName.isEmpty ? "Gib zuerst einen Namen ein" : "")
    }

    // MARK: - Actions

    @MainActor
    private func createWorkout() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let workout = try await workoutStore.createWorkout(
                name: workoutName,
                defaultRestTime: TimeInterval(defaultRestTime)
            )

            // Success - call callback with created workout
            dismiss()
            workoutStore.showSuccess("Workout '\(workout.name)' erstellt")
            onWorkoutCreated(workout)

        } catch {
            // Error is handled by WorkoutStore
            print("❌ CreateWorkoutView: Failed to create workout - \(error)")
        }
    }
}

// MARK: - Preview

#Preview("Create Workout") {
    CreateWorkoutView(onWorkoutCreated: { _ in })
        .environment(WorkoutStore.preview)
}

#Preview("Create Workout - Dark") {
    CreateWorkoutView(onWorkoutCreated: { _ in })
        .environment(WorkoutStore.preview)
        .preferredColorScheme(.dark)
}
