//
//  HomeView.swift
//  GymTracker
//
//  Created on 2025-10-22.
//  V2 Clean Architecture - Home View with Workout Picker
//  Updated on 2025-10-23 - Added Workout Selection
//

import SwiftUI

// MARK: - Quick-Setup Preview Data

struct QuickSetupPreviewData: Identifiable {
    let id = UUID()
    let config: QuickSetupConfig
    let exercises: [WorkoutExercise]
    let allExercises: [ExerciseEntity]
}

// MARK: - Home View

/// Home view with workout selection
///
/// **Features:**
/// - Workout list with favorites
/// - Start workout button
/// - Continue active session
struct HomeView: View {

    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dependencyContainer) private var dependencyContainer
    @State private var workoutStore: WorkoutStore?
    @State private var workouts: [Workout] = []  // LOCAL state instead of store
    @State private var folders: [WorkoutFolder] = []  // LOCAL state for folders
    @State private var showActiveWorkout = false
    @State private var showWorkoutSummary = false
    @State private var showCreateWorkout = false
    @State private var showCreateWorkoutDirect = false
    @State private var showQuickSetup = false
    @State private var quickSetupPreviewData: QuickSetupPreviewData? = nil
    @State private var allExercises: [ExerciseEntity] = []
    @State private var showProfile = false
    @State private var showLockerInput = false
    @State private var navigateToNewWorkout: Workout?  // For newly created workouts (opens ExercisePicker)
    @State private var navigateToExistingWorkout: Workout?  // For existing workouts (no auto-open)
    @State private var workoutsHash: Int = 0  // Performance: Cache workout list hash
    @State private var isFavoritesExpanded = true  // Collapsible Favoriten section
    @State private var isAllWorkoutsExpanded = true  // Collapsible Alle Workouts section
    @State private var folderExpandedState: [UUID: Bool] = [:]  // Track expansion for each folder
    @State private var showManageFolders = false  // Sheet for managing folders
    @State private var foldersUpdateTrigger = 0  // Force view update when folders change

    var body: some View {
        NavigationStack {
            // Content (no ZStack wrapping)
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
                        .overlay(alignment: .top) {
                            // Success Pill Overlay
                            if store.showSuccessPill, let message = store.successMessage {
                                SuccessPill(message: message)
                                    .padding(.top, 8)
                            }
                        }
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
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCreateWorkout) {
                WorkoutCreationModeSheet(
                    onSelectEmpty: {
                        showCreateWorkoutDirect = true
                    },
                    onSelectQuickSetup: {
                        showQuickSetup = true
                    },
                    onSelectWizard: {
                        // Coming soon
                    }
                )
            }
            .sheet(isPresented: $showCreateWorkoutDirect) {
                if let store = workoutStore {
                    CreateWorkoutView { createdWorkout in
                        // Navigate to the created workout's detail view
                        navigateToNewWorkout = createdWorkout
                    }
                    .environment(store)
                }
            }
            .sheet(isPresented: $showQuickSetup) {
                QuickSetupView { config in
                    // Dismiss this sheet first
                    showQuickSetup = false

                    // Generate workout exercises from config
                    Task {
                        await handleQuickSetupGeneration(config: config)
                    }
                }
            }
            .sheet(item: $quickSetupPreviewData) { previewData in
                if let store = workoutStore {
                    QuickSetupPreviewView(
                        config: previewData.config,
                        generatedExercises: previewData.exercises,
                        allExercises: previewData.allExercises,
                        onSave: { name, exercises in
                            Task {
                                await saveQuickSetupWorkout(name: name, exercises: exercises)
                            }
                        }
                    )
                    .environment(store)
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(
                    userProfileRepository: dependencyContainer.makeUserProfileRepository(),
                    importBodyMetricsUseCase: dependencyContainer.makeImportBodyMetricsUseCase()
                )
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
            .onChange(of: showActiveWorkout) { oldValue, newValue in
                // When Active Workout sheet is dismissed, reload workouts
                if !newValue && oldValue {
                    Task {
                        if let store = workoutStore {
                            await store.refresh()
                            workouts = store.workouts
                            updateWorkoutsHash()
                        }
                    }
                }
            }
            .onChange(of: workoutStore?.workouts) { oldValue, newValue in
                // Sync local workouts array when store changes (e.g., favorite toggle, folder deletion)
                if let updatedWorkouts = newValue {
                    workouts = updatedWorkouts
                    updateWorkoutsHash()
                }
            }
            .onChange(of: workoutStore?.folders) { oldValue, newValue in
                // Sync local folders array when store changes (e.g., folder deletion)
                if let updatedFolders = newValue {
                    folders = updatedFolders
                    foldersUpdateTrigger += 1
                }
            }
            .onAppear {
                // Reload workouts every time view appears to catch updates
                Task {
                    if let store = workoutStore {
                        await store.refresh()
                        // Copy to local @State to force SwiftUI update
                        workouts = store.workouts
                        updateWorkoutsHash()
                    }
                }
            }
            .task {
                // Initial load
                await loadData()
                // Copy to local state
                if let store = workoutStore {
                    workouts = store.workouts
                    folders = store.folders
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

        return VStack(spacing: 0) {
            // Fixed Header (outside ScrollView, like ExercisesView)
            GreetingHeaderView(
                showProfile: $showProfile,
                showLockerInput: $showLockerInput
            )

            // Workout Calendar Strip (outside ScrollView, like ExercisesView)
            WorkoutCalendarStripView()
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)

            // Scrollable Content (like exerciseList in ExercisesView)
            if store.isLoading {
                ProgressView("Lade Workouts...")
                    .frame(maxHeight: .infinity)
            } else if workouts.isEmpty {
                emptyWorkoutState
            } else {
                workoutScrollView(
                    store: store, favoriteWorkouts: favoriteWorkouts,
                    regularWorkouts: regularWorkouts)
            }
        }
        .id(workoutsHash)
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    private var emptyWorkoutState: some View {
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
        .frame(maxHeight: .infinity)
        .padding()
    }

    private func workoutScrollView(
        store: WorkoutStore, favoriteWorkouts: [Workout], regularWorkouts: [Workout]
    ) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Workouts Section
                VStack(spacing: 0) {
                    // Section Header with Plus Button and Manage Categories
                    HStack {
                        Text("Workouts")
                            .font(.title3)
                            .fontWeight(.bold)

                        Spacer()

                        // Manage folders button
                        Button {
                            showManageFolders = true
                        } label: {
                            Image(systemName: "folder")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showCreateWorkout = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .padding(.bottom, 16)

                    LazyVStack(spacing: 12) {

                        // Favorites section
                        if !favoriteWorkouts.isEmpty {
                            collapsibleSectionHeader(
                                title: "Favoriten",
                                isExpanded: $isFavoritesExpanded
                            )
                            .padding(.top, 8)

                            if isFavoritesExpanded {
                                ForEach(favoriteWorkouts) { workout in
                                    WorkoutCard(workout: workout, store: store) {
                                        navigateToWorkout(workout, store: store)
                                    } onStart: {
                                        startWorkout(workout)
                                    }
                                    .contextMenu {
                                        workoutContextMenu(workout: workout)
                                    }
                                }
                            }
                        }

                        // Folder sections
                        ForEach(folders) { folder in
                            let folderWorkouts = workouts.filter { $0.folderId == folder.id }
                            if !folderWorkouts.isEmpty {
                                let isExpanded = folderExpandedState[folder.id] ?? true

                                collapsibleFolderHeader(
                                    folder: folder,
                                    isExpanded: Binding(
                                        get: { folderExpandedState[folder.id] ?? true },
                                        set: { folderExpandedState[folder.id] = $0 }
                                    )
                                )
                                .padding(.top, 8)

                                if isExpanded {
                                    ForEach(folderWorkouts) { workout in
                                        WorkoutCard(workout: workout, store: store) {
                                            navigateToWorkout(workout, store: store)
                                        } onStart: {
                                            startWorkout(workout)
                                        }
                                        .contextMenu {
                                            workoutContextMenu(workout: workout)
                                        }
                                    }
                                }
                            }
                        }

                        // Uncategorized workouts (no folder)
                        let uncategorizedWorkouts = regularWorkouts.filter { $0.folderId == nil }
                        if !uncategorizedWorkouts.isEmpty {
                            collapsibleSectionHeader(
                                title: "Ohne Kategorie",
                                isExpanded: $isAllWorkoutsExpanded
                            )
                            .padding(
                                .top, favoriteWorkouts.isEmpty && store.folders.isEmpty ? 8 : 8)

                            if isAllWorkoutsExpanded {
                                ForEach(uncategorizedWorkouts) { workout in
                                    WorkoutCard(workout: workout, store: store) {
                                        navigateToWorkout(workout, store: store)
                                    } onStart: {
                                        startWorkout(workout)
                                    }
                                    .contextMenu {
                                        workoutContextMenu(workout: workout)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .refreshable {
            await store.refresh()
            workouts = store.workouts  // Update local state on pull-to-refresh
            updateWorkoutsHash()
        }
        .sheet(isPresented: $showManageFolders) {
            ManageFoldersSheet()
                .environment(store)
        }
        .onChange(of: showManageFolders) { oldValue, newValue in
            // Reload folders and workouts when ManageFolders sheet is dismissed
            if !newValue && oldValue {
                Task {
                    await store.loadFolders()
                    await store.loadWorkouts()  // Also reload workouts in case folder was deleted
                    folders = store.folders  // Copy to local state
                    workouts = store.workouts  // Copy to local state
                    foldersUpdateTrigger += 1  // Force view update
                    updateWorkoutsHash()
                    print(
                        "🔄 HomeView: Folders and workouts reloaded after ManageFolders sheet dismissed, trigger=\(foldersUpdateTrigger), folders=\(folders.count), workouts=\(workouts.count)"
                    )
                }
            }
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

    private func collapsibleSectionHeader(title: String, isExpanded: Binding<Bool>) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.wrappedValue.toggle()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))

                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    // MARK: - Folder Header

    private func collapsibleFolderHeader(folder: WorkoutFolder, isExpanded: Binding<Bool>)
        -> some View
    {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.wrappedValue.toggle()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack {
                // Color indicator
                Circle()
                    .fill(Color(hex: folder.color) ?? .purple)
                    .frame(width: 12, height: 12)

                Text(folder.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))

                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func workoutContextMenu(workout: Workout) -> some View {
        // Move to folder submenu
        Menu("Verschieben nach...") {
            Button {
                Task {
                    await workoutStore?.moveWorkoutToFolder(workoutId: workout.id, folderId: nil)
                    // Reload local workouts after move
                    if let store = workoutStore {
                        workouts = store.workouts
                        updateWorkoutsHash()
                    }
                }
            } label: {
                Label("Ohne Kategorie", systemImage: "folder.badge.minus")
            }

            ForEach(folders) { folder in
                Button {
                    Task {
                        await workoutStore?.moveWorkoutToFolder(
                            workoutId: workout.id, folderId: folder.id)
                        // Reload local workouts after move
                        if let store = workoutStore {
                            workouts = store.workouts
                            updateWorkoutsHash()
                            print(
                                "🔄 HomeView: Workouts reloaded after moving to folder '\(folder.name)'"
                            )
                        }
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(Color(hex: folder.color) ?? .purple)
                            .frame(width: 12, height: 12)
                        Text(folder.name)
                    }
                }
            }
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

        // Load workouts and folders if no active session
        if !sessionStore.hasActiveSession, let store = workoutStore {
            await store.loadWorkouts()
            await store.loadFolders()
            folders = store.folders  // Copy to local state
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

    // MARK: - Quick-Setup Helpers

    /// Generate workout exercises from Quick-Setup config
    private func handleQuickSetupGeneration(config: QuickSetupConfig) async {
        guard let container = dependencyContainer else { return }

        do {
            // Load all exercises for picker
            let exerciseRepo = container.makeExerciseRepository()
            allExercises = try await exerciseRepo.fetchAll()

            // Generate workout exercises
            let useCase = container.makeQuickSetupWorkoutUseCase()
            let generatedExercises = try await useCase.generateWorkoutExercises(config: config)

            // Create preview data and show sheet (ensure on main thread)
            await MainActor.run {
                quickSetupPreviewData = QuickSetupPreviewData(
                    config: config,
                    exercises: generatedExercises,
                    allExercises: allExercises
                )
            }
        } catch {
            print("❌ Quick-Setup generation error: \(error)")
        }
    }

    /// Save Quick-Setup workout
    private func saveQuickSetupWorkout(name: String, exercises: [WorkoutExercise]) async {
        guard let store = workoutStore else { return }

        do {
            // 1. Create empty workout
            let workout = try await store.createWorkout(name: name)

            // 2. Add all exercises to the workout
            for exercise in exercises {
                await store.addExercise(exerciseId: exercise.exerciseId, to: workout.id)
            }

            // 3. Refresh workout list
            await store.refresh()
            workouts = store.workouts
            updateWorkoutsHash()

        } catch {
            print("❌ Failed to save Quick-Setup workout: \(error)")
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
                // Header: Title + Favorite
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Title
                        Text(workout.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        // Equipment Type Icons
                        if let equipmentType = workout.equipmentType {
                            equipmentIcons(for: equipmentType)
                        }
                    }

                    Spacer()

                    // Favorite Star
                    if workout.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.subheadline)
                            .foregroundColor(.appOrange)
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
            return (Color(.systemGray2), "leaf.fill")
        case "Fortgeschritten":
            return (Color(.systemGray), "flame.fill")
        case "Profi":
            return (Color(.darkGray), "bolt.fill")
        default:
            return (.gray, "circle.fill")
        }
    }

    // MARK: - Equipment Icons

    @ViewBuilder
    private func equipmentIcons(for equipmentType: String) -> some View {
        HStack(spacing: 4) {
            if equipmentType.lowercased() == "gemischt" {
                // For mixed workouts, show all equipment types present
                // For now, show all icons as we don't have exercise details here
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "figure.hand.cycling")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // Single equipment type
                Image(systemName: equipmentIcon(for: equipmentType))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func equipmentIcon(for equipmentType: String) -> String {
        switch equipmentType.lowercased() {
        case "maschine":
            return "figure.hand.cycling"
        case "körpergewicht":
            return "figure.core.training"
        case "freie gewichte":
            return "figure.strengthtraining.traditional"
        case "cardio":
            return "figure.run.treadmill"
        default:
            return "figure.mixed.cardio"
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
    HomeView()
        .environment(SessionStore.preview)
}
