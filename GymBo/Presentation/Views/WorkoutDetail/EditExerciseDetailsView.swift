//
//  EditExerciseDetailsView.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Presentation Layer
//

import SwiftUI

/// Sheet view for editing exercise details within a workout
///
/// **Features:**
/// - Edit target sets, reps, weight
/// - Edit rest time between sets
/// - Add/edit notes
/// - Validation feedback
/// - Save with success notification
///
/// **Design:**
/// - Form-based layout
/// - Number pickers for easy input
/// - Cancel and Save buttons
/// - Keyboard-friendly
struct EditExerciseDetailsView: View {

    // MARK: - Properties

    let workoutId: UUID
    let exercise: WorkoutExercise
    let exerciseName: String
    let onSave: (Int, Int, Double?, TimeInterval?, String?) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var targetSets: Int
    @State private var targetReps: Int
    @State private var targetWeight: String
    @State private var restTime: Int
    @State private var notes: String
    @State private var useWeight: Bool

    // MARK: - Initialization

    init(
        workoutId: UUID,
        exercise: WorkoutExercise,
        exerciseName: String,
        onSave: @escaping (Int, Int, Double?, TimeInterval?, String?) -> Void
    ) {
        self.workoutId = workoutId
        self.exercise = exercise
        self.exerciseName = exerciseName
        self.onSave = onSave

        // Initialize state
        _targetSets = State(initialValue: exercise.targetSets)
        _targetReps = State(initialValue: exercise.targetReps)
        _targetWeight = State(
            initialValue: exercise.targetWeight.map { String(format: "%.1f", $0) } ?? "")
        _restTime = State(initialValue: Int(exercise.restTime ?? 90))
        _notes = State(initialValue: exercise.notes ?? "")
        _useWeight = State(initialValue: exercise.targetWeight != nil && exercise.targetWeight! > 0)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Exercise Name Section
                Section {
                    HStack {
                        Image(systemName: "dumbbell.fill")
                            .foregroundStyle(.orange)
                        Text(exerciseName)
                            .font(.headline)
                    }
                }

                // Sets & Reps Section
                Section("Sätze & Wiederholungen") {
                    Stepper("Sätze: \(targetSets)", value: $targetSets, in: 1...10)
                    Stepper("Wiederholungen: \(targetReps)", value: $targetReps, in: 1...50)
                }

                // Weight Section
                Section("Gewicht") {
                    Toggle("Gewicht verwenden", isOn: $useWeight)

                    if useWeight {
                        HStack {
                            TextField("Gewicht", text: $targetWeight)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("kg")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Rest Time Section
                Section("Pause zwischen Sätzen") {
                    Picker("Pause", selection: $restTime) {
                        Text("30 Sek").tag(30)
                        Text("45 Sek").tag(45)
                        Text("60 Sek").tag(60)
                        Text("90 Sek").tag(90)
                        Text("120 Sek").tag(120)
                        Text("180 Sek").tag(180)
                    }
                    .pickerStyle(.segmented)
                }

                // Notes Section
                Section("Notizen") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Übung bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var isValid: Bool {
        if useWeight {
            // Check if weight is valid number
            guard Double(targetWeight.replacingOccurrences(of: ",", with: ".")) != nil,
                !targetWeight.isEmpty
            else {
                return false
            }
        }
        return true
    }

    // MARK: - Actions

    private func saveChanges() {
        // Parse weight
        let weight: Double?
        if useWeight, !targetWeight.isEmpty {
            weight = Double(targetWeight.replacingOccurrences(of: ",", with: "."))
        } else {
            weight = nil
        }

        // Prepare notes (nil if empty)
        let finalNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let notesToSave = finalNotes.isEmpty ? nil : finalNotes

        // Call save handler
        onSave(
            targetSets,
            targetReps,
            weight,
            TimeInterval(restTime),
            notesToSave
        )

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    EditExerciseDetailsView(
        workoutId: UUID(),
        exercise: WorkoutExercise(
            exerciseId: UUID(),
            targetSets: 3,
            targetReps: 10,
            targetWeight: 80.0,
            restTime: 90,
            orderIndex: 0,
            notes: "Focus on form"
        ),
        exerciseName: "Bankdrücken",
        onSave: { sets, reps, weight, rest, notes in
            print("Saved: \(sets) sets, \(reps) reps, \(weight ?? 0)kg, \(rest)s rest")
        }
    )
}
