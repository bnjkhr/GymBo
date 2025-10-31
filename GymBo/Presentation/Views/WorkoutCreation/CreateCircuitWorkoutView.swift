//
//  CreateCircuitWorkoutView.swift
//  GymBo
//
//  Created on 2025-10-31.
//  V6 - Circuit Training UI
//

import SwiftUI

/// View for creating a new circuit training workout template
///
/// **Features:**
/// - 3-step wizard flow
/// - Step 1: Basic settings (name, rest times)
/// - Step 2: Create circuit groups (3+ stations)
/// - Step 3: Preview & save
///
/// **Differences from Superset:**
/// - Minimum 3 exercises per group (vs 2)
/// - Shorter rest between stations (default 30s vs 90s)
/// - Longer rest after circuit (default 180s vs 120s)
struct CreateCircuitWorkoutView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencyContainer) private var dependencyContainer
    @Environment(WorkoutStore.self) private var workoutStore

    // MARK: - Callback

    let onWorkoutCreated: (Workout) -> Void

    // MARK: - State

    @State private var currentStep: Int = 1
    @State private var workoutName: String = ""
    @State private var defaultRestTime: TimeInterval = 30  // Between stations (shorter!)
    @State private var restAfterGroup: TimeInterval = 180  // After circuit complete (longer!)
    @State private var exerciseGroups: [ExerciseGroup] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false

    // Exercise picker state
    @State private var showExercisePicker: Bool = false
    @State private var selectedGroupIndex: Int? = nil
    @State private var selectedExerciseIndex: Int? = nil

    // Exercise names cache
    @State private var exerciseNames: [UUID: String] = [:]

    @FocusState private var isNameFieldFocused: Bool

    // MARK: - Constants

    private let restTimeBetweenStationsOptions = [
        (value: TimeInterval(30), label: "30 Sek"),
        (value: TimeInterval(45), label: "45 Sek"),
        (value: TimeInterval(60), label: "60 Sek"),
        (value: TimeInterval(90), label: "90 Sek")
    ]

    private let restAfterCircuitOptions = [
        (value: TimeInterval(90), label: "90 Sek"),
        (value: TimeInterval(120), label: "2 Min"),
        (value: TimeInterval(180), label: "3 Min"),
        (value: TimeInterval(240), label: "4 Min")
    ]

    // MARK: - Computed

    private var canProceedFromStep1: Bool {
        !workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canProceedFromStep2: Bool {
        !exerciseGroups.isEmpty &&
        exerciseGroups.allSatisfy { group in
            group.exercises.count >= 3 &&  // Minimum 3 stations!
            group.exercises.allSatisfy { $0.targetSets > 0 } &&
            group.hasConsistentRounds
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Progress Indicator
                    progressIndicator

                    // Current Step Content
                    switch currentStep {
                    case 1:
                        step1BasicSettings
                    case 2:
                        step2CreateGroups
                    case 3:
                        step3Preview
                    default:
                        EmptyView()
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Circuit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
            .disabled(isLoading)
            .alert("Fehler", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Unbekannter Fehler")
            }
            .sheet(isPresented: $showExercisePicker) {
                exercisePickerSheet
            }
            .onAppear {
                // Initialize with one empty group
                if exerciseGroups.isEmpty {
                    exerciseGroups.append(ExerciseGroup(
                        exercises: [],
                        groupIndex: 0,
                        restAfterGroup: restAfterGroup
                    ))
                }

                // Auto-focus name field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isNameFieldFocused = true
                }
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: 10, height: 10)

                if step < 3 {
                    Rectangle()
                        .fill(step < currentStep ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(height: 2)
                }
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Step 1: Basic Settings

    private var step1BasicSettings: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Step Header
            Text("Schritt 1 von 3")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            // Name Section
            VStack(alignment: .leading, spacing: 8) {
                Text("NAME")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                TextField("z.B. Full Body Circuit", text: $workoutName)
                    .focused($isNameFieldFocused)
                    .autocorrectionDisabled()
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
            }

            // Rest Time Between Stations
            VStack(alignment: .leading, spacing: 12) {
                Text("PAUSENZEIT ZWISCHEN STATIONEN")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                restTimeButtons(
                    options: restTimeBetweenStationsOptions,
                    selection: $defaultRestTime
                )
            }

            // Rest Time After Circuit
            VStack(alignment: .leading, spacing: 12) {
                Text("PAUSENZEIT NACH RUNDE")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                restTimeButtons(
                    options: restAfterCircuitOptions,
                    selection: $restAfterGroup
                )
            }

            // Info Box
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color(hex: "#F77E2D"))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Circuit = 3+ Stationen")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("Stationen werden nacheinander in Rotation absolviert")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(hex: "#F77E2D").opacity(0.1))
            .cornerRadius(12)

            // Next Button
            Button {
                nextStep()
            } label: {
                Text("Weiter")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canProceedFromStep1 ? Color.primary : Color.secondary)
                    .cornerRadius(12)
            }
            .disabled(!canProceedFromStep1)
        }
    }

    // MARK: - Step 2: Create Groups

    private var step2CreateGroups: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Step Header
            Text("Schritt 2 von 3")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            // Section Title
            Text("CIRCUIT-GRUPPEN")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            // Groups List
            ForEach(Array(exerciseGroups.enumerated()), id: \.element.id) { index, group in
                ExerciseGroupBuilder(
                    groupType: .circuit,
                    groupIndex: index,
                    group: bindingForGroup(at: index),
                    exerciseNames: exerciseNames,
                    onAddExercise: {
                        addExerciseToGroup(at: index)
                    },
                    onEditExercise: { exerciseId in
                        editExerciseInGroup(groupIndex: index, exerciseId: exerciseId)
                    },
                    onDeleteExercise: { exerciseId in
                        deleteExerciseFromGroup(groupIndex: index, exerciseId: exerciseId)
                    },
                    onDeleteGroup: {
                        deleteGroup(at: index)
                    }
                )
            }

            // Info: Minimum 3 stations required
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)

                Text("Mindestens 3 Stationen pro Circuit erforderlich")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)

            // Add Another Circuit Button
            Button {
                addNewGroup()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)

                    Text("Weiteren Circuit hinzufügen")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color(hex: "#F77E2D"))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#F77E2D").opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            // Navigation Buttons
            HStack {
                Button {
                    previousStep()
                } label: {
                    Text("Zurück")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                }

                Button {
                    nextStep()
                } label: {
                    Text("Weiter")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canProceedFromStep2 ? Color.primary : Color.secondary)
                        .cornerRadius(12)
                }
                .disabled(!canProceedFromStep2)
            }
        }
    }

    // MARK: - Step 3: Preview

    private var step3Preview: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Step Header
            Text("Schritt 3 von 3")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            // Section Title
            Text("VORSCHAU")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            // Workout Summary
            VStack(alignment: .leading, spacing: 16) {
                // Workout Name
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(Color(hex: "#F77E2D"))
                    Text(workoutName)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                // Rest Times
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pausenzeit: \(Int(defaultRestTime))s zwischen Stationen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Pausenzeit: \(Int(restAfterGroup))s nach Runde")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            // Groups Preview
            ForEach(Array(exerciseGroups.enumerated()), id: \.element.id) { index, group in
                groupPreview(group: group, index: index)
            }

            // Total Summary
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(Color(hex: "#F77E2D"))

                let totalStations = exerciseGroups.reduce(0) { sum, group in
                    sum + group.exercises.count
                }
                let totalSets = exerciseGroups.reduce(0) { sum, group in
                    sum + (group.exercises.first?.targetSets ?? 0) * group.exercises.count
                }

                Text("Gesamt: \(exerciseGroups.count) Circuits, \(totalStations) Stationen, \(totalSets) Sätze")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            // Navigation Buttons
            HStack {
                Button {
                    previousStep()
                } label: {
                    Text("Zurück")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                }

                Button {
                    createWorkout()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Erstellen")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color(hex: "#F77E2D"))
                .cornerRadius(12)
                .disabled(isLoading)
            }
        }
    }

    // MARK: - Helpers

    private func restTimeButtons(options: [(value: TimeInterval, label: String)], selection: Binding<TimeInterval>) -> some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.value) { option in
                Button {
                    selection.wrappedValue = option.value
                    HapticFeedback.impact(.light)
                } label: {
                    Text(option.label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selection.wrappedValue == option.value ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selection.wrappedValue == option.value
                                ? Color.primary
                                : Color(.secondarySystemGroupedBackground)
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func groupPreview(group: ExerciseGroup, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Group Header
            Text("Circuit \(index + 1) (\(group.rounds) Runden)")
                .font(.headline)

            // Exercises
            ForEach(Array(group.exercises.enumerated()), id: \.element.id) { exIndex, exercise in
                let letters = ["A", "B", "C", "D", "E", "F", "G", "H"]
                VStack(alignment: .leading, spacing: 4) {
                    Text("Station \(letters[min(exIndex, letters.count - 1)]): ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    + Text(exerciseNames[exercise.exerciseId] ?? "Unbekannt")
                        .font(.body)
                        .fontWeight(.medium)

                    Text("\(exercise.targetSets) × \(exercise.targetReps ?? 0) Wdh × \(exercise.targetWeight ?? 0 > 0 ? String(format: "%.1f", exercise.targetWeight!) + "kg" : "Körpergewicht")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 16)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var exercisePickerSheet: some View {
        Text("Exercise Picker - TODO")
            // TODO: Implement ExercisePicker integration
    }

    // MARK: - Actions

    private func nextStep() {
        withAnimation {
            currentStep = min(currentStep + 1, 3)
        }
        HapticFeedback.impact(.medium)
    }

    private func previousStep() {
        withAnimation {
            currentStep = max(currentStep - 1, 1)
        }
        HapticFeedback.impact(.light)
    }

    private func addNewGroup() {
        let newGroup = ExerciseGroup(
            exercises: [],
            groupIndex: exerciseGroups.count,
            restAfterGroup: restAfterGroup
        )
        exerciseGroups.append(newGroup)
        HapticFeedback.impact(.light)
    }

    private func deleteGroup(at index: Int) {
        exerciseGroups.remove(at: index)
        // Reindex remaining groups
        for i in 0..<exerciseGroups.count {
            exerciseGroups[i].groupIndex = i
        }
        HapticFeedback.impact(.medium)
    }

    private func addExerciseToGroup(at groupIndex: Int) {
        selectedGroupIndex = groupIndex
        selectedExerciseIndex = nil
        showExercisePicker = true
    }

    private func editExerciseInGroup(groupIndex: Int, exerciseId: UUID) {
        guard let exerciseIndex = exerciseGroups[groupIndex].exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        selectedGroupIndex = groupIndex
        selectedExerciseIndex = exerciseIndex
        showExercisePicker = true
    }

    private func deleteExerciseFromGroup(groupIndex: Int, exerciseId: UUID) {
        exerciseGroups[groupIndex].exercises.removeAll { $0.id == exerciseId }
        HapticFeedback.impact(.light)
    }

    private func bindingForGroup(at index: Int) -> Binding<ExerciseGroup> {
        Binding(
            get: { exerciseGroups[index] },
            set: { exerciseGroups[index] = $0 }
        )
    }

    private func createWorkout() {
        guard let container = dependencyContainer else {
            errorMessage = "Dependency Container nicht verfügbar"
            showError = true
            return
        }

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let useCase = container.makeCreateCircuitWorkoutUseCase()

                let workout = try await useCase.execute(
                    name: workoutName.trimmingCharacters(in: .whitespacesAndNewlines),
                    defaultRestTime: defaultRestTime,
                    exerciseGroups: exerciseGroups
                )

                HapticFeedback.notification(.success)
                onWorkoutCreated(workout)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                HapticFeedback.notification(.error)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
// Preview temporarily disabled - requires DependencyContainer.preview extension
// #Preview {
//     CreateCircuitWorkoutView(onWorkoutCreated: { _ in })
//         .environment(WorkoutStore.preview)
// }
#endif
