//
//  SupersetGroupCard.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V6 - Superset Training Feature
//

import SwiftUI

/// Compact card displaying a superset group (2 exercises) during active workout
///
/// **Features:**
/// - Shows both exercises in the superset pair
/// - Visual separation between exercises
/// - Round indicator (e.g., "Runde 2/3")
/// - Rest time indicator after group
/// - Color coding for exercise A and B
///
/// **Design:**
/// - White card with rounded corners
/// - Exercise A: Blue accent
/// - Exercise B: Orange accent
/// - Clear visual hierarchy
struct SupersetGroupCard: View {

    // MARK: - Properties

    let group: SessionExerciseGroup
    let groupIndex: Int
    let exerciseNames: [UUID: String]  // exerciseId -> name mapping

    /// Callbacks
    let onToggleCompletion: ((UUID, UUID) -> Void)?  // (exerciseId, setId)
    let onUpdateWeight: ((UUID, UUID, Double) -> Void)?  // (exerciseId, setId, weight)
    let onUpdateReps: ((UUID, UUID, Int) -> Void)?  // (exerciseId, setId, reps)

    // MARK: - Constants

    private enum Layout {
        static let cornerRadius: CGFloat = 24
        static let cardPadding: CGFloat = 20
        static let exerciseSpacing: CGFloat = 16
        static let shadowRadius: CGFloat = 6
    }

    private enum Colors {
        static let exerciseA = Color.blue
        static let exerciseB = Color.orange
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Group header
            groupHeader
                .padding(.horizontal, Layout.cardPadding)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, Layout.cardPadding)

            // Exercise A (Blue)
            if let exerciseA = group.exercises.first {
                exerciseSection(
                    exercise: exerciseA,
                    exerciseNumber: "A",
                    accentColor: Colors.exerciseA,
                    currentRound: group.currentRound
                )
                .padding(.horizontal, Layout.cardPadding)
                .padding(.vertical, 16)
            }

            // Rest indicator between exercises
            restIndicator(duration: group.exercises.first?.restTimeToNext ?? 60)
                .padding(.horizontal, Layout.cardPadding)

            // Exercise B (Orange)
            if group.exercises.count >= 2 {
                exerciseSection(
                    exercise: group.exercises[1],
                    exerciseNumber: "B",
                    accentColor: Colors.exerciseB,
                    currentRound: group.currentRound
                )
                .padding(.horizontal, Layout.cardPadding)
                .padding(.vertical, 16)
            }

            Divider()
                .padding(.horizontal, Layout.cardPadding)

            // Group rest footer
            groupRestFooter
                .padding(.horizontal, Layout.cardPadding)
                .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(Layout.cornerRadius)
        .shadow(color: .black.opacity(0.08), radius: Layout.shadowRadius, y: 2)
    }

    // MARK: - Subviews

    /// Group header with round indicator
    private var groupHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SUPERSET \(groupIndex + 1)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Text("Runde \(group.currentRound)/\(group.totalRounds)")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Spacer()

            // Progress indicator
            progressCircle
        }
    }

    /// Progress circle showing round completion
    private var progressCircle: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 4)
                .frame(width: 48, height: 48)

            Circle()
                .trim(from: 0, to: Double(group.currentRound - 1) / Double(group.totalRounds))
                .stroke(Color.accentColor, lineWidth: 4)
                .frame(width: 48, height: 48)
                .rotationEffect(.degrees(-90))

            Text("\(group.currentRound - 1)/\(group.totalRounds)")
                .font(.caption2)
                .fontWeight(.semibold)
        }
    }

    /// Exercise section with sets
    private func exerciseSection(
        exercise: DomainSessionExercise,
        exerciseNumber: String,
        accentColor: Color,
        currentRound: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise header
            HStack(spacing: 8) {
                // Exercise number badge
                Circle()
                    .fill(accentColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(exerciseNumber)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )

                Text(exerciseNames[exercise.exerciseId] ?? "Übung")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()
            }

            // Current round set
            if currentRound - 1 < exercise.sets.count {
                let set = exercise.sets[currentRound - 1]
                SupersetSetRow(
                    set: set,
                    roundNumber: currentRound,
                    accentColor: accentColor,
                    onToggle: {
                        onToggleCompletion?(exercise.id, set.id)
                    },
                    onUpdateWeight: { newWeight in
                        onUpdateWeight?(exercise.id, set.id, newWeight)
                    },
                    onUpdateReps: { newReps in
                        onUpdateReps?(exercise.id, set.id, newReps)
                    }
                )
            }
        }
    }

    /// Rest indicator between exercises
    private func restIndicator(duration: TimeInterval) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(Int(duration))s Pause")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Image(systemName: "arrow.down")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    /// Group rest footer
    private var groupRestFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "pause.circle.fill")
                .foregroundColor(.accentColor)

            Text("\(Int(group.restAfterGroup))s Pause nach Superset")
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()
        }
    }
}

// MARK: - Superset Set Row

/// Compact set row for superset display
struct SupersetSetRow: View {

    let set: DomainSessionSet
    let roundNumber: Int
    let accentColor: Color
    let onToggle: () -> Void
    let onUpdateWeight: (Double) -> Void
    let onUpdateReps: (Int) -> Void

    @State private var isEditingWeight = false
    @State private var isEditingReps = false

    var body: some View {
        HStack(spacing: 16) {
            // Round number
            Text("R\(roundNumber)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)

            // Weight
            Button {
                isEditingWeight = true
            } label: {
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", set.weight))
                        .font(.system(size: 20, weight: .bold))
                    Text("kg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)

            Text("×")
                .font(.headline)
                .foregroundColor(.secondary)

            // Reps
            Button {
                isEditingReps = true
            } label: {
                Text("\(set.reps)")
                    .font(.system(size: 20, weight: .bold))
            }
            .foregroundColor(.primary)

            Spacer()

            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            set.completed ? accentColor : Color(.systemGray4),
                            lineWidth: 2
                        )
                        .frame(width: 32, height: 32)

                    if set.completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(accentColor)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Preview

#if DEBUG
    #Preview("Superset Group Card") {
        let sampleGroup = SessionExerciseGroup(
            exercises: [
                DomainSessionExercise(
                    exerciseId: UUID(),
                    exerciseName: "Biceps Curls",
                    sets: [
                        DomainSessionSet(weight: 10, reps: 12, completed: true, orderIndex: 0),
                        DomainSessionSet(weight: 10, reps: 12, completed: true, orderIndex: 1),
                        DomainSessionSet(weight: 10, reps: 12, completed: false, orderIndex: 2),
                    ],
                    orderIndex: 0
                ),
                DomainSessionExercise(
                    exerciseId: UUID(),
                    exerciseName: "Triceps Extension",
                    sets: [
                        DomainSessionSet(weight: 15, reps: 12, completed: true, orderIndex: 0),
                        DomainSessionSet(weight: 15, reps: 12, completed: true, orderIndex: 1),
                        DomainSessionSet(weight: 15, reps: 12, completed: false, orderIndex: 2),
                    ],
                    orderIndex: 1
                ),
            ],
            groupIndex: 0,
            currentRound: 3,
            totalRounds: 3,
            restAfterGroup: 120
        )

        let exerciseNames = [
            sampleGroup.exercises[0].exerciseId: "Biceps Curls",
            sampleGroup.exercises[1].exerciseId: "Triceps Extension",
        ]

        return SupersetGroupCard(
            group: sampleGroup,
            groupIndex: 0,
            exerciseNames: exerciseNames,
            onToggleCompletion: nil,
            onUpdateWeight: nil,
            onUpdateReps: nil
        )
        .padding()
        .background(Color(.systemGroupedBackground))
    }
#endif
