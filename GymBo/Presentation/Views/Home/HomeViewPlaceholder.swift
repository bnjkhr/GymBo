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
    @State private var showActiveWorkout = false
    @State private var showWorkoutSummary = false

    var body: some View {
        NavigationStack {
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
            .navigationTitle("Workouts")
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
            .task {
                await loadData()
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
        List {
            if store.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if store.workouts.isEmpty {
                ContentUnavailableView(
                    "Keine Workouts",
                    systemImage: "dumbbell",
                    description: Text("Erstelle dein erstes Workout")
                )
            } else {
                // Favorites section
                if !store.favoriteWorkouts.isEmpty {
                    Section("Favoriten") {
                        ForEach(store.favoriteWorkouts) { workout in
                            NavigationLink {
                                WorkoutDetailView(workout: workout) {
                                    startWorkout(workout)
                                }
                            } label: {
                                WorkoutRowContent(workout: workout)
                            }
                        }
                    }
                }

                // Regular workouts
                if !store.regularWorkouts.isEmpty {
                    Section("Alle Workouts") {
                        ForEach(store.regularWorkouts) { workout in
                            NavigationLink {
                                WorkoutDetailView(workout: workout) {
                                    startWorkout(workout)
                                }
                            } label: {
                                WorkoutRowContent(workout: workout)
                            }
                        }
                    }
                }
            }
        }
        .refreshable {
            await store.refresh()
        }
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

// MARK: - Workout Row Content

private struct WorkoutRowContent: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: workout.isFavorite ? "star.fill" : "dumbbell.fill")
                .font(.title2)
                .foregroundColor(workout.isFavorite ? .yellow : .orange)
                .frame(width: 40)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 12) {
                    Label(
                        "\(workout.exerciseCount)",
                        systemImage: "figure.strengthtraining.traditional")
                    Label("\(workout.totalSets)", systemImage: "list.bullet")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    HomeViewPlaceholder()
        .environment(SessionStore.preview)
}
