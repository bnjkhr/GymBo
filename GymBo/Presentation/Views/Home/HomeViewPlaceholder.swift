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
    @State private var navigateToNewWorkout: Workout?  // For newly created workouts (opens ExercisePicker)
    @State private var navigateToExistingWorkout: Workout?  // For existing workouts (no auto-open)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header: Workouts + Button
                HStack(alignment: .center) {
                    Text("Workouts")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Spacer()

                    Button {
                        showCreateWorkout = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Neues Workout erstellen")
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color(.systemBackground))

                // Content
                ZStack(alignment: .top) {
                    Group {
                        if sessionStore.hasActiveSession {
                            // Show continue session button
                            continueSessionView
                        } else if let store = workoutStore {
                            // Show workout list
                            workoutListView(store: store)
                        } else {
                            // Loading state
                            ProgressView("Loading...")
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
            .onAppear {
                // Reload workouts every time view appears to catch updates
                Task {
                    if let store = workoutStore {
                        print("🔄 HomeView: Reloading workouts on appear")
                        await store.refresh()
                        // Copy to local @State to force SwiftUI update
                        let oldWorkouts = workouts
                        workouts = store.workouts
                        print("🔄 HomeView: Updated local workouts array, count=\(workouts.count)")
                        // Debug: Print all workout names
                        print("🔄 HomeView: OLD workouts: \(oldWorkouts.map { $0.name })")
                        print("🔄 HomeView: NEW workouts: \(workouts.map { $0.name })")
                    }
                }
            }
            .task {
                // Initial load
                await loadData()
                // Copy to local state
                if let store = workoutStore {
                    workouts = store.workouts
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
                LazyVStack(spacing: 12) {
                    // Favorites section
                    if !favoriteWorkouts.isEmpty {
                        sectionHeader(title: "Favoriten")

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
                            .padding(.top, favoriteWorkouts.isEmpty ? 0 : 8)

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
                .padding(.vertical, 12)
            }
        }
        .id(workouts.map { $0.name }.joined())  // Force view to recreate when names change
        .refreshable {
            await store.refresh()
            workouts = store.workouts  // Update local state on pull-to-refresh
        }
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
                // Header: Icon + Title + Favorite
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: "dumbbell.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)

                    // Title
                    Text(workout.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    // Favorite Star
                    if workout.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                    }
                }

                // Stats
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
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(CardButtonStyle())
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
