//
//  ExercisePickerView.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Exercise Picker
//

import SwiftUI

/// View for picking exercises from the catalog
///
/// **Features:**
/// - Search exercises by name
/// - Filter by muscle group
/// - Filter by equipment type
/// - Shows 145 German exercises from database
///
/// **Design:**
/// - Search bar at top
/// - Filter chips below search
/// - Scrollable exercise list
/// - Tap to select and dismiss
struct ExercisePickerView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencyContainer) private var dependencyContainer

    let onExerciseSelected: (ExerciseEntity) -> Void

    @State private var exercises: [ExerciseEntity] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedMuscleGroup: String?
    @State private var selectedEquipment: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar

                // Filter Chips
                if !exercises.isEmpty {
                    filterChips
                        .padding(.vertical, 8)
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
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Muscle Group Filters
                ForEach(availableMuscleGroups, id: \.self) { group in
                    FilterChip(
                        title: group,
                        isSelected: selectedMuscleGroup == group
                    ) {
                        if selectedMuscleGroup == group {
                            selectedMuscleGroup = nil
                        } else {
                            selectedMuscleGroup = group
                        }
                    }
                }

                Divider()
                    .frame(height: 24)

                // Equipment Filters
                ForEach(availableEquipment, id: \.self) { equipment in
                    FilterChip(
                        title: equipmentDisplayName(equipment),
                        isSelected: selectedEquipment == equipment,
                        icon: equipmentIcon(equipment)
                    ) {
                        if selectedEquipment == equipment {
                            selectedEquipment = nil
                        } else {
                            selectedEquipment = equipment
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredExercises, id: \.id) { exercise in
                    ExercisePickerRow(exercise: exercise) {
                        onExerciseSelected(exercise)
                        dismiss()
                    }
                }
            }
            .padding()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Keine Übungen gefunden")
                .font(.headline)

            Text("Versuche andere Suchbegriffe oder Filter")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }

    // MARK: - Computed Properties

    private var filteredExercises: [ExerciseEntity] {
        var filtered = exercises

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by muscle group
        if let selectedGroup = selectedMuscleGroup {
            filtered = filtered.filter { exercise in
                exercise.muscleGroupsRaw.contains(selectedGroup)
            }
        }

        // Filter by equipment
        if let selectedEquip = selectedEquipment {
            filtered = filtered.filter { exercise in
                exercise.equipmentTypeRaw == selectedEquip
            }
        }

        return filtered
    }

    private var availableMuscleGroups: [String] {
        // Get unique muscle groups from all exercises
        let allGroups = exercises.flatMap { $0.muscleGroupsRaw }
        return Array(Set(allGroups)).sorted()
    }

    private var availableEquipment: [String] {
        // Get unique equipment types
        let allEquipment = exercises.map { $0.equipmentTypeRaw }
        return Array(Set(allEquipment)).sorted()
    }

    // MARK: - Helpers

    private func equipmentDisplayName(_ raw: String) -> String {
        switch raw {
        case "Freie Gewichte": return "Freie Gewichte"
        case "Maschinen": return "Maschinen"
        case "Körpergewicht": return "Körpergewicht"
        case "Kabel": return "Kabel"
        case "Kurzhanteln": return "Kurzhanteln"
        default: return raw
        }
    }

    private func equipmentIcon(_ raw: String) -> String {
        switch raw {
        case "Freie Gewichte": return "dumbbell"
        case "Maschinen": return "gearshape.2"
        case "Körpergewicht": return "figure.strengthtraining.traditional"
        case "Kabel": return "cable.connector"
        case "Kurzhanteln": return "dumbbell"
        default: return "circle"
        }
    }

    // MARK: - Actions

    private func loadExercises() async {
        guard let container = dependencyContainer else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let repository = container.makeExerciseRepository()
            exercises = try await repository.fetchAll()
            print("✅ Loaded \(exercises.count) exercises")
        } catch {
            print("❌ Failed to load exercises: \(error)")
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var icon: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
            .background(isSelected ? Color.orange : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

// MARK: - Exercise Picker Row

private struct ExercisePickerRow: View {
    let exercise: ExerciseEntity
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Exercise Icon
                Image(systemName: equipmentIcon)
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .frame(width: 40)

                // Exercise Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

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
                                .foregroundStyle(.tertiary)

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
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    private var equipmentIcon: String {
        switch exercise.equipmentTypeRaw {
        case "Freie Gewichte": return "dumbbell.fill"
        case "Maschinen": return "gearshape.2.fill"
        case "Körpergewicht": return "figure.strengthtraining.traditional"
        case "Kabel": return "cable.connector"
        case "Kurzhanteln": return "dumbbell.fill"
        default: return "circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    ExercisePickerView { exercise in
        print("Selected: \(exercise.name)")
    }
}
