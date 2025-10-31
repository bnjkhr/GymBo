//
//  AddExerciseToGroupSheet.swift
//  GymBo
//
//  Created on 2025-10-31.
//  V6 - Superset/Circuit Training UI
//

import SwiftUI

/// Sheet for configuring exercise details when adding to a Superset/Circuit group
///
/// **Features:**
/// - Set rounds (targetSets) - synced across all exercises in group
/// - Set reps or time
/// - Set weight (optional)
/// - Simplified UI compared to EditExerciseDetailsView
///
/// **Usage:**
/// ```swift
/// AddExerciseToGroupSheet(
///     exerciseName: "Bankdrücken",
///     rounds: 3,
///     onSave: { reps, time, weight in
///         // Create WorkoutExercise
///     }
/// )
/// ```
struct AddExerciseToGroupSheet: View {

    // MARK: - Properties

    let exerciseName: String
    let rounds: Int  // From group - all exercises must have same rounds
    let onSave: (Int?, TimeInterval?, Double?) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var useReps = true  // true = reps, false = time
    @State private var targetReps: Int = 10
    @State private var targetTime: Int = 60  // in seconds
    @State private var useWeight = false
    @State private var targetWeight: String = "0"

    @FocusState private var isWeightFieldFocused: Bool

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Exercise Name
                    exerciseNameHeader

                    // Rounds (Display Only - synced with group)
                    roundsSection

                    // Reps or Time
                    repsTimeSection

                    // Weight
                    weightSection
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Übung hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        saveExercise()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fertig") {
                        isWeightFieldFocused = false
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var exerciseNameHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Übung")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(exerciseName)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var roundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Runden")
                    .font(.headline)

                Spacer()

                Text("\(rounds)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#F77E2D"))
            }

            Text("Alle Übungen in dieser Gruppe haben die gleiche Anzahl an Runden")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var repsTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Wiederholungen oder Zeit")
                .font(.headline)

            // Toggle: Reps vs Time
            Picker("Typ", selection: $useReps) {
                Text("Wiederholungen").tag(true)
                Text("Zeit").tag(false)
            }
            .pickerStyle(.segmented)

            if useReps {
                // Reps Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wiederholungen pro Satz")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Wiederholungen", selection: $targetReps) {
                        ForEach([5, 8, 10, 12, 15, 20, 25, 30], id: \.self) { reps in
                            Text("\(reps) Wdh").tag(reps)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
            } else {
                // Time Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Zeit pro Satz (Sekunden)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Zeit", selection: $targetTime) {
                        ForEach([15, 20, 30, 45, 60, 90, 120], id: \.self) { seconds in
                            Text("\(seconds)s").tag(seconds)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: $useWeight) {
                Text("Gewicht verwenden")
                    .font(.headline)
            }

            if useWeight {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gewicht (kg)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField("0.0", text: $targetWeight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .focused($isWeightFieldFocused)
                            .frame(maxWidth: 120)

                        Text("kg")
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                }
            } else {
                Text("Körpergewichtsübung")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Computed

    private var isValid: Bool {
        if useWeight {
            guard let weight = Double(targetWeight), weight >= 0 else {
                return false
            }
        }
        return true
    }

    // MARK: - Actions

    private func saveExercise() {
        let reps = useReps ? targetReps : nil
        let time = useReps ? nil : TimeInterval(targetTime)
        let weight = useWeight ? Double(targetWeight) : nil

        onSave(reps, time, weight)

        HapticFeedback.notification(.success)
        dismiss()
    }
}

// MARK: - Preview

#if DEBUG
    #Preview {
        AddExerciseToGroupSheet(
            exerciseName: "Bankdrücken",
            rounds: 3
        ) { reps, time, weight in
            print("Saved: \(reps ?? 0) reps, \(time ?? 0)s, \(weight ?? 0)kg")
        }
    }
#endif
