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
    @State private var showReorderSheet = false
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
                            workoutName: session.workoutName,
                            currentExercise: currentExerciseNumber(session: session),
                            totalExercises: session.exercises.count
                        )

                        // Exercise List (ScrollView)
                        if !session.exercises.isEmpty {
                            exerciseListView()
                        } else {
                            emptyExercisesView
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            HStack(spacing: 16) {
                                eyeToggleButton
                                reorderButton
                                addExerciseButton
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
            .sheet(isPresented: $showReorderSheet) {
                if let session = sessionStore.currentSession {
                    ReorderExercisesSheet(
                        exercises: session.exercises.sorted { $0.orderIndex < $1.orderIndex },
                        exerciseNames: exerciseNames,
                        workoutId: session.workoutId,
                        onReorder: { reorderedExercises, savePermanently in
                            Task {
                                await sessionStore.reorderExercises(
                                    reorderedExercises: reorderedExercises,
                                    savePermanently: savePermanently
                                )
                            }
                        }
                    )
                }
            }
            .interactiveDismissDisabled(showSummary)  // Prevent swipe-to-dismiss while summary shown
            .task(id: sessionStore.currentSession?.id) {
                await loadExerciseNames()
            }
            .onAppear {
                // Clear any leftover rest timer from previous workout
                restTimerManager.cancelRest()
            }
            .overlay(alignment: .top) {
                // Success Pill for notifications (e.g., "Nächste Übung")
                if let message = sessionStore.successMessage {
                    SuccessPill(message: message)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(duration: 0.3), value: sessionStore.successMessage)
                        .zIndex(1000)  // Above all other content
                }
            }
        }
    }

    // MARK: - Helpers

    /// Get the current exercise number (1-based) - first incomplete exercise
    private func currentExerciseNumber(session: DomainWorkoutSession) -> Int? {
        let sortedExercises = session.exercises.sorted { $0.orderIndex < $1.orderIndex }

        // Find first incomplete exercise
        if let currentIndex = sortedExercises.firstIndex(where: { !$0.isCompleted }) {
            return currentIndex + 1  // 1-based
        }

        // All exercises completed - return total count
        return sortedExercises.count
    }

    // MARK: - Subviews

    /// ScrollView with all exercises (REPLACED List to fix drag-and-drop button bug)
    private func exerciseListView() -> some View {
        ZStack {
            if let session = sessionStore.currentSession {
                let sortedExercises = session.exercises.sorted { $0.orderIndex < $1.orderIndex }

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(sortedExercises.enumerated()), id: \.element.id) {
                            index, exercise in
                            // Hide exercise if it's finished (unless eye toggle is on)
                            let shouldHide = exercise.isFinished && !showAllExercises

                            if !shouldHide {
                                // Create unique ID based on exercise + set IDs only (not completion status)
                                // This ensures view updates on set add/remove but NOT on completion toggle
                                let setsSignature = exercise.sets.map { $0.id.uuidString }.joined(
                                    separator: ",")

                                exerciseCardView(for: exercise, at: index, in: session)
                                    .id("\(exercise.id)-\(setsSignature)")
                                    .padding(.horizontal, 12)
                            }
                        }

                        // Workout Complete Message (when all exercises completed)
                        if allExercisesCompleted(session: session) {
                            workoutCompleteMessage
                                .padding(.horizontal, 12)
                        }
                    }
                    .padding(.vertical, 4)
                }
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
            },
            onReorder: {
                showReorderSheet = true
                UISelectionFeedbackGenerator().selectionChanged()
            }
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
            Image(
                systemName: showAllExercises
                    ? "eye" : "eye.slash"
            )
            .font(.title3)
            .foregroundStyle(showAllExercises ? .orange : .primary)
        }
    }

    /// Reorder button to open reorder sheet
    private var reorderButton: some View {
        Button {
            showReorderSheet = true
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.title3)
                .foregroundStyle(.primary)
        }
    }

    /// Add exercise button
    private var addExerciseButton: some View {
        Button {
            // TODO: Add exercise functionality
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            Image(systemName: "plus.circle")
                .font(.title3)
                .foregroundStyle(.orange)
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

            // Hint about List icon
            Text("Tippe auf die Übersicht oben, um alle Übungen zu sehen")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
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

// MARK: - Reorder Exercises Sheet

/// Separate sheet for reordering exercises
/// Uses List with drag-and-drop in isolation to avoid button auto-trigger bug
struct ReorderExercisesSheet: View {

    let exercises: [DomainSessionExercise]
    let exerciseNames: [UUID: String]
    let workoutId: UUID
    let onReorder: ([DomainSessionExercise], Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var localExercises: [DomainSessionExercise]
    @State private var savePermanently = false

    init(
        exercises: [DomainSessionExercise],
        exerciseNames: [UUID: String],
        workoutId: UUID,
        onReorder: @escaping ([DomainSessionExercise], Bool) -> Void
    ) {
        self.exercises = exercises
        self.exerciseNames = exerciseNames
        self.workoutId = workoutId
        self.onReorder = onReorder
        self._localExercises = State(initialValue: exercises)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Toggle for permanent save
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $savePermanently) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reihenfolge dauerhaft speichern")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Ändert die Reihenfolge auch im Workout-Template")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.orange)
                }
                .padding()
                .background(Color(.systemGroupedBackground))

                Divider()

                // Exercise list
                List {
                    ForEach(Array(localExercises.enumerated()), id: \.element.id) {
                        index, exercise in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exerciseNames[exercise.exerciseId] ?? "Übung \(index + 1)")
                                    .font(.headline)

                                Text("\(exercise.sets.count) Sätze")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            // Order indicator
                            Text("\(index + 1)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 30, height: 30)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove { source, destination in
                        localExercises.move(fromOffsets: source, toOffset: destination)
                    }
                }
                .environment(\.editMode, .constant(.active))
            }
            .navigationTitle("Übungen sortieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        onReorder(localExercises, savePermanently)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
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
