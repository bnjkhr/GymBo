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
            Form {
                nameSection
                restTimeSection
            }
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

    // MARK: - Sections

    private var nameSection: some View {
        Section {
            TextField("Workout Name", text: $workoutName)
                .focused($isNameFieldFocused)
                .autocorrectionDisabled()
                .accessibilityLabel("Workout Name")
        } header: {
            Text("Details")
        } footer: {
            Text("Gib deinem Workout einen aussagekräftigen Namen")
                .font(.caption)
        }
    }

    private var restTimeSection: some View {
        Section {
            Picker("Standard-Pause", selection: $defaultRestTime) {
                ForEach(restTimeOptions, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .accessibilityLabel("Standard-Pausenzeit zwischen Sätzen")
        } header: {
            Text("Pausenzeit")
        } footer: {
            Text("Diese Pausenzeit wird als Standard für alle Übungen verwendet")
                .font(.caption)
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

            // Success - dismiss and show success message
            dismiss()
            workoutStore.showSuccess("Workout '\(workout.name)' erstellt")

        } catch {
            // Error is handled by WorkoutStore
            print("❌ CreateWorkoutView: Failed to create workout - \(error)")
        }
    }
}

// MARK: - Preview

#Preview("Create Workout") {
    CreateWorkoutView()
        .environment(WorkoutStore.preview)
}

#Preview("Create Workout - Dark") {
    CreateWorkoutView()
        .environment(WorkoutStore.preview)
        .preferredColorScheme(.dark)
}
