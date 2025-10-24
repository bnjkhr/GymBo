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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    nameSection
                    restTimeSection
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
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

    // MARK: - Subviews (Modern iOS 26 Design)

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

            Text("Standard-Pausenzeit zwischen Sätzen")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
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
