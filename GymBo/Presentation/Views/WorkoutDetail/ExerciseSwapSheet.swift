//
//  ExerciseSwapSheet.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V2 Clean Architecture - Presentation Layer
//

import SwiftUI

/// Sheet for swapping an exercise with an alternative
///
/// **Features:**
/// - Shows current exercise
/// - Lists alternatives from same muscle groups
/// - Search/filter functionality
/// - Toggle to save permanently to template
///
/// **Design:**
/// - Modern iOS 26 card design
/// - Clear current vs. new selection
/// - Prominent action buttons
struct ExerciseSwapSheet: View {

    // MARK: - Properties

    let currentExercise: ExerciseEntity
    let currentWorkoutExercise: WorkoutExercise
    let onSwap: (ExerciseEntity) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencyContainer) private var dependencyContainer

    @State private var allExercises: [ExerciseEntity] = []
    @State private var filteredExercises: [ExerciseEntity] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var selectedExercise: ExerciseEntity?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Exercise Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aktuelle Übung")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal, 20)

                        CurrentExerciseCard(exercise: currentExercise)
                            .padding(.horizontal, 16)
                    }
                    .onAppear {
                        print("🟢 ExerciseSwapSheet: Body rendered")
                        print("🟢 Current exercise: \(currentExercise.name)")
                        print(
                            "🟢 DependencyContainer: \(dependencyContainer != nil ? "Present" : "NIL")"
                        )
                    }

                    // Search Bar
                    SearchBar(text: $searchText, placeholder: "Alternativen suchen...")
                        .padding(.horizontal, 16)

                    // Alternatives Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Alternativen")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Spacer()
                            if !filteredExercises.isEmpty {
                                Text("\(filteredExercises.count)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)

                        if isLoading {
                            ProgressView("Lade Alternativen...")
                                .padding()
                        } else if filteredExercises.isEmpty {
                            EmptyStateView()
                                .padding(.horizontal, 16)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(filteredExercises, id: \.id) { exercise in
                                    AlternativeExerciseCard(
                                        exercise: exercise,
                                        isSelected: selectedExercise?.id == exercise.id
                                    )
                                    .onTapGesture {
                                        selectedExercise = exercise
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Übung ersetzen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ersetzen") {
                        if let selected = selectedExercise {
                            onSwap(selected)
                            dismiss()
                        }
                    }
                    .disabled(selectedExercise == nil)
                    .fontWeight(.semibold)
                }
            }
        }
        .task {
            await loadAlternatives()
        }
        .onChange(of: searchText) { _, newValue in
            filterExercises(searchText: newValue)
        }
    }

    // MARK: - Data Loading

    private func loadAlternatives() async {
        print("🔍 ExerciseSwapSheet: Loading alternatives for \(currentExercise.name)")
        print("🔍 Current muscle groups: \(currentExercise.muscleGroupsRaw)")

        guard let container = dependencyContainer else {
            print("❌ ExerciseSwapSheet: dependencyContainer is nil!")
            await MainActor.run {
                isLoading = false
            }
            return
        }

        let repository = container.makeExerciseRepository()

        do {
            // Load all exercises
            let exercises = try await repository.fetchAll()
            print("🔍 Loaded \(exercises.count) total exercises from repository")

            // Filter by same muscle groups
            let currentMuscleGroups = Set(currentExercise.muscleGroupsRaw)
            let alternatives = exercises.filter { exercise in
                // Exclude current exercise
                guard exercise.id != currentExercise.id else { return false }

                // Check if any muscle group matches
                let exerciseMuscleGroups = Set(exercise.muscleGroupsRaw)
                return !currentMuscleGroups.isDisjoint(with: exerciseMuscleGroups)
            }

            await MainActor.run {
                allExercises = alternatives
                filteredExercises = alternatives
                isLoading = false
            }

            print("✅ Loaded \(alternatives.count) alternatives for \(currentExercise.name)")
        } catch {
            print("❌ Failed to load alternatives: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func filterExercises(searchText: String) {
        if searchText.isEmpty {
            filteredExercises = allExercises
        } else {
            filteredExercises = allExercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText)
                    || exercise.muscleGroupsRaw.contains {
                        $0.localizedCaseInsensitiveContains(searchText)
                    } || exercise.equipmentTypeRaw.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Current Exercise Card

private struct CurrentExerciseCard: View {
    let exercise: ExerciseEntity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.title2)
                .foregroundStyle(.orange)
                .frame(width: 44, height: 44)
                .background(Color.orange.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.body)
                    .fontWeight(.semibold)

                HStack(spacing: 6) {
                    if !exercise.muscleGroupsRaw.isEmpty {
                        Text(exercise.muscleGroupsRaw.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(exercise.equipmentTypeRaw)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Alternative Exercise Card

private struct AlternativeExerciseCard: View {
    let exercise: ExerciseEntity
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.title3)
                .foregroundStyle(isSelected ? .orange : .secondary)
                .frame(width: 40, height: 40)
                .background(
                    isSelected
                        ? Color.orange.opacity(0.1)
                        : Color(.tertiarySystemGroupedBackground)
                )
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)

                HStack(spacing: 6) {
                    if !exercise.muscleGroupsRaw.isEmpty {
                        Text(exercise.muscleGroupsRaw.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(exercise.equipmentTypeRaw)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }
        }
        .padding(14)
        .background(
            isSelected
                ? Color.orange.opacity(0.05)
                : Color(.secondarySystemGroupedBackground)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Search Bar

private struct SearchBar: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

// MARK: - Empty State

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("Keine Alternativen gefunden")
                .font(.headline)

            Text("Versuche einen anderen Suchbegriff")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    ExerciseSwapSheet(
        currentExercise: ExerciseEntity(
            name: "Bankdrücken",
            muscleGroupsRaw: ["Brust", "Trizeps"],
            equipmentTypeRaw: "Langhantel"
        ),
        currentWorkoutExercise: WorkoutExercise(
            exerciseId: UUID(),
            targetSets: 4,
            targetReps: 8,
            targetWeight: 80.0,
            restTime: 90,
            orderIndex: 0
        ),
        onSwap: { exercise in
            print("Swapped to: \(exercise.name)")
        }
    )
}
