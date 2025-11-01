//
//  WorkoutSelectionSheet.swift
//  GymBo
//
//  Created on 2025-11-01.
//  Feature: Add Exercise to Workout from Exercises View
//

import SwiftUI

/// Sheet for selecting a workout to add an exercise to
///
/// **Features:**
/// - Shows all workouts (grouped by favorites/folders/uncategorized)
/// - Search bar (optional, for large workout lists)
/// - Tap workout to add exercise
/// - Success feedback
///
/// **Usage:**
/// ```swift
/// WorkoutSelectionSheet(exercise: exercise) { workout in
///     await addExerciseToWorkout(exercise, workout)
/// }
/// ```
struct WorkoutSelectionSheet: View {

    // MARK: - Properties

    let exercise: ExerciseEntity
    let onWorkoutSelected: (Workout) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutStore.self) private var workoutStore

    @State private var searchText = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Exercise Info Header
                exerciseInfoHeader

                // Search Bar (only if more than 5 workouts)
                if workoutStore.workouts.count > 5 {
                    searchBar
                }

                // Workout List
                workoutList
            }
            .navigationTitle("Workout auswählen")
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

    // MARK: - Subviews

    private var exerciseInfoHeader: some View {
        VStack(spacing: 4) {
            Text(exercise.name)
                .font(.headline)
                .foregroundStyle(.primary)

            if !exercise.muscleGroupsRaw.isEmpty {
                Text(exercise.muscleGroupsRaw.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Workouts durchsuchen...", text: $searchText)
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
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var workoutList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                let favorites = filteredWorkouts.filter { $0.isFavorite }
                let folders = workoutStore.folders
                let regular = filteredWorkouts.filter { !$0.isFavorite }

                // Favorites Section
                if !favorites.isEmpty {
                    sectionHeader("FAVORITEN")
                    ForEach(favorites) { workout in
                        workoutCard(workout)
                    }
                }

                // Folder Sections
                ForEach(folders) { folder in
                    let folderWorkouts = filteredWorkouts.filter { $0.folderId == folder.id }
                    if !folderWorkouts.isEmpty {
                        folderSectionHeader(folder)
                        ForEach(folderWorkouts) { workout in
                            workoutCard(workout)
                        }
                    }
                }

                // Uncategorized Workouts
                let uncategorized = regular.filter { $0.folderId == nil }
                if !uncategorized.isEmpty {
                    sectionHeader("ALLE WORKOUTS")
                    ForEach(uncategorized) { workout in
                        workoutCard(workout)
                    }
                }

                // Empty State
                if filteredWorkouts.isEmpty {
                    emptyState
                }
            }
            .padding()
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func folderSectionHeader(_ folder: WorkoutFolder) -> some View {
        HStack {
            Circle()
                .fill(Color(hex: folder.color) ?? .purple)
                .frame(width: 12, height: 12)

            Text(folder.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func workoutCard(_ workout: Workout) -> some View {
        Button {
            onWorkoutSelected(workout)
            dismiss()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        if workout.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.appOrange)
                        }

                        Text(workout.name)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }

                    Text("\(workout.exerciseCount) Übungen • \(workout.totalSets) Sätze")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Keine Workouts gefunden")
                .font(.title3)
                .fontWeight(.semibold)

            if !searchText.isEmpty {
                Text("Versuche andere Suchbegriffe")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Erstelle zuerst ein Workout")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxHeight: .infinity)
        .padding()
    }

    // MARK: - Computed Properties

    private var filteredWorkouts: [Workout] {
        if searchText.isEmpty {
            return workoutStore.workouts
        } else {
            return workoutStore.workouts.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let previewExercise = ExerciseEntity(
        id: UUID(),
        name: "Bankdrücken",
        muscleGroupsRaw: ["Brust", "Schultern", "Trizeps"],
        equipmentTypeRaw: "Langhantel",
        difficultyLevelRaw: "Fortgeschritten",
        descriptionText: "Kraftübung für die Brustmuskulatur",
        instructions: []
    )

    WorkoutSelectionSheet(exercise: previewExercise) { workout in
        print("Selected workout: \(workout.name)")
    }
    .environment(WorkoutStore.preview)
}
#endif
