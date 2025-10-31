//
//  ExerciseGroupBuilder.swift
//  GymBo
//
//  Created on 2025-10-31.
//  V6 - Superset/Circuit Training UI
//

import SwiftUI

/// Reusable component for building exercise groups (Superset or Circuit)
///
/// **Features:**
/// - Displays all exercises in a group
/// - Add/Edit/Delete exercises
/// - Validates group constraints (2 for superset, 3+ for circuit)
/// - Auto-sync rounds across all exercises
///
/// **Usage:**
/// ```swift
/// ExerciseGroupBuilder(
///     groupType: .superset,
///     groupIndex: 0,
///     group: $group,
///     onAddExercise: { /* ... */ },
///     onEditExercise: { exerciseId in /* ... */ },
///     onDeleteExercise: { exerciseId in /* ... */ },
///     onDeleteGroup: { /* ... */ }
/// )
/// ```
struct ExerciseGroupBuilder: View {

    // MARK: - Types

    enum GroupType {
        case superset  // Exactly 2 exercises
        case circuit   // 3+ exercises

        var minExercises: Int {
            switch self {
            case .superset: return 2
            case .circuit: return 3
            }
        }

        var maxExercises: Int {
            switch self {
            case .superset: return 2
            case .circuit: return 99
            }
        }

        var displayName: String {
            switch self {
            case .superset: return "Superset"
            case .circuit: return "Circuit"
            }
        }

        func exerciseLabel(at index: Int) -> String {
            switch self {
            case .superset:
                return index == 0 ? "A1" : "A2"
            case .circuit:
                let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
                return "Station \(letters[min(index, letters.count - 1)])"
            }
        }
    }

    // MARK: - Properties

    let groupType: GroupType
    let groupIndex: Int

    @Binding var group: ExerciseGroup

    let exerciseNames: [UUID: String]  // exerciseId → name
    let onAddExercise: () -> Void
    let onEditExercise: (UUID) -> Void
    let onDeleteExercise: (UUID) -> Void
    let onDeleteGroup: () -> Void

    // MARK: - Computed

    private var isValid: Bool {
        group.exercises.count >= groupType.minExercises
    }

    private var canAddMore: Bool {
        group.exercises.count < groupType.maxExercises
    }

    private var validationMessage: String? {
        if group.exercises.isEmpty {
            return "Mindestens \(groupType.minExercises) Übungen erforderlich"
        }
        if group.exercises.count < groupType.minExercises {
            return "Noch \(groupType.minExercises - group.exercises.count) Übung(en) hinzufügen"
        }
        return nil
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("\(groupType.displayName) \(groupIndex + 1)")
                    .font(.headline)
                    .foregroundColor(.primary)

                if let rounds = group.exercises.first?.targetSets {
                    Text("(\(rounds) Runden)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Delete Group Button
                Button(role: .destructive, action: onDeleteGroup) {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }

            // Exercise List
            VStack(spacing: 8) {
                ForEach(Array(group.exercises.enumerated()), id: \.element.id) { index, exercise in
                    exerciseRow(exercise: exercise, index: index)
                }

                // Add Exercise Button (only for circuits or if empty)
                if canAddMore {
                    addExerciseButton
                }
            }

            // Validation Message
            if let message = validationMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Text(message)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Subviews

    private func exerciseRow(exercise: WorkoutExercise, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Exercise Label (A1/A2 or Station A/B/C)
                Text(groupType.exerciseLabel(at: index))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    // Exercise Name
                    Text(exerciseNames[exercise.exerciseId] ?? "Unbekannte Übung")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    // Details (Sets × Reps × Weight)
                    HStack(spacing: 4) {
                        Text("\(exercise.targetSets) Sätze")
                        Text("×")

                        if let time = exercise.targetTime, time > 0 {
                            Text("\(Int(time))s")
                        } else {
                            Text("\(exercise.targetReps ?? 0) Wdh")
                        }

                        Text("×")

                        if let weight = exercise.targetWeight, weight > 0 {
                            Text("\(String(format: "%.1f", weight))kg")
                        } else {
                            Text("Körpergewicht")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Edit Button
                Button {
                    onEditExercise(exercise.id)
                    HapticFeedback.impact(.light)
                } label: {
                    Text("Ändern")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#F77E2D"))
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color(.systemGroupedBackground))
            .cornerRadius(8)
        }
    }

    private var addExerciseButton: some View {
        Button {
            onAddExercise()
            HapticFeedback.impact(.light)
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.body)

                Text(groupType == .superset ? "Übung hinzufügen" : "Station hinzufügen")
                    .font(.body)
                    .fontWeight(.medium)
            }
            .foregroundColor(Color(hex: "#F77E2D"))
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color(hex: "#F77E2D").opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Superset Group - Empty") {
    ExerciseGroupBuilder(
        groupType: .superset,
        groupIndex: 0,
        group: .constant(ExerciseGroup(
            exercises: [],
            groupIndex: 0,
            restAfterGroup: 120
        )),
        exerciseNames: [:],
        onAddExercise: {},
        onEditExercise: { _ in },
        onDeleteExercise: { _ in },
        onDeleteGroup: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Superset Group - Complete") {
    ExerciseGroupBuilder(
        groupType: .superset,
        groupIndex: 0,
        group: .constant(ExerciseGroup(
            exercises: [
                WorkoutExercise(
                    id: UUID(),
                    exerciseId: UUID(),
                    targetSets: 3,
                    targetReps: 10,
                    targetWeight: 80.0,
                    orderIndex: 0
                ),
                WorkoutExercise(
                    id: UUID(),
                    exerciseId: UUID(),
                    targetSets: 3,
                    targetReps: 8,
                    targetWeight: 0.0,
                    orderIndex: 1
                )
            ],
            groupIndex: 0,
            restAfterGroup: 120
        )),
        exerciseNames: [
            UUID(): "Bankdrücken",
            UUID(): "Klimmzüge"
        ],
        onAddExercise: {},
        onEditExercise: { _ in },
        onDeleteExercise: { _ in },
        onDeleteGroup: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Circuit Group") {
    ExerciseGroupBuilder(
        groupType: .circuit,
        groupIndex: 0,
        group: .constant(ExerciseGroup(
            exercises: [
                WorkoutExercise(
                    id: UUID(),
                    exerciseId: UUID(),
                    targetSets: 3,
                    targetReps: 15,
                    targetWeight: 60.0,
                    orderIndex: 0
                ),
                WorkoutExercise(
                    id: UUID(),
                    exerciseId: UUID(),
                    targetSets: 3,
                    targetReps: 15,
                    targetWeight: 0.0,
                    orderIndex: 1
                ),
                WorkoutExercise(
                    id: UUID(),
                    exerciseId: UUID(),
                    targetSets: 3,
                    targetReps: 12,
                    targetWeight: 50.0,
                    orderIndex: 2
                )
            ],
            groupIndex: 0,
            restAfterGroup: 180
        )),
        exerciseNames: [
            UUID(): "Kniebeugen",
            UUID(): "Push-ups",
            UUID(): "Rows"
        ],
        onAddExercise: {},
        onEditExercise: { _ in },
        onDeleteExercise: { _ in },
        onDeleteGroup: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
#endif
