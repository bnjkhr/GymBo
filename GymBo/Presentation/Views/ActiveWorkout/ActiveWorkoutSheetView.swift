//
//  ActiveWorkoutSheetView.swift
//  GymBo
//
//  Created on 2025-10-22.
//  V2 Clean Architecture - Active Workout Session UI (NEW SCROLLVIEW DESIGN)
//

import SwiftUI

/// Main view for active workout session - NEW DESIGN
///
/// **Features:**
/// - ScrollView showing ALL exercises (not TabView)
/// - Timer section at top (conditional - only when rest timer active)
/// - Eye icon to show/hide completed exercises
/// - Bottom action bar (fixed)
/// - Compact exercise cards
///
/// **Design Philosophy:**
/// - Workout overview (not one exercise at a time)
/// - Timer-centric (large, prominent when resting)
/// - Compact set rows for space efficiency
/// - Vertical scrolling through all exercises
struct ActiveWorkoutSheetView: View {

    // MARK: - Properties

    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var restTimerManager = RestTimerStateManager()

    @State private var showAllExercises = false
    @State private var showSummary = false
    @State private var completedSession: DomainWorkoutSession? = nil  // Store session for summary
    @State private var exerciseNames: [UUID: String] = [:]
    @State private var exerciseEquipment: [UUID: String] = [:]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Show workout UI if session exists OR if showing summary with completed session
                if let session = sessionStore.currentSession ?? completedSession {
                    VStack(spacing: 0) {
                        // Timer Section (ALWAYS visible)
                        TimerSection(
                            restTimerManager: restTimerManager,
                            workoutStartDate: session.startDate,
                            workoutName: session.workoutName
                        )

                        // Exercise List (ScrollView)
                        if !session.exercises.isEmpty {
                            exerciseListView()
                        } else {
                            emptyExercisesView
                        }

                        // Bottom Action Bar
                        BottomActionBar(
                            onRepeat: {
                                // TODO: Repeat last set
                            },
                            onAddExercise: {
                                // TODO: Add exercise
                            }
                        )
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            HStack(spacing: 16) {
                                eyeToggleButton
                                EditButton()
                            }
                        }

                        ToolbarItem(placement: .principal) {
                            exerciseCounterView(session: session)
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            endSessionButton
                        }
                    }
                } else {
                    noSessionView
                }
            }
            .sheet(isPresented: $showSummary) {
                ZStack {
                    if let session = completedSession {
                        WorkoutSummaryView(session: session) {
                            // Clear currentSession and dismiss
                            sessionStore.currentSession = nil
                            showSummary = false
                            dismiss()
                        }
                        .onAppear {
                            print("🔍 Sheet: Showing WorkoutSummaryView")
                        }
                    } else {
                        Text("No session data")
                            .onAppear {
                                print("❌ Sheet: completedSession is nil!")
                            }
                    }
                }
                .onAppear {
                    print(
                        "🔍 Sheet: showSummary is true, completedSession: \(completedSession?.id.uuidString ?? "nil")"
                    )
                }
            }
            .interactiveDismissDisabled(showSummary)  // Prevent swipe-to-dismiss while summary shown
            .task(id: sessionStore.currentSession?.id) {
                await loadExerciseNames()
            }
        }
    }

    // MARK: - Subviews

    /// ScrollView with all exercises (using List for drag & drop support)
    private func exerciseListView() -> some View {
        ZStack {
            if let session = sessionStore.currentSession {
                let sortedExercises = session.exercises.sorted { $0.orderIndex < $1.orderIndex }

                List {
                    ForEach(Array(sortedExercises.enumerated()), id: \.element.id) {
                        index, exercise in
                        // Hide exercise if it's finished (unless eye toggle is on)
                        let shouldHide = exercise.isFinished && !showAllExercises

                        if !shouldHide {
                            // Create unique ID based on exercise + all set states
                            let setsSignature = exercise.sets.map { "\($0.id)-\($0.completed)" }
                                .joined(separator: ",")

                            exerciseCardView(for: exercise, at: index, in: session)
                                .id("\(exercise.id)-\(setsSignature)")
                                .listRowInsets(
                                    EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .onMove { source, destination in
                        Task {
                            await sessionStore.reorderExercises(from: source, to: destination)
                        }
                    }

                    // Workout Complete Message (when all exercises completed)
                    if allExercisesCompleted(session: session) {
                        workoutCompleteMessage
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.gray.opacity(0.1))
                .animation(
                    .timingCurve(0.2, 0.0, 0.0, 1.0, duration: 0.3), value: showAllExercises)
            }
        }
    }

    /// Exercise card view with all callbacks
    @ViewBuilder
    private func exerciseCardView(
        for exercise: DomainSessionExercise,
        at index: Int,
        in session: DomainWorkoutSession
    ) -> some View {
        CompactExerciseCard(
            exercise: exercise,
            exerciseIndex: index,
            totalExercises: session.exercises.count,
            exerciseName: exerciseNames[exercise.exerciseId] ?? "Übung \(index + 1)",
            equipment: exerciseEquipment[exercise.exerciseId],
            onToggleCompletion: { setId in
                Task {
                    print(
                        "🔵 Set completion tapped: exercise \(index), setId \(setId)"
                    )

                    await sessionStore.completeSet(
                        exerciseId: exercise.id,
                        setId: setId
                    )

                    print("✅ Set marked complete")

                    // Start rest timer after EVERY set completion
                    // Use restTimeToNext from current exercise
                    if let restTime = exercise.restTimeToNext {
                        print("🔵 Starting rest timer: \(restTime) seconds")
                        restTimerManager.startRest(duration: restTime)
                        print("✅ Rest timer started successfully")
                    } else {
                        print("⚠️ No rest time configured for this exercise")
                    }
                }
            },
            onUpdateWeight: { setId, newWeight in
                Task {
                    print(
                        "✏️ Update weight: setId \(setId), newWeight \(newWeight)"
                    )
                    await sessionStore.updateSet(
                        exerciseId: exercise.id,
                        setId: setId,
                        weight: newWeight
                    )
                }
            },
            onUpdateReps: { setId, newReps in
                Task {
                    print("✏️ Update reps: setId \(setId), newReps \(newReps)")
                    await sessionStore.updateSet(
                        exerciseId: exercise.id,
                        setId: setId,
                        reps: newReps
                    )
                }
            },
            onUpdateAllSets: { weight, reps in
                Task {
                    print("✏️ Update all sets: weight=\(weight)kg, reps=\(reps)")
                    await sessionStore.updateAllSets(
                        exerciseId: exercise.id,
                        weight: weight,
                        reps: reps
                    )
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            },
            onAddSet: { weight, reps in
                Task {
                    print("➕ Add set: \(weight)kg x \(reps) reps")
                    await sessionStore.addSet(
                        exerciseId: exercise.id,
                        weight: weight,
                        reps: reps
                    )
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            },
            onRemoveSet: { setId in
                Task {
                    print("🗑️ Remove set: \(setId)")
                    await sessionStore.removeSet(
                        exerciseId: exercise.id,
                        setId: setId
                    )
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            },
            onMarkAllComplete: {
                Task {
                    await sessionStore.finishExercise(exerciseId: exercise.id)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        )
        .id(
            "\(exercise.id)-\(exercise.sets.map { "\($0.weight)-\($0.reps)-\($0.completed)" }.joined())"
        )
        .transition(
            .asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal: .opacity.combined(with: .move(edge: .top))
            ))
    }

    /// Eye toggle button for show/hide completed exercises
    private var eyeToggleButton: some View {
        Button {
            showAllExercises.toggle()
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            Image(systemName: showAllExercises ? "eye.fill" : "eye.slash.fill")
                .font(.title3)
                .foregroundStyle(showAllExercises ? .orange : .primary)
        }
    }

    /// Exercise counter (e.g., "1 / 14")
    private func exerciseCounterView(session: DomainWorkoutSession) -> some View {
        Text("\(session.completedSets) / \(session.totalSets)")
            .font(.headline)
            .monospacedDigit()
    }

    private var emptyExercisesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Keine Übungen")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Dieses Workout enthält keine Übungen")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }

    private var noSessionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Keine aktive Session")
                .font(.title2)
                .fontWeight(.semibold)

            Button("Schließen") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var endSessionButton: some View {
        Button {
            Task {
                // Save session before ending (for summary display)
                completedSession = sessionStore.currentSession
                await sessionStore.endSession()
                showSummary = true
            }
        } label: {
            Text("Beenden")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Helpers

    /// Check if all exercises are completed
    private func allExercisesCompleted(session: DomainWorkoutSession) -> Bool {
        let allCompleted = session.exercises.allSatisfy { exercise in
            exercise.sets.allSatisfy { $0.completed }
        }
        print("🔍 allExercisesCompleted: \(allCompleted)")
        print("   - Total exercises: \(session.exercises.count)")
        for (index, exercise) in session.exercises.enumerated() {
            let completedSets = exercise.sets.filter { $0.completed }.count
            print("   - Exercise \(index): \(completedSets)/\(exercise.sets.count) sets completed")
        }
        return allCompleted
    }

    /// Workout complete message with hint and button
    private var workoutCompleteMessage: some View {
        VStack(spacing: 20) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.primary)

            // Title
            Text("Workout abgeschlossen!")
                .font(.title2)
                .fontWeight(.bold)

            // Hint about Eye icon
            HStack(spacing: 8) {
                Image(systemName: "eye.fill")
                    .foregroundColor(.primary)
                Text("Tippe auf das Auge-Symbol oben, um alle Übungen zu sehen")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            // Finish Workout Button
            Button {
                Task {
                    // Save session before ending (for summary display)
                    completedSession = sessionStore.currentSession
                    print(
                        "🔍 Button: completedSession saved: \(completedSession?.id.uuidString ?? "nil")"
                    )

                    await sessionStore.endSession()
                    print("🔍 Button: endSession completed")
                    print(
                        "🔍 Button: currentSession is now: \(sessionStore.currentSession?.id.uuidString ?? "nil")"
                    )

                    showSummary = true
                    print("🔍 Button: showSummary set to true")
                }
            } label: {
                Text("Workout beenden")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    /// Load exercise names and equipment for all exercises in the session
    private func loadExerciseNames() async {
        guard let session = sessionStore.currentSession else { return }

        for exercise in session.exercises {
            let name = await sessionStore.getExerciseName(for: exercise.exerciseId)
            exerciseNames[exercise.exerciseId] = name

            if let equipment = await sessionStore.getExerciseEquipment(for: exercise.exerciseId) {
                exerciseEquipment[exercise.exerciseId] = equipment
            }
        }
    }
}

// MARK: - Workout Summary View

/// Summary view shown after workout completion
struct WorkoutSummaryView: View {

    let session: DomainWorkoutSession
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                // Title
                Text("Workout abgeschlossen!")
                    .font(.title)
                    .fontWeight(.bold)

                // Stats
                VStack(spacing: 16) {
                    summaryRow(
                        icon: "clock",
                        label: "Dauer",
                        value: session.formattedDuration
                    )

                    summaryRow(
                        icon: "checkmark.circle",
                        label: "Sets",
                        value: "\(session.completedSets)/\(session.totalSets)"
                    )

                    summaryRow(
                        icon: "flame",
                        label: "Übungen",
                        value: "\(session.exercises.count)"
                    )

                    if session.totalVolume > 0 {
                        summaryRow(
                            icon: "scalemass",
                            label: "Volumen",
                            value: String(format: "%.0f kg", session.totalVolume)
                        )
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(16)

                Spacer()

                // Done button
                Button(action: onDismiss) {
                    Text("Fertig")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Zusammenfassung")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30)

            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Preview

#Preview("Active Workout - New Design") {
    ActiveWorkoutSheetView()
        .environment(SessionStore.previewWithSession)
}

#Preview("Summary") {
    WorkoutSummaryView(session: .preview) {
        print("Dismissed")
    }
}
