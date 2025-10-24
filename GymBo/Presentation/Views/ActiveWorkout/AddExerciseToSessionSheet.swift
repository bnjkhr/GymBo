//
//  AddExerciseToSessionSheet.swift
//  GymBo
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Presentation Layer
//

import SwiftUI

/// Sheet for adding exercises to an active workout session
///
/// **Features:**
/// - Single-select exercise picker
/// - Toggle: "Dauerhaft in Workout speichern"
/// - Search & filter exercises
/// - Add exercise to session (with optional template update)
///
/// **Design:**
/// - Similar to ExercisePickerView but single-select
/// - Toggle at bottom (like ReorderExercisesSheet)
/// - Modern iOS 26 card design
struct AddExerciseToSessionSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencyContainer) private var dependencyContainer

    // MARK: - Callback

    let onAddExercise: (ExerciseEntity, Bool) -> Void

    // MARK: - State

    @State private var exercises: [ExerciseEntity] = []
    @State private var searchText = ""
    @State private var selectedMuscleGroup: String?
    @State private var selectedEquipment: String?
    @State private var savePermanently = false
    @State private var isLoading = true

    // Cached filtered exercises (performance optimization)
    @State private var cachedFilteredExercises: [ExerciseEntity] = []

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Exercise List
                if isLoading {
                    ProgressView("Lade Übungen...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(cachedFilteredExercises) { exercise in
                            ExerciseRowButton(exercise: exercise) {
                                selectExercise(exercise)
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Übungen durchsuchen")
                    .onChange(of: searchText) { _, _ in
                        updateFilteredExercises()
                    }
                    .onChange(of: selectedMuscleGroup) { _, _ in
                        updateFilteredExercises()
                    }
                    .onChange(of: selectedEquipment) { _, _ in
                        updateFilteredExercises()
                    }
                }

                // Bottom Toggle Section
                permanentSaveToggle
            }
            .navigationTitle("Übung hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadExercises()
            }
        }
    }

    // MARK: - Subviews

    private var permanentSaveToggle: some View {
        VStack(spacing: 12) {
            Divider()

            Toggle(isOn: $savePermanently) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dauerhaft in Workout speichern")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Übung wird dem Workout-Template hinzugefügt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.orange)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Actions

    private func selectExercise(_ exercise: ExerciseEntity) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onAddExercise(exercise, savePermanently)
        dismiss()
    }

    @MainActor
    private func loadExercises() async {
        guard let container = dependencyContainer else {
            isLoading = false
            return
        }

        let repository = container.makeExerciseRepository()

        do {
            exercises = try await repository.fetchAll()
            updateFilteredExercises()
            isLoading = false
        } catch {
            print("❌ Failed to load exercises: \(error)")
            isLoading = false
        }
    }

    private func updateFilteredExercises() {
        var filtered = exercises

        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Muscle group filter
        if let muscleGroup = selectedMuscleGroup {
            filtered = filtered.filter { $0.muscleGroupsRaw.contains(muscleGroup) }
        }

        // Equipment filter
        if let equipment = selectedEquipment {
            filtered = filtered.filter { $0.equipmentTypeRaw == equipment }
        }

        cachedFilteredExercises = filtered.sorted { $0.name < $1.name }
    }
}

// MARK: - Exercise Row Button

private struct ExerciseRowButton: View {
    let exercise: ExerciseEntity
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "figure.run")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 32)

                // Exercise Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if !exercise.muscleGroups.isEmpty {
                        Text(exercise.muscleGroups.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    AddExerciseToSessionSheet { exercise, savePermanently in
        print("Selected: \(exercise.name), Save permanently: \(savePermanently)")
    }
}
