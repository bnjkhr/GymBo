//
//  SupersetWorkoutView.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V6 - Superset Training Feature
//

import SwiftUI

/// Main view for active superset workout session
///
/// **Features:**
/// - Timer section at top (rest timer / workout duration)
/// - Scrollable list of superset groups
/// - Each group shows paired exercises (A/B)
/// - Round progression tracking
/// - Workout completion message
///
/// **Design:**
/// - Same structure as ActiveWorkoutSheetView
/// - SupersetGroupCard components instead of CompactExerciseCard
/// - Optimized for paired exercise workflow
struct SupersetWorkoutView: View {

    // MARK: - Properties

    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var restTimerManager = RestTimerStateManager()

    @State private var showEndWorkoutConfirmation = false
    @State private var exerciseNames: [UUID: String] = [:]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Show workout UI only if active session exists
                if let session = sessionStore.currentSession {
                    VStack(spacing: 0) {
                        // Timer Section with black background extending to top
                        ZStack(alignment: .bottom) {
                            // Black background
                            Color.black
                                .ignoresSafeArea(edges: .top)

                            // Timer content (safe area respected for content)
                            TimerSection(
                                restTimerManager: restTimerManager,
                                workoutStartDate: session.startDate,
                                workoutName: session.workoutName,
                                currentExercise: currentGroupNumber(session: session),
                                totalExercises: session.exerciseGroups?.count ?? 0
                            )
                        }
                        .frame(height: 300)

                        // Superset Groups List (ScrollView)
                        if let groups = session.exerciseGroups, !groups.isEmpty {
                            groupsListView(groups: groups)
                        } else {
                            emptyGroupsView
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            groupCounterView(session: session)
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            endSessionButton
                        }
                    }
                } else {
                    // No session - dismiss sheet immediately
                    Color.clear
                        .onAppear {
                            dismiss()
                        }
                }
            }
            .interactiveDismissDisabled(false)
            .task(id: sessionStore.currentSession?.id) {
                await loadExerciseNames()
            }
            .onAppear {
                // Clear any leftover rest timer from previous workout
                restTimerManager.cancelRest()

                // Pass restTimerManager to SessionStore
                sessionStore.setRestTimerManager(restTimerManager)
            }
            .overlay(alignment: .top) {
                // Success Pill for notifications
                if let message = sessionStore.successMessage {
                    SuccessPill(message: message)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(duration: 0.3), value: sessionStore.successMessage)
                        .zIndex(1000)
                }
            }
        }
    }

    // MARK: - Helpers

    /// Get the current group number (1-based) - first incomplete group
    private func currentGroupNumber(session: DomainWorkoutSession) -> Int? {
        guard let groups = session.exerciseGroups else { return nil }

        // Find first group with incomplete round
        if let currentIndex = groups.firstIndex(where: { group in
            group.currentRound <= group.totalRounds
        }) {
            return currentIndex + 1  // 1-based
        }

        // All groups completed - return total count
        return groups.count
    }

    // MARK: - Subviews

    /// ScrollView with all superset groups
    private func groupsListView(groups: [SessionExerciseGroup]) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                    SupersetGroupCard(
                        group: group,
                        groupIndex: index,
                        exerciseNames: exerciseNames,
                        onToggleCompletion: { exerciseId, setId in
                            Task {
                                // Find the set BEFORE completing it (to get restTime)
                                let exercise = group.exercises.first(where: { $0.id == exerciseId })
                                let setRestTime = exercise?.sets.first(where: { $0.id == setId })?
                                    .restTime

                                // Complete the set using group-aware use case
                                await sessionStore.completeGroupSet(
                                    groupIndex: index,
                                    exerciseId: exerciseId,
                                    setId: setId
                                )

                                // Start rest timer
                                if let restTime = setRestTime {
                                    restTimerManager.startRest(duration: restTime)
                                }
                            }
                        },
                        onUpdateWeight: { exerciseId, setId, newWeight in
                            Task {
                                await sessionStore.updateGroupSet(
                                    groupIndex: index,
                                    exerciseId: exerciseId,
                                    setId: setId,
                                    weight: newWeight
                                )
                            }
                        },
                        onUpdateReps: { exerciseId, setId, newReps in
                            Task {
                                await sessionStore.updateGroupSet(
                                    groupIndex: index,
                                    exerciseId: exerciseId,
                                    setId: setId,
                                    reps: newReps
                                )
                            }
                        }
                    )
                    .padding(.horizontal, 12)
                    .padding(.top, index == 0 ? 12 : 0)
                }

                // Workout Complete Message
                if allGroupsCompleted(session: sessionStore.currentSession) {
                    workoutCompleteMessage
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                }
            }
            .padding(.bottom, 12)
        }
        .background(Color.black)
    }

    /// Empty state when no groups
    private var emptyGroupsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Keine Superset-Gruppen")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Dieses Workout enthält keine Superset-Gruppen")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }

    /// Group counter (e.g., "Gruppe 2 / 4")
    private func groupCounterView(session: DomainWorkoutSession) -> some View {
        let current = currentGroupNumber(session: session) ?? 0
        let total = session.exerciseGroups?.count ?? 0
        return Text("Gruppe \(current) / \(total)")
            .font(.headline)
            .monospacedDigit()
    }

    /// End session button with confirmation dialog
    private var endSessionButton: some View {
        Button {
            showEndWorkoutConfirmation = true
        } label: {
            Text("Beenden")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .confirmationDialog(
            "Workout beenden?",
            isPresented: $showEndWorkoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Workout beenden") {
                Task {
                    await sessionStore.endSession()
                }
            }

            Button("Workout abbrechen", role: .destructive) {
                Task {
                    await sessionStore.cancelSession()
                }
            }

            Button("Zurück", role: .cancel) {
                // Just dismiss the confirmation dialog
            }
        } message: {
            Text("Möchtest du das Workout speichern oder verwerfen?")
        }
    }

    /// Workout complete message
    private var workoutCompleteMessage: some View {
        VStack(spacing: 20) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.primary)

            // Title
            Text("Superset Workout abgeschlossen!")
                .font(.title2)
                .fontWeight(.bold)

            // Hint
            Text("Alle Runden abgeschlossen. Bereit zum Beenden?")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Finish Workout Button
            Button {
                showEndWorkoutConfirmation = true
            } label: {
                Text("Workout beenden")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    // MARK: - Helpers

    /// Check if all groups are completed
    private func allGroupsCompleted(session: DomainWorkoutSession?) -> Bool {
        guard let groups = session?.exerciseGroups else { return false }

        return groups.allSatisfy { group in
            group.currentRound > group.totalRounds
        }
    }

    /// Load exercise names for all exercises in all groups
    private func loadExerciseNames() async {
        guard let session = sessionStore.currentSession,
            let groups = session.exerciseGroups
        else { return }

        for group in groups {
            for exercise in group.exercises {
                let name = await sessionStore.getExerciseName(for: exercise.exerciseId)
                exerciseNames[exercise.exerciseId] = name
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
    #Preview("Superset Workout") {
        SupersetWorkoutView()
            .environment(SessionStore.previewWithSupersetSession)
    }
#endif
