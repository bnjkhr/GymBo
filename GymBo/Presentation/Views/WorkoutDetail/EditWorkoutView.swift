//
//  EditWorkoutView.swift
//  GymBo
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Edit Workout View
//

import SwiftUI

/// View for editing workout template metadata (name & rest time)
///
/// **Features:**
/// - Edit workout name
/// - Edit default rest time
/// - Form validation
/// - iOS HIG compliant design
struct EditWorkoutView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutStore.self) private var workoutStore

    // MARK: - Callback
    let workout: Workout
    let onSave: (String, TimeInterval) -> Void

    @State private var workoutName: String
    @State private var defaultRestTime: Int
    @State private var isLoading = false
    @FocusState private var isNameFieldFocused: Bool

    private let restTimeOptions = [
        (value: 30, label: "30 Sekunden"),
        (value: 60, label: "60 Sekunden"),
        (value: 90, label: "90 Sekunden"),
        (value: 120, label: "2 Minuten"),
        (value: 180, label: "3 Minuten"),
    ]

    // MARK: - Initialization

    init(workout: Workout, onSave: @escaping (String, TimeInterval) -> Void) {
        self.workout = workout
        self.onSave = onSave
        self._workoutName = State(initialValue: workout.name)
        self._defaultRestTime = State(initialValue: Int(workout.defaultRestTime))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                restTimeSection
            }
            .navigationTitle("Workout bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    cancelButton
                }
                ToolbarItem(placement: .confirmationAction) {
                    saveButton
                }
            }
            .disabled(isLoading)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isNameFieldFocused = true
                }
            }
        }
    }

    // MARK: - Subviews

    private var nameSection: some View {
        Section {
            TextField("Workout-Name", text: $workoutName)
                .focused($isNameFieldFocused)
                .autocorrectionDisabled()
        } header: {
            Text("Name")
        }
    }

    private var restTimeSection: some View {
        Section {
            Picker("Pausenzeit", selection: $defaultRestTime) {
                ForEach(restTimeOptions, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Standard-Pausenzeit")
        } footer: {
            Text("Standard-Pausenzeit zwischen Sätzen")
        }
    }

    private var cancelButton: some View {
        Button("Abbrechen") {
            dismiss()
        }
    }

    private var saveButton: some View {
        Button("Speichern") {
            Task {
                await saveWorkout()
            }
        }
        .disabled(workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
    }

    // MARK: - Actions

    @MainActor
    private func saveWorkout() async {
        isLoading = true
        defer { isLoading = false }

        let trimmedName = workoutName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            print("❌ EditWorkoutView: Workout name cannot be empty")
            return
        }

        // Call callback with updated values
        onSave(trimmedName, TimeInterval(defaultRestTime))

        // Dismiss sheet
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    EditWorkoutView(
        workout: Workout(
            name: "Push Day",
            exercises: [],
            defaultRestTime: 90,
            isFavorite: false
        )
    ) { name, restTime in
        print("Updated: \(name), \(restTime)s")
    }
}
