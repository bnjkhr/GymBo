//
//  QuickSetupPreviewView.swift
//  GymBo
//
//  Created on 2025-10-26.
//  Quick-Setup Feature - Preview & Customization
//

import SwiftUI

/// Preview and customization view for Quick-Setup workout
struct QuickSetupPreviewView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutStore.self) private var workoutStore

    let config: QuickSetupConfig
    let generatedExercises: [WorkoutExercise]
    let allExercises: [ExerciseEntity]  // For swap/add
    let onSave: (String, [WorkoutExercise]) -> Void

    @State private var workoutName: String = ""
    @State private var exercises: [WorkoutExercise]
    @State private var showExercisePicker = false
    @State private var exerciseToReplace: WorkoutExercise? = nil

    init(
        config: QuickSetupConfig,
        generatedExercises: [WorkoutExercise],
        allExercises: [ExerciseEntity],
        onSave: @escaping (String, [WorkoutExercise]) -> Void
    ) {
        self.config = config
        self.generatedExercises = generatedExercises
        self.allExercises = allExercises
        self.onSave = onSave

        // Generate default name
        let equipmentText =
            config.availableEquipment.count == 1
            ? config.availableEquipment.first!.displayName
            : "Gemischt"

        let defaultName =
            "Quick \(config.goal.displayName) (\(equipmentText)) - \(config.duration.displayName)"

        _workoutName = State(initialValue: defaultName)
        _exercises = State(initialValue: generatedExercises)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section
                headerSection

                // Exercise List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(exercises.enumerated()), id: \.element.id) {
                            index, exercise in
                            ExercisePreviewCard(
                                exercise: exercise,
                                exerciseName: exerciseName(for: exercise.exerciseId),
                                orderNumber: index + 1,
                                onSwap: {
                                    exerciseToReplace = exercise
                                    showExercisePicker = true
                                },
                                onDelete: {
                                    withAnimation {
                                        exercises.removeAll { $0.id == exercise.id }
                                        reorderExercises()
                                    }
                                }
                            )
                        }

                        // Add Exercise Button
                        addExerciseButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)  // Space for bottom button
                }

                // Save Button
                saveButton
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerSheet(
                    exercises: filteredExercisesForPicker(),
                    currentExerciseMuscleGroups: currentExerciseMuscleGroups(),
                    onSelect: { selectedExercise in
                        handleExerciseSelection(selectedExercise)
                    }
                )
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Workout Name (Editable)
            TextField("Workout-Name", text: $workoutName)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 16)

            // Stats
            HStack(spacing: 24) {
                StatBadge(
                    icon: "list.bullet",
                    value: "\(exercises.count)",
                    label: "Übungen"
                )

                StatBadge(
                    icon: "clock",
                    value: config.duration.displayName,
                    label: "Dauer"
                )

                StatBadge(
                    icon: "target",
                    value: config.goal.displayName,
                    label: "Ziel"
                )
            }
            .padding(.bottom, 16)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Add Exercise Button

    private var addExerciseButton: some View {
        Button {
            exerciseToReplace = nil
            showExercisePicker = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Übung hinzufügen")
                    .font(.headline)
            }
            .foregroundColor(.appOrange)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appOrange.opacity(0.3), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                saveWorkout()
            } label: {
                Text("Workout speichern")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        workoutName.isEmpty || exercises.isEmpty ? Color.secondary : Color.appOrange
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(workoutName.isEmpty || exercises.isEmpty)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Helpers

    private func exerciseName(for exerciseId: UUID) -> String {
        allExercises.first { $0.id == exerciseId }?.name ?? "Unbekannt"
    }

    private func currentExerciseMuscleGroups() -> [String] {
        guard let exerciseToReplace = exerciseToReplace else { return [] }
        return allExercises.first { $0.id == exerciseToReplace.exerciseId }?.muscleGroupsRaw ?? []
    }

    private func filteredExercisesForPicker() -> [ExerciseEntity] {
        // Filter by selected equipment
        allExercises.filter { exercise in
            config.availableEquipment.contains { category in
                exercise.equipmentTypeRaw == category.rawValue
            }
        }
    }

    private func handleExerciseSelection(_ selectedExercise: ExerciseEntity) {
        if let exerciseToReplace = exerciseToReplace {
            // Replace existing exercise
            if let index = exercises.firstIndex(where: { $0.id == exerciseToReplace.id }) {
                let scheme = config.goal.defaultSetRepScheme
                exercises[index] = WorkoutExercise(
                    exerciseId: selectedExercise.id,
                    targetSets: scheme.sets,
                    targetReps: scheme.reps > 0 ? scheme.reps : nil,
                    targetTime: scheme.reps == 0 ? 30 : nil,
                    targetWeight: nil,
                    restTime: scheme.rest,
                    perSetRestTimes: nil,
                    orderIndex: index,
                    notes: nil
                )
            }
        } else {
            // Add new exercise
            let scheme = config.goal.defaultSetRepScheme
            let newExercise = WorkoutExercise(
                exerciseId: selectedExercise.id,
                targetSets: scheme.sets,
                targetReps: scheme.reps > 0 ? scheme.reps : nil,
                targetTime: scheme.reps == 0 ? 30 : nil,
                targetWeight: nil,
                restTime: scheme.rest,
                perSetRestTimes: nil,
                orderIndex: exercises.count,
                notes: nil
            )
            exercises.append(newExercise)
        }
    }

    private func reorderExercises() {
        for (index, _) in exercises.enumerated() {
            exercises[index] = WorkoutExercise(
                id: exercises[index].id,
                exerciseId: exercises[index].exerciseId,
                targetSets: exercises[index].targetSets,
                targetReps: exercises[index].targetReps,
                targetTime: exercises[index].targetTime,
                targetWeight: exercises[index].targetWeight,
                restTime: exercises[index].restTime,
                perSetRestTimes: exercises[index].perSetRestTimes,
                orderIndex: index,
                notes: exercises[index].notes
            )
        }
    }

    private func saveWorkout() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
        onSave(workoutName, exercises)
    }
}

// MARK: - Exercise Preview Card

private struct ExercisePreviewCard: View {
    let exercise: WorkoutExercise
    let exerciseName: String
    let orderNumber: Int
    let onSwap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Order Number
            Text("\(orderNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color(.tertiarySystemGroupedBackground))
                )

            // Exercise Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exerciseName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let reps = exercise.targetReps {
                        Text("\(exercise.targetSets)×\(reps)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if let time = exercise.targetTime {
                        Text("\(exercise.targetSets)×\(Int(time))s")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let restTime = exercise.restTime {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(Int(restTime))s")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Action Buttons
            HStack(spacing: 8) {
                // Swap Button
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onSwap()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.body)
                        .foregroundColor(.appOrange)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                // Delete Button
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.appOrange)

            Text(value)
                .font(.headline)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Exercise Picker Sheet

private struct ExercisePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let exercises: [ExerciseEntity]
    let currentExerciseMuscleGroups: [String]
    let onSelect: (ExerciseEntity) -> Void

    @State private var searchText = ""

    var filteredExercises: [ExerciseEntity] {
        let filtered =
            searchText.isEmpty
            ? exercises
            : exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

        // Sort: Same muscle groups first, then others
        return filtered.sorted { exercise1, exercise2 in
            let hasMatchingMuscles1 = !Set(exercise1.muscleGroupsRaw).isDisjoint(
                with: currentExerciseMuscleGroups)
            let hasMatchingMuscles2 = !Set(exercise2.muscleGroupsRaw).isDisjoint(
                with: currentExerciseMuscleGroups)

            if hasMatchingMuscles1 && !hasMatchingMuscles2 {
                return true  // exercise1 comes first
            } else if !hasMatchingMuscles1 && hasMatchingMuscles2 {
                return false  // exercise2 comes first
            } else {
                // Both have or don't have matching muscles - sort alphabetically
                return exercise1.name < exercise2.name
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredExercises) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Text(exercise.muscleGroupsRaw.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            // Show indicator for matching muscle groups
                            if !Set(exercise.muscleGroupsRaw).isDisjoint(with: currentExerciseMuscleGroups) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.appOrange)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Übung suchen")
            .navigationTitle("Übung wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }
}
