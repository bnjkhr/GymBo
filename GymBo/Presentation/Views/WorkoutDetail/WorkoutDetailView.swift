//
//  WorkoutDetailView.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Workout Detail View
//

import SwiftUI

/// Detail view for a workout template showing all exercises
///
/// **Features:**
/// - Workout header with name and stats
/// - List of all exercises with sets/reps/weight
/// - Start workout button
/// - Favorite toggle
///
/// **Design:**
/// - Clean, readable layout
/// - Exercise cards with icons
/// - Prominent start button
struct WorkoutDetailView: View {

    // MARK: - Properties

    let workoutId: UUID
    let onStartWorkout: () -> Void

    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dependencyContainer) private var dependencyContainer
    @Environment(\.dismiss) private var dismiss

    @State private var workout: Workout?
    @State private var exerciseNames: [UUID: String] = [:]
    @State private var isLoadingExercises = true
    @State private var workoutStore: WorkoutStore?
    @State private var isFavorite: Bool = false
    @State private var showExercisePicker = false

    // MARK: - Initialization

    init(workout: Workout, onStartWorkout: @escaping () -> Void) {
        self.workoutId = workout.id
        self.onStartWorkout = onStartWorkout
        self._workout = State(initialValue: workout)
        self._isFavorite = State(initialValue: workout.isFavorite)
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let workout = workout {
                ScrollView {
                    VStack(spacing: 24) {
                        // Stats Section
                        statsSection(for: workout)

                        // Exercises Section
                        if isLoadingExercises {
                            ProgressView("Lade Übungen...")
                                .padding()
                        } else {
                            exercisesSection(for: workout)
                        }

                        // Start Button
                        startButton
                            .padding(.top, 16)
                            .padding(.bottom, 32)
                    }
                    .padding()
                }
                .navigationTitle(workout.name)
            } else {
                ProgressView("Lade Workout...")
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    // Add Exercise Button
                    Button {
                        showExercisePicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.orange)
                    }

                    // Favorite Button
                    Button {
                        Task {
                            await toggleFavorite()
                        }
                    } label: {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundStyle(isFavorite ? .yellow : .primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView { exercise in
                Task {
                    await addExercise(exercise)
                }
            }
            .environment(\.dependencyContainer, dependencyContainer)
        }
        .successPill(
            isPresented: Binding(
                get: { workoutStore?.showSuccessPill ?? false },
                set: { newValue in workoutStore?.showSuccessPill = newValue }
            ),
            message: workoutStore?.successMessage ?? ""
        )
        .task {
            await loadData()
        }
    }

    // MARK: - Subviews

    /// Stats cards showing workout overview
    private func statsSection(for workout: Workout) -> some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "figure.strengthtraining.traditional",
                title: "Übungen",
                value: "\(workout.exerciseCount)"
            )

            StatCard(
                icon: "list.bullet",
                title: "Sätze",
                value: "\(workout.totalSets)"
            )

            StatCard(
                icon: "clock",
                title: "ca. Dauer",
                value: estimatedDuration(for: workout)
            )
        }
    }

    /// List of exercises in the workout
    private func exercisesSection(for workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Übungen")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)

            ForEach(
                Array(workout.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated()),
                id: \.element.id
            ) { index, exercise in
                ExerciseRow(
                    exercise: exercise,
                    exerciseName: exerciseNames[exercise.exerciseId] ?? "Übung \(index + 1)",
                    orderNumber: index + 1
                )
            }
        }
    }

    /// Start workout button
    private var startButton: some View {
        Button(action: onStartWorkout) {
            Label("Workout starten", systemImage: "play.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    // MARK: - Computed Properties

    private func estimatedDuration(for workout: Workout) -> String {
        // Estimate: (totalSets * 30s) + (restTime * sets) = rough estimate
        let workTime = workout.totalSets * 30  // 30 seconds per set
        let restTime = Int(workout.defaultRestTime) * workout.totalSets
        let totalSeconds = workTime + restTime
        let minutes = totalSeconds / 60

        if minutes < 60 {
            return "\(minutes) Min"
        } else {
            let hours = minutes / 60
            let remainingMins = minutes % 60
            return "\(hours)h \(remainingMins)m"
        }
    }

    // MARK: - Actions

    /// Load initial data
    private func loadData() async {
        // Initialize workout store
        if workoutStore == nil, let container = dependencyContainer {
            workoutStore = container.makeWorkoutStore()
        }

        // Load exercise names
        await loadExerciseNames()
    }

    /// Load exercise names from database
    private func loadExerciseNames() async {
        isLoadingExercises = true
        defer { isLoadingExercises = false }

        guard let container = dependencyContainer,
            let workout = workout
        else { return }
        let repository = container.makeExerciseRepository()

        for exercise in workout.exercises {
            do {
                if let exerciseEntity = try await repository.fetch(id: exercise.exerciseId) {
                    exerciseNames[exercise.exerciseId] = exerciseEntity.name
                }
            } catch {
                print("❌ Failed to load exercise name: \(error)")
            }
        }
    }

    /// Toggle favorite status
    private func toggleFavorite() async {
        guard let store = workoutStore else { return }

        // Optimistic update (sofortiges UI Feedback)
        isFavorite.toggle()

        print("🌟 Toggled favorite: \(workout?.name ?? "Unknown") → isFavorite: \(isFavorite)")

        // Dann Backend update
        await store.toggleFavorite(workoutId: workoutId)

        // Update local workout from store
        if let updatedWorkout = store.workouts.first(where: { $0.id == workoutId }) {
            workout = updatedWorkout
        }
    }

    /// Add exercise to workout
    private func addExercise(_ exercise: ExerciseEntity) async {
        guard let store = workoutStore else { return }

        await store.addExercise(exerciseId: exercise.id, to: workoutId)

        // Update local workout from store
        if let updatedWorkout = store.workouts.first(where: { $0.id == workoutId }) {
            workout = updatedWorkout
        }

        // Reload exercise names for new exercise
        await loadExerciseNames()
    }
}

// MARK: - Stat Card

/// Small stat card showing a metric
private struct StatCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.orange)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Exercise Row

/// Row showing an exercise in the workout
private struct ExerciseRow: View {
    let exercise: WorkoutExercise
    let exerciseName: String
    let orderNumber: Int

    var body: some View {
        HStack(spacing: 16) {
            // Order number
            Text("\(orderNumber)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                Text(exerciseName)
                    .font(.headline)

                HStack(spacing: 8) {
                    if let weight = exercise.targetWeight, weight > 0 {
                        Text("\(Int(weight)) kg")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(exercise.targetSets) × \(exercise.targetReps)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let restTime = exercise.restTime {
                        Text("• \(Int(restTime))s Pause")
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WorkoutDetailView(
            workout: Workout(
                name: "Push Day",
                exercises: [
                    WorkoutExercise(
                        exerciseId: UUID(),
                        targetSets: 4,
                        targetReps: 8,
                        targetWeight: 100.0,
                        restTime: 90,
                        orderIndex: 0
                    ),
                    WorkoutExercise(
                        exerciseId: UUID(),
                        targetSets: 3,
                        targetReps: 10,
                        targetWeight: 80.0,
                        restTime: 90,
                        orderIndex: 1
                    ),
                ],
                defaultRestTime: 90,
                isFavorite: true
            ),
            onStartWorkout: { print("Start workout") }
        )
        .environment(SessionStore.preview)
    }
}
