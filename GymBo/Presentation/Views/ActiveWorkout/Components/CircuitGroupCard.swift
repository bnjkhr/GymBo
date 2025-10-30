//
//  CircuitGroupCard.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V6 - Circuit Training Feature
//

import SwiftUI

/// Compact card displaying a circuit training group during active workout
///
/// **Features:**
/// - Overview of all stations with completion indicators
/// - Large focus view for current station
/// - Round indicator (e.g., "Runde 2/4")
/// - Auto-scroll to current station
/// - Rest time indicator after full circuit
///
/// **Design:**
/// - White card with rounded corners
/// - Station overview at top
/// - Large current station card
/// - Clear visual hierarchy
/// - Progress indicators for each station
struct CircuitGroupCard: View {

    // MARK: - Properties

    let group: SessionExerciseGroup
    let groupIndex: Int
    let exerciseNames: [UUID: String]  // exerciseId -> name mapping

    /// Callbacks
    let onToggleCompletion: ((UUID, UUID) -> Void)?  // (exerciseId, setId)
    let onUpdateWeight: ((UUID, UUID, Double) -> Void)?  // (exerciseId, setId, weight)
    let onUpdateReps: ((UUID, UUID, Int) -> Void)?  // (exerciseId, setId, reps)
    let onAdvanceRound: (() -> Void)?  // Manual round advancement

    // MARK: - State

    @State private var currentStationIndex: Int = 0

    // MARK: - Constants

    private enum Layout {
        static let cornerRadius: CGFloat = 24
        static let cardPadding: CGFloat = 20
        static let stationSpacing: CGFloat = 8
        static let shadowRadius: CGFloat = 6
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Circuit header
            circuitHeader
                .padding(.horizontal, Layout.cardPadding)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, Layout.cardPadding)

            // Station overview
            stationOverview
                .padding(.horizontal, Layout.cardPadding)
                .padding(.vertical, 16)

            Divider()
                .padding(.horizontal, Layout.cardPadding)

            // Current station focus
            currentStationFocus
                .padding(.horizontal, Layout.cardPadding)
                .padding(.vertical, 20)

            Divider()
                .padding(.horizontal, Layout.cardPadding)

            // Circuit rest footer
            circuitRestFooter
                .padding(.horizontal, Layout.cardPadding)
                .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(Layout.cornerRadius)
        .shadow(color: .black.opacity(0.08), radius: Layout.shadowRadius, y: 2)
        .onAppear {
            // Find current station (first incomplete)
            updateCurrentStation()
        }
    }

    // MARK: - Subviews

    /// Circuit header with round indicator
    private var circuitHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("CIRCUIT \(groupIndex + 1)")
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

    /// Station overview showing all stations
    private var stationOverview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STATIONEN")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                ForEach(Array(group.exercises.enumerated()), id: \.element.id) {
                    index, exercise in
                    stationBadge(
                        station: index + 1,
                        exercise: exercise,
                        isCurrent: index == currentStationIndex
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            currentStationIndex = index
                        }
                    }
                }
            }
        }
    }

    /// Individual station badge
    private func stationBadge(
        station: Int, exercise: DomainSessionExercise, isCurrent: Bool
    ) -> some View {
        let setIndex = group.currentRound - 1
        let isCompleted = setIndex < exercise.sets.count && exercise.sets[setIndex].completed

        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isCurrent ? Color.accentColor : isCompleted ? Color.green : Color(.systemGray5))
                    .frame(width: 44, height: 44)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(station)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isCurrent ? .white : .secondary)
                }
            }

            Text(exerciseNames[exercise.exerciseId]?.prefix(8) ?? "Station")
                .font(.caption2)
                .foregroundColor(isCurrent ? .primary : .secondary)
                .lineLimit(1)
        }
    }

    /// Current station focus view
    private var currentStationFocus: some View {
        let exercise = group.exercises[currentStationIndex]
        let setIndex = group.currentRound - 1

        return VStack(alignment: .leading, spacing: 16) {
            // Station header
            HStack {
                Text("AKTUELLE STATION")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

                Spacer()

                // Station number
                HStack(spacing: 4) {
                    Image(systemName: "figure.run")
                        .font(.caption)
                    Text("Station \(currentStationIndex + 1)/\(group.exercises.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.accentColor)
            }

            // Exercise name
            Text(exerciseNames[exercise.exerciseId] ?? "Übung")
                .font(.title2)
                .fontWeight(.bold)

            // Current set
            if setIndex < exercise.sets.count {
                let set = exercise.sets[setIndex]
                CircuitSetCard(
                    set: set,
                    roundNumber: group.currentRound,
                    onToggle: {
                        onToggleCompletion?(exercise.id, set.id)
                        // Auto-advance to next station
                        advanceToNextStation()
                    },
                    onUpdateWeight: { newWeight in
                        onUpdateWeight?(exercise.id, set.id, newWeight)
                    },
                    onUpdateReps: { newReps in
                        onUpdateReps?(exercise.id, set.id, newReps)
                    }
                )
            }

            // Next station preview
            nextStationPreview
        }
    }

    /// Next station preview
    private var nextStationPreview: some View {
        let nextIndex = (currentStationIndex + 1) % group.exercises.count
        let nextExercise = group.exercises[nextIndex]

        return HStack(spacing: 8) {
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(.secondary)

            if nextIndex == 0 && group.currentRound < group.totalRounds {
                Text("Nächste: Runde \(group.currentRound + 1)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Nächste: \(exerciseNames[nextExercise.exerciseId] ?? "Station")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    /// Circuit rest footer
    private var circuitRestFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "pause.circle.fill")
                .foregroundColor(.accentColor)

            Text("\(Int(group.restAfterGroup))s Pause nach Circuit")
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            // Manual advance button
            if group.currentRound < group.totalRounds {
                Button {
                    onAdvanceRound?()
                } label: {
                    HStack(spacing: 4) {
                        Text("Nächste Runde")
                            .font(.caption)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Helpers

    /// Update current station based on completion
    private func updateCurrentStation() {
        let setIndex = group.currentRound - 1
        for (index, exercise) in group.exercises.enumerated() {
            if setIndex < exercise.sets.count && !exercise.sets[setIndex].completed {
                currentStationIndex = index
                return
            }
        }
    }

    /// Advance to next station
    private func advanceToNextStation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentStationIndex = (currentStationIndex + 1) % group.exercises.count
        }
    }
}

// MARK: - Circuit Set Card

/// Large set card for circuit focus view
struct CircuitSetCard: View {

    let set: DomainSessionSet
    let roundNumber: Int
    let onToggle: () -> Void
    let onUpdateWeight: (Double) -> Void
    let onUpdateReps: (Int) -> Void

    @State private var isEditingWeight = false
    @State private var isEditingReps = false

    var body: some View {
        VStack(spacing: 16) {
            // Round indicator
            HStack {
                Text("Runde \(roundNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()
            }

            // Weight and reps
            HStack(spacing: 20) {
                // Weight
                VStack(alignment: .leading, spacing: 4) {
                    Text("GEWICHT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    Button {
                        isEditingWeight = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(String(format: "%.1f", set.weight))
                                .font(.system(size: 32, weight: .bold))
                            Text("kg")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                Spacer()

                // Reps
                VStack(alignment: .leading, spacing: 4) {
                    Text("WIEDERHOLUNGEN")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    Button {
                        isEditingReps = true
                    } label: {
                        Text("\(set.reps)")
                            .font(.system(size: 32, weight: .bold))
                    }
                    .foregroundColor(.primary)
                }
            }

            // Complete button
            Button(action: onToggle) {
                HStack {
                    Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)

                    Text(set.completed ? "Abgeschlossen" : "Satz abschließen")
                        .font(.headline)

                    Spacer()
                }
                .padding()
                .background(set.completed ? Color.green : Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Preview

#if DEBUG
    #Preview("Circuit Group Card") {
        let sampleGroup = SessionExerciseGroup(
            exercises: [
                DomainSessionExercise(
                    exerciseId: UUID(),
                    exerciseName: "Squats",
                    sets: [
                        DomainSessionSet(weight: 60, reps: 15, completed: true, orderIndex: 0),
                        DomainSessionSet(weight: 60, reps: 15, completed: false, orderIndex: 1),
                        DomainSessionSet(weight: 60, reps: 15, completed: false, orderIndex: 2),
                    ],
                    orderIndex: 0
                ),
                DomainSessionExercise(
                    exerciseId: UUID(),
                    exerciseName: "Push-ups",
                    sets: [
                        DomainSessionSet(weight: 0, reps: 20, completed: true, orderIndex: 0),
                        DomainSessionSet(weight: 0, reps: 20, completed: false, orderIndex: 1),
                        DomainSessionSet(weight: 0, reps: 20, completed: false, orderIndex: 2),
                    ],
                    orderIndex: 1
                ),
                DomainSessionExercise(
                    exerciseId: UUID(),
                    exerciseName: "Rows",
                    sets: [
                        DomainSessionSet(weight: 40, reps: 12, completed: true, orderIndex: 0),
                        DomainSessionSet(weight: 40, reps: 12, completed: false, orderIndex: 1),
                        DomainSessionSet(weight: 40, reps: 12, completed: false, orderIndex: 2),
                    ],
                    orderIndex: 2
                ),
                DomainSessionExercise(
                    exerciseId: UUID(),
                    exerciseName: "Lunges",
                    sets: [
                        DomainSessionSet(weight: 0, reps: 16, completed: true, orderIndex: 0),
                        DomainSessionSet(weight: 0, reps: 16, completed: false, orderIndex: 1),
                        DomainSessionSet(weight: 0, reps: 16, completed: false, orderIndex: 2),
                    ],
                    orderIndex: 3
                ),
                DomainSessionExercise(
                    exerciseId: UUID(),
                    exerciseName: "Plank",
                    sets: [
                        DomainSessionSet(weight: 0, reps: 60, completed: true, orderIndex: 0),
                        DomainSessionSet(weight: 0, reps: 60, completed: false, orderIndex: 1),
                        DomainSessionSet(weight: 0, reps: 60, completed: false, orderIndex: 2),
                    ],
                    orderIndex: 4
                ),
            ],
            groupIndex: 0,
            currentRound: 2,
            totalRounds: 3,
            restAfterGroup: 180
        )

        let exerciseNames = Dictionary(
            uniqueKeysWithValues: sampleGroup.exercises.map {
                ($0.exerciseId, $0.exerciseName)
            })

        return CircuitGroupCard(
            group: sampleGroup,
            groupIndex: 0,
            exerciseNames: exerciseNames,
            onToggleCompletion: nil,
            onUpdateWeight: nil,
            onUpdateReps: nil,
            onAdvanceRound: nil
        )
        .padding()
        .background(Color(.systemGroupedBackground))
    }
#endif
