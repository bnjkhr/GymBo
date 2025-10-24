//
//  ExercisesView.swift
//  GymBo
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Exercises Library View
//

import SwiftUI

/// Exercises library view showing all available exercises
///
/// **Features:**
/// - Search exercises by name
/// - Filter by muscle group and equipment
/// - Tap exercise to see details
/// - Modern card-based design
///
/// **Design:**
/// - Header with title
/// - Search bar
/// - Filter chips (horizontal scroll)
/// - Exercise cards
struct ExercisesView: View {

    @Environment(\.dependencyContainer) private var dependencyContainer

    @State private var exercises: [ExerciseEntity] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedMuscleGroup: String?
    @State private var selectedEquipment: String?
    @State private var selectedExercise: ExerciseEntity?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header
                header

                // Search Bar
                searchBar

                // Filter Chips
                if !exercises.isEmpty {
                    filterChips
                }

                // Exercise List
                if isLoading {
                    ProgressView("Lade Übungen...")
                        .frame(maxHeight: .infinity)
                } else if filteredExercises.isEmpty {
                    emptyState
                } else {
                    exerciseList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
            .task {
                await loadExercises()
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(alignment: .center) {
            Text("Übungen")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            Text("\(filteredExercises.count)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color(.systemBackground))
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Übung suchen...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Muscle Group Filters
                FilterChip(
                    title: "Alle",
                    icon: nil,
                    isSelected: selectedMuscleGroup == nil && selectedEquipment == nil
                ) {
                    selectedMuscleGroup = nil
                    selectedEquipment = nil
                }

                ForEach(availableMuscleGroups, id: \.self) { group in
                    FilterChip(
                        title: group,
                        icon: muscleGroupIcon(for: group),
                        isSelected: selectedMuscleGroup == group
                    ) {
                        selectedMuscleGroup = (selectedMuscleGroup == group) ? nil : group
                        selectedEquipment = nil
                    }
                }

                Divider()
                    .frame(height: 24)

                // Equipment Filters
                ForEach(availableEquipment, id: \.self) { equipment in
                    FilterChip(
                        title: equipment,
                        icon: equipmentIcon(for: equipment),
                        isSelected: selectedEquipment == equipment
                    ) {
                        selectedEquipment = (selectedEquipment == equipment) ? nil : equipment
                        selectedMuscleGroup = nil
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredExercises) { exercise in
                    ExerciseCard(exercise: exercise) {
                        selectedExercise = exercise
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Keine Übungen gefunden")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Versuche andere Suchbegriffe oder Filter")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }

    // MARK: - Computed Properties

    private var filteredExercises: [ExerciseEntity] {
        exercises.filter { exercise in
            // Search filter
            let matchesSearch =
                searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText)

            // Muscle group filter
            let matchesMuscleGroup =
                selectedMuscleGroup == nil
                || exercise.muscleGroupsRaw.contains(selectedMuscleGroup!)

            // Equipment filter
            let matchesEquipment =
                selectedEquipment == nil || exercise.equipmentTypeRaw == selectedEquipment!

            return matchesSearch && matchesMuscleGroup && matchesEquipment
        }
    }

    private var availableMuscleGroups: [String] {
        let allGroups = exercises.flatMap { $0.muscleGroupsRaw }
        return Array(Set(allGroups)).sorted()
    }

    private var availableEquipment: [String] {
        let allEquipment = exercises.map { $0.equipmentTypeRaw }.filter { !$0.isEmpty }
        return Array(Set(allEquipment)).sorted()
    }

    // MARK: - Helper Functions

    private func muscleGroupIcon(for group: String) -> String? {
        switch group.lowercased() {
        case "brust": return "figure.arms.open"
        case "rücken": return "figure.walk"
        case "schultern": return "figure.arms.open"
        case "beine": return "figure.walk"
        case "arme": return "figure.arms.open"
        case "core", "bauch": return "figure.core.training"
        default: return nil
        }
    }

    private func equipmentIcon(for equipment: String) -> String? {
        switch equipment.lowercased() {
        case "langhantel": return "figure.strengthtraining.traditional"
        case "kurzhantel": return "dumbbell"
        case "bodyweight": return "figure.walk"
        case "maschine": return "gearshape"
        case "kabelzug": return "arrow.left.and.right"
        default: return nil
        }
    }

    // MARK: - Actions

    private func loadExercises() async {
        isLoading = true
        defer { isLoading = false }

        guard let container = dependencyContainer else { return }
        let repository = container.makeExerciseRepository()

        do {
            exercises = try await repository.fetchAll()
            print("✅ Loaded \(exercises.count) exercises")
        } catch {
            print("❌ Failed to load exercises: \(error)")
        }
    }
}

// MARK: - Exercise Card Component

private struct ExerciseCard: View {
    let exercise: ExerciseEntity
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Equipment Icon
                Image(systemName: equipmentIcon)
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(width: 32)

                // Exercise Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        // Muscle Groups
                        if !exercise.muscleGroupsRaw.isEmpty {
                            Text(exercise.muscleGroupsRaw.prefix(2).joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Difficulty
                        if !exercise.difficultyLevelRaw.isEmpty {
                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text(exercise.difficultyLevelRaw)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var equipmentIcon: String {
        switch exercise.equipmentTypeRaw.lowercased() {
        case "langhantel": return "figure.strengthtraining.traditional"
        case "kurzhantel": return "dumbbell.fill"
        case "bodyweight": return "figure.walk"
        case "maschine": return "gearshape.fill"
        case "kabelzug": return "arrow.left.and.right"
        default: return "dumbbell.fill"
        }
    }
}

// MARK: - Filter Chip Component

private struct FilterChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }

                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.primary : Color(.systemGray6))
            .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
            .cornerRadius(16)
        }
    }
}

// MARK: - Preview

#Preview {
    ExercisesView()
}
