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
    let onSave: (Int, Int?, TimeInterval?, Double?, TimeInterval?, String?) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var targetSets: Int
    @State private var targetReps: Int
    @State private var targetTime: Int  // in seconds
    @State private var targetWeight: String
    @State private var restTime: Int
    @State private var notes: String
    @State private var useWeight: Bool
    @State private var useReps: Bool
    @State private var useTime: Bool
    @FocusState private var isWeightFieldFocused: Bool
    @FocusState private var isNotesFieldFocused: Bool

    // MARK: - Initialization

    init(
        workoutId: UUID,
        exercise: WorkoutExercise,
        exerciseName: String,
        onSave: @escaping (Int, Int?, TimeInterval?, Double?, TimeInterval?, String?) -> Void
    ) {
        self.workoutId = workoutId
        self.exercise = exercise
        self.exerciseName = exerciseName
        self.onSave = onSave

        // Initialize state
        _targetSets = State(initialValue: exercise.targetSets)
        _targetReps = State(initialValue: exercise.targetReps ?? 8)
        _targetTime = State(initialValue: Int(exercise.targetTime ?? 60))
        _targetWeight = State(
            initialValue: exercise.targetWeight.map { String(format: "%.1f", $0) } ?? "0")
        _restTime = State(initialValue: Int(exercise.restTime ?? 90))
        _notes = State(initialValue: exercise.notes ?? "")
        _useWeight = State(initialValue: exercise.targetWeight != nil && exercise.targetWeight! > 0)
        _useReps = State(initialValue: exercise.targetReps != nil)
        _useTime = State(initialValue: exercise.targetTime != nil)
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

                // Sets Section
                Section("Sätze") {
                    Stepper("Sätze: \(targetSets)", value: $targetSets, in: 1...10)
                }

                // Reps or Time Section
                Section("Wiederholungen oder Zeit") {
                    Toggle("Wiederholungen verwenden", isOn: $useReps)
                        .onChange(of: useReps) { _, newValue in
                            if newValue {
                                useTime = false
                            }
                        }

                    if useReps {
                        Stepper("Wiederholungen: \(targetReps)", value: $targetReps, in: 1...50)
                    }

                    Toggle("Zeit verwenden", isOn: $useTime)
                        .onChange(of: useTime) { _, newValue in
                            if newValue {
                                useReps = false
                            }
                        }

                    if useTime {
                        Picker("Zeit", selection: $targetTime) {
                            Text("15 Sek").tag(15)
                            Text("30 Sek").tag(30)
                            Text("45 Sek").tag(45)
                            Text("60 Sek").tag(60)
                            Text("90 Sek").tag(90)
                            Text("120 Sek").tag(120)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // Weight Section
                Section("Gewicht") {
                    Toggle("Gewicht verwenden", isOn: $useWeight)

                    if useWeight {
                        HStack {
                            Text("Gewicht")
                            Spacer()
                            TextField("0", text: $targetWeight)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 100)
                                .focused($isWeightFieldFocused)
                            Text("kg")
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
                        .focused($isNotesFieldFocused)
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

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fertig") {
                        isWeightFieldFocused = false
                        isNotesFieldFocused = false
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var isValid: Bool {
        // Must have either reps or time
        guard useReps || useTime else {
            return false
        }

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
            useReps ? targetReps : nil,
            useTime ? TimeInterval(targetTime) : nil,
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
        onSave: { sets, reps, time, weight, rest, notes in
            print(
                "Saved: \(sets) sets, \(reps.map { "\($0) reps" } ?? ""), \(time.map { "\($0)s" } ?? ""), \(weight ?? 0)kg, \(rest)s rest"
            )
        }
    )
}
