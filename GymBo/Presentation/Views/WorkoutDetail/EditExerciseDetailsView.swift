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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Exercise Name Header
                    exerciseNameHeader

                    // Sets Section
                    setsSection

                    // Reps or Time Section
                    repsTimeSection

                    // Weight Section
                    weightSection

                    // Rest Time Section
                    restTimeSection

                    // Notes Section
                    notesSection
                }
                .padding()
                .padding(.bottom, 100)  // Extra padding for keyboard
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
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

    // MARK: - Subviews (Modern iOS 26 Design)

    private var exerciseNameHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.title2)
                .foregroundStyle(.primary)

            Text(exerciseName)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var setsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Sätze")

            VStack(spacing: 0) {
                HStack {
                    Text("Anzahl")
                        .font(.body)

                    Spacer()

                    Button {
                        if targetSets > 1 {
                            targetSets -= 1
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(targetSets > 1 ? .primary : .secondary)
                    }
                    .disabled(targetSets <= 1)

                    Text("\(targetSets)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .frame(minWidth: 40)

                    Button {
                        if targetSets < 10 {
                            targetSets += 1
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(targetSets < 10 ? .primary : .secondary)
                    }
                    .disabled(targetSets >= 10)
                }
                .padding()
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private var repsTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Wiederholungen oder Zeit")

            VStack(spacing: 8) {
                // Reps Toggle
                toggleCard(
                    title: "Wiederholungen",
                    isOn: $useReps,
                    onChange: { newValue in
                        if newValue { useTime = false }
                    }
                )

                // Reps Stepper
                if useReps {
                    HStack {
                        Text("Wiederholungen")
                            .font(.body)

                        Spacer()

                        Button {
                            if targetReps > 1 {
                                targetReps -= 1
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(targetReps > 1 ? .primary : .secondary)
                        }
                        .disabled(targetReps <= 1)

                        Text("\(targetReps)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .frame(minWidth: 40)

                        Button {
                            if targetReps < 50 {
                                targetReps += 1
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(targetReps < 50 ? .primary : .secondary)
                        }
                        .disabled(targetReps >= 50)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }

                // Time Toggle
                toggleCard(
                    title: "Zeit verwenden",
                    isOn: $useTime,
                    onChange: { newValue in
                        if newValue { useReps = false }
                    }
                )

                // Time Picker
                if useTime {
                    VStack(spacing: 8) {
                        ForEach([15, 30, 45, 60, 90, 120], id: \.self) { seconds in
                            timeOptionButton(seconds: seconds)
                        }
                    }
                }
            }
        }
    }

    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Gewicht")

            VStack(spacing: 8) {
                toggleCard(
                    title: "Gewicht verwenden",
                    isOn: $useWeight,
                    onChange: { _ in }
                )

                if useWeight {
                    HStack {
                        Text("Gewicht")
                            .font(.body)

                        Spacer()

                        TextField("0", text: $targetWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .frame(maxWidth: 100)
                            .focused($isWeightFieldFocused)

                        Text("kg")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
        }
    }

    private var restTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Pause zwischen Sätzen")

            VStack(spacing: 8) {
                ForEach([30, 45, 60, 90, 120, 180], id: \.self) { seconds in
                    restTimeOptionButton(seconds: seconds)
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Notizen")

            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .focused($isNotesFieldFocused)
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }

    private func toggleCard(title: String, isOn: Binding<Bool>, onChange: @escaping (Bool) -> Void)
        -> some View
    {
        Button {
            isOn.wrappedValue.toggle()
            onChange(isOn.wrappedValue)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                if isOn.wrappedValue {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(
                isOn.wrappedValue
                    ? Color.primary.opacity(0.1) : Color(.secondarySystemGroupedBackground)
            )
            .cornerRadius(12)
        }
    }

    private func timeOptionButton(seconds: Int) -> some View {
        Button {
            targetTime = seconds
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack {
                Text("\(seconds) Sekunden")
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                if targetTime == seconds {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(
                targetTime == seconds
                    ? Color.primary.opacity(0.1) : Color(.secondarySystemGroupedBackground)
            )
            .cornerRadius(12)
        }
    }

    private func restTimeOptionButton(seconds: Int) -> some View {
        Button {
            restTime = seconds
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack {
                Text("\(seconds) Sekunden")
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                if restTime == seconds {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(
                restTime == seconds
                    ? Color.primary.opacity(0.1) : Color(.secondarySystemGroupedBackground)
            )
            .cornerRadius(12)
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
