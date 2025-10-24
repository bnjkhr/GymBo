//
//  HomeViewPlaceholder.swift
//  GymTracker
//
//  Created on 2025-10-22.
//  V2 Clean Architecture - Home View with Workout Picker
//  Updated on 2025-10-23 - Added Workout Selection
//

import SwiftUI

/// Home view with workout selection
///
/// **Features:**
/// - Workout list with favorites
/// - Start workout button
/// - Continue active session
struct HomeViewPlaceholder: View {

    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dependencyContainer) private var dependencyContainer
    @State private var workoutStore: WorkoutStore?
    @State private var workouts: [Workout] = []  // LOCAL state instead of store
    @State private var showActiveWorkout = false
    @State private var showWorkoutSummary = false
    @State private var showCreateWorkout = false
    @State private var showProfile = false
    @State private var showLockerInput = false
    @State private var navigateToNewWorkout: Workout?  // For newly created workouts (opens ExercisePicker)
    @State private var navigateToExistingWorkout: Workout?  // For existing workouts (no auto-open)
    @State private var workoutsHash: Int = 0  // Performance: Cache workout list hash

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Content
                Group {
                    if sessionStore.hasActiveSession {
                        // Show continue session button (no scroll needed)
                        VStack(spacing: 0) {
                            GreetingHeaderView(
                                showProfile: $showProfile,
                                showLockerInput: $showLockerInput
                            )
                            continueSessionView
                        }
                    } else if let store = workoutStore {
                        // Show workout list with integrated header
                        workoutListView(store: store)
                    } else {
                        // Loading state
                        VStack(spacing: 0) {
                            GreetingHeaderView(
                                showProfile: $showProfile,
                                showLockerInput: $showLockerInput
                            )
                            ProgressView("Loading...")
                        }
                    }
                }

                // Success Pill Overlay
                if let store = workoutStore, store.showSuccessPill,
                    let message = store.successMessage
                {
                    SuccessPill(message: message)
                        .padding(.top, 8)
                        .zIndex(1000)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCreateWorkout) {
                if let store = workoutStore {
                    CreateWorkoutView { createdWorkout in
                        // Navigate to the created workout's detail view
                        navigateToNewWorkout = createdWorkout
                    }
                    .environment(store)
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showLockerInput) {
                LockerNumberInputSheet()
            }
            // Navigation for NEWLY created workouts (opens ExercisePicker automatically)
            .navigationDestination(item: $navigateToNewWorkout) { workout in
                if let store = workoutStore {
                    WorkoutDetailView(
                        workout: workout,
                        onStartWorkout: {
                            Task {
                                await sessionStore.startSession(workoutId: workout.id)
                                showActiveWorkout = true
                            }
                        },
                        openExercisePickerOnAppear: true
                    )
                    .environment(store)
                }
            }
            // Navigation for EXISTING workouts (no auto-open)
            .navigationDestination(item: $navigateToExistingWorkout) { workout in
                if let store = workoutStore {
                    WorkoutDetailView(
                        workout: workout,
                        onStartWorkout: {
                            Task {
                                await sessionStore.startSession(workoutId: workout.id)
                                showActiveWorkout = true
                            }
                        },
                        openExercisePickerOnAppear: false
                    )
                    .environment(store)
                }
            }
            .sheet(isPresented: $showActiveWorkout) {
                if sessionStore.hasActiveSession {
                    ActiveWorkoutSheetView()
                        .environment(workoutStore)
                }
            }
            .sheet(isPresented: $showWorkoutSummary) {
                if let completedSession = sessionStore.completedSession {
                    WorkoutSummaryView(session: completedSession) {
                        // Clear completed session and dismiss
                        sessionStore.completedSession = nil
                        showWorkoutSummary = false
                    }
                }
            }
            .onChange(of: sessionStore.completedSession) { oldValue, newValue in
                // Show summary sheet when a session is completed
                showWorkoutSummary = (newValue != nil)
            }
            .onChange(of: workoutStore?.workouts) { oldValue, newValue in
                // Sync local workouts array when store changes (e.g., favorite toggle)
                if let updatedWorkouts = newValue {
                    print("🔄 HomeView: WorkoutStore changed, syncing local array")
                    workouts = updatedWorkouts
                    updateWorkoutsHash()
                }
            }
            .onAppear {
                // Reload workouts every time view appears to catch updates
                Task {
                    if let store = workoutStore {
                        print("🔄 HomeView: Reloading workouts on appear")
                        await store.refresh()
                        // Copy to local @State to force SwiftUI update
                        workouts = store.workouts
                        updateWorkoutsHash()
                        print("🔄 HomeView: Updated local workouts array, count=\(workouts.count)")
                    }
                }
            }
            .task {
                // Initial load
                await loadData()
                // Copy to local state
                if let store = workoutStore {
                    workouts = store.workouts
                    updateWorkoutsHash()
                }
            }
        }
    }

    // MARK: - Subviews

    private var continueSessionView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 64))
                    .foregroundColor(.green)

                Text("Training läuft")
                    .font(.title)
                    .fontWeight(.bold)

                Button(action: { showActiveWorkout = true }) {
                    Label("Training fortsetzen", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
    }

    private func workoutListView(store: WorkoutStore) -> some View {
        let favoriteWorkouts = workouts.filter { $0.isFavorite }
        let regularWorkouts = workouts.filter { !$0.isFavorite }

        return ScrollView {
            VStack(spacing: 0) {
                if store.isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if workouts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("Keine Workouts")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Erstelle dein erstes Workout")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                } else {
                    // Workouts Section
                    VStack(spacing: 0) {
                        // Section Header
                        HStack {
                            Text("Workouts")
                                .font(.title3)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                        // Create New Workout Button (below header, left aligned)
                        createWorkoutButton
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)

                        LazyVStack(spacing: 12) {

                            // Favorites section
                            if !favoriteWorkouts.isEmpty {
                                sectionHeader(title: "Favoriten")
                                    .padding(.top, 8)

                                ForEach(favoriteWorkouts) { workout in
                                    WorkoutCard(workout: workout, store: store) {
                                        navigateToWorkout(workout, store: store)
                                    } onStart: {
                                        startWorkout(workout)
                                    }
                                }
                            }

                            // Regular workouts
                            if !regularWorkouts.isEmpty {
                                sectionHeader(title: "Alle Workouts")
                                    .padding(.top, favoriteWorkouts.isEmpty ? 8 : 8)

                                ForEach(regularWorkouts) { workout in
                                    WorkoutCard(workout: workout, store: store) {
                                        navigateToWorkout(workout, store: store)
                                    } onStart: {
                                        startWorkout(workout)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                }
            }
        }
        .refreshable {
            await store.refresh()
            workouts = store.workouts  // Update local state on pull-to-refresh
            updateWorkoutsHash()
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            // Fixed Header (stays visible while scrolling)
            VStack(spacing: 0) {
                // Greeting Header
                GreetingHeaderView(
                    showProfile: $showProfile,
                    showLockerInput: $showLockerInput
                )

                // Workout Calendar Strip
                WorkoutCalendarStripView()
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
            }
            .background(Color(.systemBackground))
        }
        .id(workoutsHash)  // Force view to recreate when workouts change (using cached hash)
    }

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }

    private var createWorkoutButton: some View {
        Button {
            showCreateWorkout = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.body)

                Text("Neues Workout erstellen")
                    .font(.body)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func navigateToWorkout(_ workout: Workout, store: WorkoutStore) {
        navigateToExistingWorkout = workout  // Use existing workout navigation (no auto-open)
    }

    // MARK: - Actions

    private func loadData() async {
        // Initialize workout store if needed
        if workoutStore == nil, let container = dependencyContainer {
            workoutStore = container.makeWorkoutStore()
        }

        // Load active session
        await sessionStore.loadActiveSession()

        // Load workouts if no active session
        if !sessionStore.hasActiveSession, let store = workoutStore {
            await store.loadWorkouts()
        }
    }

    private func startWorkout(_ workout: Workout) {
        Task {
            await sessionStore.startSession(workoutId: workout.id)

            if sessionStore.hasActiveSession {
                showActiveWorkout = true
            }
        }
    }

    // MARK: - Performance Helpers

    private func updateWorkoutsHash() {
        // Simple hash based on count and names (faster than joined string)
        var hasher = Hasher()
        hasher.combine(workouts.count)
        for workout in workouts {
            hasher.combine(workout.name)
            hasher.combine(workout.isFavorite)
        }
        workoutsHash = hasher.finalize()
    }
}

// MARK: - Workout Card (Modern iOS 26 Design)

private struct WorkoutCard: View {
    let workout: Workout
    let store: WorkoutStore
    let onTap: () -> Void
    let onStart: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Title + Favorite
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Title
                        Text(workout.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        // Equipment Type
                        if let equipmentType = workout.equipmentType {
                            Text(equipmentType)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Favorite Star
                    if workout.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                    }
                }

                // Stats & Difficulty
                HStack(spacing: 16) {
                    Label {
                        Text("\(workout.exerciseCount)")
                            .font(.subheadline)
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    Label {
                        Text("\(workout.totalSets)")
                            .font(.subheadline)
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "list.bullet")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    Spacer()

                    // Difficulty Badge
                    if let difficulty = workout.difficultyLevel {
                        difficultyBadge(for: difficulty)
                    }
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(CardButtonStyle())
    }

    // MARK: - Difficulty Badge

    @ViewBuilder
    private func difficultyBadge(for level: String) -> some View {
        let (color, icon) = difficultyStyle(for: level)

        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(level)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }

    private func difficultyStyle(for level: String) -> (Color, String) {
        switch level {
        case "Anfänger":
            return (.green, "leaf.fill")
        case "Fortgeschritten":
            return (.orange, "flame.fill")
        case "Profi":
            return (.red, "bolt.fill")
        default:
            return (.gray, "circle.fill")
        }
    }
}

// MARK: - Card Button Style (iOS 26 Press Effect)

private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    HomeViewPlaceholder()
        .environment(SessionStore.preview)
}
