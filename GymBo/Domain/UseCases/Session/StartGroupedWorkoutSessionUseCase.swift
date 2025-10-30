//
//  StartGroupedWorkoutSessionUseCase.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V6 Clean Architecture - Domain Layer
//

import Foundation

/// Use Case for starting a new superset or circuit training workout session
///
/// **Responsibility:**
/// - Create a new DomainWorkoutSession from a superset/circuit workout template
/// - Load exercises and exercise groups from workout template
/// - Convert exercise groups to session exercise groups with round tracking
/// - Ensure no other active sessions exist
/// - Save session to repository
///
/// **Business Rules:**
/// - Only ONE active session allowed at a time
/// - Session starts with all sets marked as incomplete
/// - Session state is `.active` by default
/// - Start date is set to current time
/// - Round tracking starts at 1 for all groups
/// - Supports both superset (2 exercises) and circuit (3+ exercises) workouts
///
/// **Usage:**
/// ```swift
/// let useCase = DefaultStartGroupedWorkoutSessionUseCase(...)
/// let session = try await useCase.execute(workoutId: workoutId)
/// ```
protocol StartGroupedWorkoutSessionUseCase {
    /// Start a new superset/circuit workout session
    /// - Parameter workoutId: ID of the workout template to use
    /// - Returns: The newly created session
    /// - Throws: UseCaseError if session cannot be started
    func execute(workoutId: UUID) async throws -> DomainWorkoutSession
}

// MARK: - Implementation

/// Default implementation of StartGroupedWorkoutSessionUseCase
final class DefaultStartGroupedWorkoutSessionUseCase: StartGroupedWorkoutSessionUseCase {

    // MARK: - Properties

    private let sessionRepository: SessionRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let workoutRepository: WorkoutRepositoryProtocol
    private let healthKitService: HealthKitServiceProtocol
    private let featureFlagService: FeatureFlagServiceProtocol

    // MARK: - Initialization

    init(
        sessionRepository: SessionRepositoryProtocol,
        exerciseRepository: ExerciseRepositoryProtocol,
        workoutRepository: WorkoutRepositoryProtocol,
        healthKitService: HealthKitServiceProtocol,
        featureFlagService: FeatureFlagServiceProtocol
    ) {
        self.sessionRepository = sessionRepository
        self.exerciseRepository = exerciseRepository
        self.workoutRepository = workoutRepository
        self.healthKitService = healthKitService
        self.featureFlagService = featureFlagService
    }

    // MARK: - Execute

    func execute(workoutId: UUID) async throws -> DomainWorkoutSession {
        print("🔵 StartGroupedWorkoutSessionUseCase: Starting execution for workout \(workoutId)")

        // BUSINESS RULE: Only one active session allowed
        if let existingSession = try await sessionRepository.fetchActiveSession() {
            print("❌ StartGroupedWorkoutSessionUseCase: Active session already exists")
            throw UseCaseError.activeSessionExists(existingSession.id)
        }

        // Load workout template from repository
        print("🔵 StartGroupedWorkoutSessionUseCase: Loading workout template")
        guard let workout = try await workoutRepository.fetch(id: workoutId) else {
            print("❌ StartGroupedWorkoutSessionUseCase: Workout not found: \(workoutId)")
            throw UseCaseError.workoutNotFound(workoutId)
        }

        // Validate workout type
        guard workout.workoutType == .superset || workout.workoutType == .circuit else {
            throw UseCaseError.invalidInput(
                "Workout must be superset or circuit type (found: \(workout.workoutType.rawValue))"
            )
        }

        // Validate exercise groups exist
        guard let exerciseGroups = workout.exerciseGroups, !exerciseGroups.isEmpty else {
            throw UseCaseError.invalidInput("Workout must have exercise groups")
        }

        print(
            "✅ StartGroupedWorkoutSessionUseCase: Loaded \(workout.workoutType.rawValue) workout '\(workout.name)' with \(exerciseGroups.count) groups"
        )

        // Convert exercise groups to session exercise groups
        print(
            "🔵 StartGroupedWorkoutSessionUseCase: Converting workout groups to session groups")
        let sessionExerciseGroups = await convertToSessionExerciseGroups(exerciseGroups)
        print("   - Created \(sessionExerciseGroups.count) session exercise groups")

        // Flatten all session exercises from groups
        let allSessionExercises = sessionExerciseGroups.flatMap { $0.exercises }
        print("   - Total session exercises: \(allSessionExercises.count)")

        // Create session
        let session = DomainWorkoutSession(
            workoutId: workoutId,
            startDate: Date(),
            exercises: allSessionExercises,
            state: .active,
            workoutName: workout.name,
            workoutType: workout.workoutType,  // V6: Preserve workout type
            exerciseGroups: sessionExerciseGroups  // V6: Session exercise groups with round tracking
        )

        print("   - Session created with ID: \(session.id.uuidString)")

        // Save session to repository
        print("🔵 StartGroupedWorkoutSessionUseCase: Saving session to repository")
        do {
            try await sessionRepository.save(session)
            print("✅ StartGroupedWorkoutSessionUseCase: Session saved successfully")
        } catch {
            print("❌ StartGroupedWorkoutSessionUseCase: Failed to save session: \(error)")
            throw UseCaseError.saveFailed(error)
        }

        // Start HealthKit session (fire-and-forget, non-blocking)
        let dynamicIslandEnabled = featureFlagService.isEnabled(.dynamicIsland)
        let liveActivitiesEnabled = featureFlagService.isEnabled(.liveActivities)

        if dynamicIslandEnabled || liveActivitiesEnabled {
            Task.detached(priority: .background) { [weak self] in
                guard let self = self else { return }

                print("🔵 StartGroupedWorkoutSessionUseCase: Starting HealthKit session")
                let result = await self.healthKitService.startWorkoutSession(
                    type: .traditionalStrengthTraining,
                    startDate: session.startDate
                )

                switch result {
                case .success(let healthKitSessionId):
                    print("✅ HealthKit session started: \(healthKitSessionId)")

                    do {
                        guard
                            var currentSession = try await self.sessionRepository.fetch(
                                id: session.id)
                        else {
                            print("⚠️ Session not found when updating HealthKit ID")
                            return
                        }

                        currentSession.healthKitSessionId = healthKitSessionId
                        try await self.sessionRepository.update(currentSession)
                        print("✅ Session updated with HealthKit ID")
                    } catch {
                        print("⚠️ Failed to update session with HealthKit ID: \(error)")
                    }

                case .failure(let error):
                    print("⚠️ HealthKit session failed to start: \(error.localizedDescription)")
                }
            }
        }

        return session
    }

    // MARK: - Private Helpers

    /// Convert workout exercise groups to session exercise groups with round tracking
    private func convertToSessionExerciseGroups(_ exerciseGroups: [ExerciseGroup]) async
        -> [SessionExerciseGroup]
    {
        var sessionGroups: [SessionExerciseGroup] = []

        for group in exerciseGroups {
            // Convert each workout exercise in the group to a session exercise
            var sessionExercises: [DomainSessionExercise] = []

            for workoutExercise in group.exercises {
                // Load exercise from catalog to get last used values
                let exerciseEntity = try? await exerciseRepository.fetch(
                    id: workoutExercise.exerciseId)

                // Use last used values if available, otherwise use template values
                let weight =
                    exerciseEntity?.lastUsedWeight ?? workoutExercise.targetWeight ?? 0.0
                let reps = exerciseEntity?.lastUsedReps ?? workoutExercise.targetReps ?? 0

                // For grouped workouts, create ONE set per round
                // Each exercise gets targetSets number of sets (one per round)
                var sets: [DomainSessionSet] = []
                for setIndex in 0..<workoutExercise.targetSets {
                    // Determine rest time for this set
                    let restTime: TimeInterval?
                    if let perSetRestTimes = workoutExercise.perSetRestTimes,
                        setIndex < perSetRestTimes.count
                    {
                        restTime = perSetRestTimes[setIndex]
                    } else {
                        restTime = workoutExercise.restTime
                    }

                    let set = DomainSessionSet(
                        weight: weight,
                        reps: reps,
                        orderIndex: setIndex,  // Set index = round index
                        restTime: restTime
                    )
                    sets.append(set)
                }

                // Create session exercise
                let sessionExercise = DomainSessionExercise(
                    exerciseId: workoutExercise.exerciseId,
                    exerciseName: exerciseEntity?.name ?? "Übung",
                    sets: sets,
                    notes: workoutExercise.notes,
                    restTimeToNext: workoutExercise.restTime,
                    orderIndex: workoutExercise.orderIndex
                )

                sessionExercises.append(sessionExercise)
            }

            // Create session exercise group with round tracking
            let sessionGroup = SessionExerciseGroup(
                id: group.id,
                exercises: sessionExercises,
                groupIndex: group.groupIndex,
                currentRound: 1,  // Start at round 1
                totalRounds: group.rounds,  // Total rounds from group
                restAfterGroup: group.restAfterGroup
            )

            sessionGroups.append(sessionGroup)
        }

        return sessionGroups
    }
}
