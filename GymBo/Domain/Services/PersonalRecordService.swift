//
//  PersonalRecordService.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Service for detecting and managing personal records
///
/// **Responsibility:**
/// - Detect new personal records from sessions
/// - Compare exercise performance across sessions
/// - Calculate max weight, reps, volume per exercise
/// - Track PR achievements over time
///
/// **Usage:**
/// ```swift
/// let service = PersonalRecordService()
/// let prs = service.detectPersonalRecords(in: sessions)
/// let recentPRs = service.getRecentPRs(from: sessions, days: 7)
/// ```
struct PersonalRecordService {

    /// Detect all personal records from a list of sessions
    /// - Parameter sessions: List of completed workout sessions
    /// - Returns: Array of personal records found
    func detectPersonalRecords(in sessions: [DomainWorkoutSession]) -> [WorkoutStatistics
        .PersonalRecord]
    {
        // Only consider completed sessions
        let completedSessions = sessions.filter { $0.state == .completed }

        // Group exercises by name across all sessions
        var exerciseRecords: [String: ExerciseStats] = [:]

        for session in completedSessions {
            for exercise in session.exercises {
                let exerciseName = exercise.exerciseName

                if exerciseRecords[exerciseName] == nil {
                    exerciseRecords[exerciseName] = ExerciseStats()
                }

                exerciseRecords[exerciseName]?.updateWithExercise(
                    exercise, sessionDate: session.startDate)
            }
        }

        // Convert to PersonalRecord array
        var personalRecords: [WorkoutStatistics.PersonalRecord] = []

        for (exerciseName, stats) in exerciseRecords {
            // Max Weight PR
            if let maxWeight = stats.maxWeightRecord {
                personalRecords.append(
                    WorkoutStatistics.PersonalRecord(
                        id: UUID(),
                        exerciseName: exerciseName,
                        type: .maxWeight,
                        value: maxWeight.weight,
                        achievedDate: maxWeight.date
                    )
                )
            }

            // Max Reps PR
            if let maxReps = stats.maxRepsRecord {
                personalRecords.append(
                    WorkoutStatistics.PersonalRecord(
                        id: UUID(),
                        exerciseName: exerciseName,
                        type: .maxReps,
                        value: Double(maxReps.reps),
                        achievedDate: maxReps.date
                    )
                )
            }

            // Max Volume PR (single exercise)
            if let maxVolume = stats.maxVolumeRecord {
                personalRecords.append(
                    WorkoutStatistics.PersonalRecord(
                        id: UUID(),
                        exerciseName: exerciseName,
                        type: .maxVolume,
                        value: maxVolume.volume,
                        achievedDate: maxVolume.date
                    )
                )
            }

            // Best Set PR (weight × reps)
            if let bestSet = stats.bestSetRecord {
                personalRecords.append(
                    WorkoutStatistics.PersonalRecord(
                        id: UUID(),
                        exerciseName: exerciseName,
                        type: .bestSet,
                        value: bestSet.score,
                        achievedDate: bestSet.date
                    )
                )
            }
        }

        return personalRecords.sorted { $0.achievedDate > $1.achievedDate }
    }

    /// Get personal records achieved within the last N days
    /// - Parameters:
    ///   - sessions: List of completed workout sessions
    ///   - days: Number of days to look back
    /// - Returns: Array of recent personal records
    func getRecentPRs(from sessions: [DomainWorkoutSession], days: Int = 7) -> [WorkoutStatistics
        .PersonalRecord]
    {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let allPRs = detectPersonalRecords(in: sessions)

        return allPRs.filter { $0.achievedDate >= cutoffDate }
    }

    /// Check if a specific exercise performance is a new PR
    /// - Parameters:
    ///   - exercise: The exercise to check
    ///   - previousSessions: Previous sessions to compare against
    /// - Returns: PR type if it's a new record, nil otherwise
    func checkForNewPR(
        exercise: DomainSessionExercise,
        in previousSessions: [DomainWorkoutSession]
    ) -> WorkoutStatistics.PersonalRecord.RecordType? {
        let previousRecords = detectPersonalRecords(in: previousSessions)
            .filter { $0.exerciseName == exercise.exerciseName }

        // Check max weight
        if let maxWeight = exercise.sets.map({ $0.weight }).max(),
            let previousMaxWeight = previousRecords.first(where: { $0.type == .maxWeight })?.value,
            maxWeight > previousMaxWeight
        {
            return .maxWeight
        }

        // Check max reps
        if let maxReps = exercise.sets.map({ $0.reps }).max(),
            let previousMaxReps = previousRecords.first(where: { $0.type == .maxReps })?.value,
            Double(maxReps) > previousMaxReps
        {
            return .maxReps
        }

        // Check max volume
        let currentVolume = exercise.totalVolume
        if let previousMaxVolume = previousRecords.first(where: { $0.type == .maxVolume })?.value,
            currentVolume > previousMaxVolume
        {
            return .maxVolume
        }

        // Check best set (weight × reps)
        if let bestSet = exercise.sets.map({ $0.weight * Double($0.reps) }).max(),
            let previousBestSet = previousRecords.first(where: { $0.type == .bestSet })?.value,
            bestSet > previousBestSet
        {
            return .bestSet
        }

        return nil
    }

    /// Get top performing exercises by weight
    /// - Parameters:
    ///   - sessions: List of sessions to analyze
    ///   - limit: Number of top exercises to return
    /// - Returns: Array of top lifts with details
    func getTopLiftsByWeight(from sessions: [DomainWorkoutSession], limit: Int = 3) -> [TopLift] {
        var exerciseMaxWeights: [String: (weight: Double, date: Date)] = [:]

        for session in sessions.filter({ $0.state == .completed }) {
            for exercise in session.exercises {
                if let maxWeight = exercise.sets.map({ $0.weight }).max() {
                    if let existing = exerciseMaxWeights[exercise.exerciseName] {
                        if maxWeight > existing.weight {
                            exerciseMaxWeights[exercise.exerciseName] = (
                                maxWeight, session.startDate
                            )
                        }
                    } else {
                        exerciseMaxWeights[exercise.exerciseName] = (maxWeight, session.startDate)
                    }
                }
            }
        }

        return
            exerciseMaxWeights
            .sorted { $0.value.weight > $1.value.weight }
            .prefix(limit)
            .map { TopLift(exerciseName: $0.key, weight: $0.value.weight, date: $0.value.date) }
    }

    // MARK: - Helper Types

    struct TopLift {
        let exerciseName: String
        let weight: Double
        let date: Date
    }

    /// Internal structure for tracking exercise statistics
    private struct ExerciseStats {
        var maxWeightRecord: WeightRecord?
        var maxRepsRecord: RepsRecord?
        var maxVolumeRecord: VolumeRecord?
        var bestSetRecord: SetRecord?

        mutating func updateWithExercise(_ exercise: DomainSessionExercise, sessionDate: Date) {
            // Track max weight
            if let maxWeight = exercise.sets.map({ $0.weight }).max() {
                if maxWeightRecord == nil || maxWeight > maxWeightRecord!.weight {
                    maxWeightRecord = WeightRecord(weight: maxWeight, date: sessionDate)
                }
            }

            // Track max reps
            if let maxReps = exercise.sets.map({ $0.reps }).max() {
                if maxRepsRecord == nil || maxReps > maxRepsRecord!.reps {
                    maxRepsRecord = RepsRecord(reps: maxReps, date: sessionDate)
                }
            }

            // Track max volume
            let volume = exercise.totalVolume
            if maxVolumeRecord == nil || volume > maxVolumeRecord!.volume {
                maxVolumeRecord = VolumeRecord(volume: volume, date: sessionDate)
            }

            // Track best set (weight × reps)
            if let bestSet = exercise.sets.map({ $0.weight * Double($0.reps) }).max() {
                if bestSetRecord == nil || bestSet > bestSetRecord!.score {
                    bestSetRecord = SetRecord(score: bestSet, date: sessionDate)
                }
            }
        }

        struct WeightRecord {
            let weight: Double
            let date: Date
        }

        struct RepsRecord {
            let reps: Int
            let date: Date
        }

        struct VolumeRecord {
            let volume: Double
            let date: Date
        }

        struct SetRecord {
            let score: Double  // weight × reps
            let date: Date
        }
    }
}
