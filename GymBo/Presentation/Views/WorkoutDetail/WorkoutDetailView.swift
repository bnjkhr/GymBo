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
    let openExercisePickerOnAppear: Bool

    @Environment(SessionStore.self) private var sessionStore
    @Environment(WorkoutStore.self) private var workoutStore
    @Environment(\.dependencyContainer) private var dependencyContainer
    @Environment(\.dismiss) private var dismiss

    @State private var workout: Workout?
    @State private var exerciseNames: [UUID: String] = [:]
    @State private var isLoadingExercises = true
    @State private var isFavorite: Bool = false
    @State private var showExercisePicker = false
    @State private var exerciseToEdit: WorkoutExercise?
    @State private var showEditWorkout = false
    @State private var showDeleteConfirmation = false

    // MARK: - Initialization

    init(
        workout: Workout, onStartWorkout: @escaping () -> Void,
        openExercisePickerOnAppear: Bool = false
    ) {
        self.workoutId = workout.id
        self.onStartWorkout = onStartWorkout
        self.openExercisePickerOnAppear = openExercisePickerOnAppear
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

                        // Start Button (directly below stats)
                        startButton

                        // Exercises Section
                        if isLoadingExercises {
                            ProgressView("Lade Übungen...")
                                .padding()
                        } else {
                            exercisesSection(for: workout)
                        }
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
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Übung hinzufügen")

                    // Favorite Button
                    Button {
                        Task {
                            await toggleFavorite()
                        }
                    } label: {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundStyle(isFavorite ? .yellow : .primary)
                    }
                    .accessibilityLabel(
                        isFavorite ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen")

                    // Edit Button
                    Button {
                        showEditWorkout = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Workout bearbeiten")

                    // Delete Button
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash.circle")
                            .foregroundStyle(.red)
                    }
                    .accessibilityLabel("Workout löschen")
                }
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView { exercises in
                Task {
                    await addExercises(exercises)
                }
            }
            .environment(\.dependencyContainer, dependencyContainer)
        }
        .sheet(item: $exerciseToEdit) { exercise in
            if let workout = workout {
                EditExerciseDetailsView(
                    workoutId: workout.id,
                    exercise: exercise,
                    exerciseName: exerciseNames[exercise.exerciseId] ?? "Übung",
                    onSave: { sets, reps, time, weight, rest, notes in
                        Task {
                            await updateExercise(
                                exercise,
                                targetSets: sets,
                                targetReps: reps,
                                targetTime: time,
                                targetWeight: weight,
                                restTime: rest,
                                notes: notes
                            )
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showEditWorkout) {
            if let workout = workout {
                EditWorkoutView(
                    workout: workout,
                    onSave: { name, restTime in
                        Task {
                            await workoutStore.updateWorkout(
                                workoutId: workout.id,
                                name: name,
                                defaultRestTime: restTime
                            )
                            // Force reload from database to update UI
                            print("🔄 WorkoutDetailView: Forcing refresh after update")
                            await workoutStore.refresh()
                            // Update local workout from refreshed store
                            if let updatedWorkout = workoutStore.workouts.first(where: {
                                $0.id == workoutId
                            }) {
                                self.workout = updatedWorkout
                            }
                        }
                    }
                )
                .environment(workoutStore)
            }
        }
        .confirmationDialog(
            "Workout löschen?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) {
                Task {
                    await deleteWorkout()
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Dieses Workout kann nicht wiederhergestellt werden.")
        }
        .successPill(
            isPresented: Binding(
                get: { workoutStore.showSuccessPill },
                set: { newValue in workoutStore.showSuccessPill = newValue }
            ),
            message: workoutStore.successMessage ?? ""
        )
        .task(id: workoutStore.refreshTrigger) {
            // Reload when refreshTrigger changes (e.g., after adding exercises during session)
            await loadData()
        }
        .onAppear {
            // Open ExercisePicker automatically if requested
            if openExercisePickerOnAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showExercisePicker = true
                }
            }
        }
    }

    // MARK: - Subviews

    /// Stats cards showing workout overview (Modern Compact Design)
    private func statsSection(for workout: Workout) -> some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "figure.strengthtraining.traditional",
                value: "\(workout.exerciseCount)",
                label: "Übungen"
            )

            StatCard(
                icon: "list.bullet",
                value: "\(workout.totalSets)",
                label: "Sätze"
            )

            StatCard(
                icon: "clock",
                value: estimatedDuration(for: workout),
                label: "Dauer"
            )
        }
        .padding(.horizontal)
    }

    /// List of exercises in the workout (Modern Compact Design)
    private func exercisesSection(for workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text("Übungen")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 20)

            // Exercise Cards
            VStack(spacing: 8) {
                ForEach(
                    Array(
                        workout.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated()
                    ),
                    id: \.element.id
                ) { index, exercise in
                    ExerciseCard(
                        exercise: exercise,
                        exerciseName: exerciseNames[exercise.exerciseId] ?? "Übung \(index + 1)",
                        orderNumber: index + 1
                    )
                    .id(
                        "\(exercise.id)-\(exercise.targetSets)-\(exercise.targetReps ?? 0)-\(exercise.targetWeight ?? 0)"
                    )
                    .onTapGesture {
                        exerciseToEdit = exercise
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                await removeExercise(exercise)
                            }
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    /// Start workout button (Modern iOS 26 Design)
    private var startButton: some View {
        Button(action: {
            onStartWorkout()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.body)
                Text("Workout starten")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.primary)
            .foregroundColor(Color(.systemBackground))
            .cornerRadius(14)
        }
        .padding(.horizontal, 16)
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
        // ALWAYS fetch fresh workout data from repository
        // Don't use cached store - create fresh store each time to avoid stale data
        guard let container = dependencyContainer else { return }

        // Create a fresh use case to fetch the workout
        let repository = container.makeWorkoutRepository()
        let getWorkoutUseCase = DefaultGetWorkoutByIdUseCase(repository: repository)

        do {
            let freshWorkout = try await getWorkoutUseCase.execute(id: workoutId)
            print("🔵 Loaded FRESH workout from repository:")
            for (idx, ex) in freshWorkout.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }
            ).enumerated() {
                print("🔵   - Order \(idx): \(ex.id)")
            }
            workout = freshWorkout
            isFavorite = freshWorkout.isFavorite
        } catch {
            print("❌ Failed to load fresh workout: \(error)")
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
                } else {
                    print("⚠️ Exercise not found: \(exercise.exerciseId)")
                }
            } catch {
                print("❌ Failed to load exercise name: \(error)")
            }
        }
    }

    /// Toggle favorite status
    private func toggleFavorite() async {
        // Optimistic update (sofortiges UI Feedback)
        isFavorite.toggle()

        print("🌟 Toggled favorite: \(workout?.name ?? "Unknown") → isFavorite: \(isFavorite)")

        // Dann Backend update
        await workoutStore.toggleFavorite(workoutId: workoutId)

        // Update local workout from store
        if let updatedWorkout = workoutStore.workouts.first(where: { $0.id == workoutId }) {
            workout = updatedWorkout
        }
    }

    /// Add multiple exercises to workout
    private func addExercises(_ exercises: [ExerciseEntity]) async {
        // Add each exercise
        for exercise in exercises {
            await workoutStore.addExercise(exerciseId: exercise.id, to: workoutId)
        }

        // Update local workout from store
        if let updatedWorkout = workoutStore.workouts.first(where: { $0.id == workoutId }) {
            workout = updatedWorkout
        }

        // Reload exercise names for new exercises
        await loadExerciseNames()

        // Show success message
        let count = exercises.count
        let message = count == 1 ? "1 Übung hinzugefügt" : "\(count) Übungen hinzugefügt"
        workoutStore.showSuccess(message)
    }

    /// Remove exercise from workout
    private func removeExercise(_ exercise: WorkoutExercise) async {
        await workoutStore.removeExercise(exerciseId: exercise.id, from: workoutId)

        // Update local workout from store
        if let updatedWorkout = workoutStore.workouts.first(where: { $0.id == workoutId }) {
            workout = updatedWorkout
        }
    }

    /// Update exercise details in workout
    private func updateExercise(
        _ exercise: WorkoutExercise,
        targetSets: Int,
        targetReps: Int?,
        targetTime: TimeInterval?,
        targetWeight: Double?,
        restTime: TimeInterval?,
        notes: String?
    ) async {
        await workoutStore.updateExercise(
            in: workoutId,
            exerciseId: exercise.id,
            targetSets: targetSets,
            targetReps: targetReps,
            targetTime: targetTime,
            targetWeight: targetWeight,
            restTime: restTime,
            notes: notes
        )

        // Update local workout from store
        if let updatedWorkout = workoutStore.workouts.first(where: { $0.id == workoutId }) {
            workout = updatedWorkout
        }
    }

    /// Delete workout and navigate back
    private func deleteWorkout() async {
        await workoutStore.deleteWorkout(workoutId: workoutId)

        // Navigate back to home
        dismiss()
    }

    /// Move exercises (drag & drop reordering)
    private func moveExercises(from source: IndexSet, to destination: Int, in workout: Workout) {
        // Create new order based on move
        var sortedExercises = workout.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
        sortedExercises.move(fromOffsets: source, toOffset: destination)

        // Update orderIndex for all exercises
        for (index, var exercise) in sortedExercises.enumerated() {
            exercise.orderIndex = index
            sortedExercises[index] = exercise
        }

        // Optimistic UI update - update local workout immediately
        var updatedWorkout = workout
        updatedWorkout.exercises = sortedExercises
        self.workout = updatedWorkout

        // Extract IDs in new order
        let newOrder = sortedExercises.map { $0.id }

        // Update in backend
        Task {
            await workoutStore.reorderExercises(in: workoutId, exerciseIds: newOrder)

            // After store reloaded, update local workout from store
            if let refreshedWorkout = workoutStore.workouts.first(where: { $0.id == workoutId }) {
                self.workout = refreshedWorkout
            }
        }
    }
}

// MARK: - Stat Card (Modern iOS 26 Compact Design)

/// Modern compact stat card
private struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
                .lineLimit(1)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Exercise Card (Modern iOS 26 Compact Design)

/// Modern compact exercise card for workout detail
private struct ExerciseCard: View {
    let exercise: WorkoutExercise
    let exerciseName: String
    let orderNumber: Int

    var body: some View {
        HStack(spacing: 12) {
            // Order number badge
            Text("\(orderNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(Circle())

            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                Text(exerciseName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Stats in compact format
                HStack(spacing: 10) {
                    // Sets × Reps or Time
                    if let reps = exercise.targetReps {
                        Text("\(exercise.targetSets) × \(reps)")
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    } else if let time = exercise.targetTime {
                        Text("\(exercise.targetSets) × \(Int(time))s")
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }

                    // Weight
                    if let weight = exercise.targetWeight, weight > 0 {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(Int(weight)) kg")
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }

                    // Rest time
                    if let restTime = exercise.restTime {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(Int(restTime))s")
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
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
