//
//  CreateExerciseView.swift
//  GymBo
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Presentation Layer
//

import SwiftUI

/// View for creating a custom exercise
///
/// **Features:**
/// - Exercise name input
/// - Multi-select muscle groups
/// - Equipment picker
/// - Difficulty selector
/// - Optional description & instructions
///
/// **Design:**
/// - iOS 26 Modern Card Design
/// - Multi-step form layout
/// - Validation feedback
struct CreateExerciseView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencyContainer) private var dependencyContainer

    // MARK: - Callback

    let onExerciseCreated: (ExerciseEntity) -> Void

    // MARK: - State

    @State private var name = ""
    @State private var selectedMuscleGroups: Set<String> = []
    @State private var selectedEquipment = "Langhantel"
    @State private var selectedDifficulty = "Anfänger"
    @State private var descriptionText = ""
    @State private var instructions = ""  // Newline-separated
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isNameFieldFocused: Bool

    // MARK: - Constants

    private let muscleGroups = [
        "Brust", "Rücken", "Schultern", "Beine", "Arme", "Core", "Bauch",
    ]

    private let equipmentTypes = [
        "Langhantel", "Kurzhantel", "Kabelzug", "Maschine", "Bodyweight", "Gemischt",
    ]

    private let difficultyLevels = [
        "Anfänger", "Fortgeschritten", "Experte",
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Name Section
                    nameSection

                    // Muscle Groups Section
                    muscleGroupsSection

                    // Equipment Section
                    equipmentSection

                    // Difficulty Section (optional)
                    difficultySection

                    // Description Section (optional)
                    descriptionSection

                    // Instructions Section (optional)
                    instructionsSection
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Neue Übung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    cancelButton
                }

                ToolbarItem(placement: .confirmationAction) {
                    createButton
                }
            }
            .disabled(isLoading)
            .alert("Fehler", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .onAppear {
                // Auto-focus name field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isNameFieldFocused = true
                }
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            TextField("z.B. Bankdrücken", text: $name)
                .focused($isNameFieldFocused)
                .autocorrectionDisabled()
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .accessibilityLabel("Übungsname")
        }
    }

    private var muscleGroupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Muskelgruppen")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            Text("Wähle mindestens eine Muskelgruppe")
                .font(.caption)
                .foregroundColor(.secondary)

            // Muscle Group Chips
            FlowLayout(spacing: 8) {
                ForEach(muscleGroups, id: \.self) { group in
                    MuscleGroupChip(
                        title: group,
                        isSelected: selectedMuscleGroups.contains(group)
                    ) {
                        toggleMuscleGroup(group)
                    }
                }
            }
        }
    }

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Equipment")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 8) {
                ForEach(equipmentTypes, id: \.self) { equipment in
                    Button {
                        selectedEquipment = equipment
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack {
                            Text(equipment)
                                .font(.body)
                                .foregroundColor(.primary)

                            Spacer()

                            if selectedEquipment == equipment {
                                Image(systemName: "checkmark")
                                    .font(.subheadline)
                                    .foregroundColor(.appOrange)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schwierigkeit (Optional)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                ForEach(difficultyLevels, id: \.self) { difficulty in
                    Button {
                        selectedDifficulty = difficulty
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text(difficulty)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedDifficulty == difficulty ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                selectedDifficulty == difficulty
                                    ? Color.appOrange
                                    : Color(
                                        .secondarySystemGroupedBackground)
                            )
                            .cornerRadius(20)
                    }
                }
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Beschreibung (Optional)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            TextField("Was trainiert diese Übung?", text: $descriptionText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .lineLimit(3...6)
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Anleitung (Optional)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            Text("Eine Zeile pro Schritt")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField(
                "1. Leg dich auf die Bank\n2. Greife die Stange\n3. ...", text: $instructions,
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .lineLimit(5...10)
        }
    }

    // MARK: - Toolbar Buttons

    private var cancelButton: some View {
        Button("Abbrechen") {
            dismiss()
        }
        .disabled(isLoading)
    }

    private var createButton: some View {
        Button("Erstellen") {
            Task {
                await createExercise()
            }
        }
        .fontWeight(.semibold)
        .disabled(!isValid || isLoading)
        .accessibilityLabel("Übung erstellen")
    }

    // MARK: - Computed Properties

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !selectedMuscleGroups.isEmpty
    }

    // MARK: - Actions

    private func toggleMuscleGroup(_ group: String) {
        if selectedMuscleGroups.contains(group) {
            selectedMuscleGroups.remove(group)
        } else {
            selectedMuscleGroups.insert(group)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @MainActor
    private func createExercise() async {
        isLoading = true
        defer { isLoading = false }

        guard let container = dependencyContainer else {
            errorMessage = "Dependency Container nicht verfügbar"
            return
        }

        // Create use case
        let repository = container.makeExerciseRepository()
        let useCase = DefaultCreateExerciseUseCase(exerciseRepository: repository)

        // Parse instructions (split by newline)
        let instructionsList =
            instructions
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        do {
            let exercise = try await useCase.execute(
                name: name,
                muscleGroups: Array(selectedMuscleGroups),
                equipment: selectedEquipment,
                difficulty: selectedDifficulty,
                description: descriptionText,
                instructions: instructionsList
            )

            print("✅ Created exercise: \(exercise.name)")

            // Success - call callback
            dismiss()
            onExerciseCreated(exercise)

        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to create exercise: \(error)")
        }
    }
}

// MARK: - Muscle Group Chip Component

private struct MuscleGroupChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.appOrange : Color(.secondarySystemGroupedBackground))
                .cornerRadius(20)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    CreateExerciseView { exercise in
        print("Created: \(exercise.name)")
    }
}
#endif
