//
//  WorkoutStatistics.swift
//  GymBo
//
//  Created on 2025-10-29.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Domain Entity representing workout statistics
///
/// This is a pure Swift struct with no framework dependencies. It represents
/// computed statistics from workout sessions.
///
/// **Design Decisions:**
/// - `struct` for value semantics
/// - Computed from session data, not persisted
/// - All properties are computed or aggregated
/// - Supports different time periods (week, month, year, all-time)
///
/// **Usage:**
/// ```swift
/// let stats = WorkoutStatistics.compute(from: sessions, period: .week)
/// ```
struct WorkoutStatistics: Equatable {

    // MARK: - Properties

    /// Time period for these statistics
    let period: TimePeriod

    /// Start date of the period
    let startDate: Date

    /// End date of the period
    let endDate: Date

    /// Total number of completed workouts
    let totalWorkouts: Int

    /// Total duration in seconds
    let totalDuration: TimeInterval

    /// Total volume (weight × reps) in kg
    let totalVolume: Double

    /// Total number of sets completed
    let totalSets: Int

    /// Total number of reps completed
    let totalReps: Int

    /// Average workout duration
    var averageWorkoutDuration: TimeInterval {
        guard totalWorkouts > 0 else { return 0 }
        return totalDuration / Double(totalWorkouts)
    }

    /// Average volume per workout
    var averageVolumePerWorkout: Double {
        guard totalWorkouts > 0 else { return 0 }
        return totalVolume / Double(totalWorkouts)
    }

    /// Current workout streak (consecutive days with workouts)
    let currentStreak: Int

    /// Longest workout streak in this period
    let longestStreak: Int

    /// Days with at least one workout
    let activeDays: Int

    /// Most frequent workout (by workout name)
    let mostFrequentWorkout: String?

    /// Personal records achieved in this period
    let personalRecords: [PersonalRecord]

    // MARK: - Nested Types

    enum TimePeriod: String, Equatable, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case allTime = "All Time"

        /// Get date range for this period from current date
        func dateRange(from referenceDate: Date = Date()) -> (start: Date, end: Date) {
            let calendar = Calendar.current

            switch self {
            case .week:
                let startOfWeek = calendar.date(
                    from: calendar.dateComponents(
                        [.yearForWeekOfYear, .weekOfYear], from: referenceDate))!
                let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
                return (startOfWeek, endOfWeek)

            case .month:
                let startOfMonth = calendar.date(
                    from: calendar.dateComponents([.year, .month], from: referenceDate))!
                let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
                return (startOfMonth, endOfMonth)

            case .year:
                let startOfYear = calendar.date(
                    from: calendar.dateComponents([.year], from: referenceDate))!
                let endOfYear = calendar.date(byAdding: .year, value: 1, to: startOfYear)!
                return (startOfYear, endOfYear)

            case .allTime:
                return (Date.distantPast, Date.distantFuture)
            }
        }
    }

    struct PersonalRecord: Equatable, Identifiable {
        let id: UUID
        let exerciseName: String
        let type: RecordType
        let value: Double
        let achievedDate: Date

        enum RecordType: String, Equatable {
            case maxWeight = "Max Weight"
            case maxReps = "Max Reps"
            case maxVolume = "Max Volume"
            case bestSet = "Best Set"
        }
    }

    // MARK: - Initialization

    init(
        period: TimePeriod,
        startDate: Date,
        endDate: Date,
        totalWorkouts: Int,
        totalDuration: TimeInterval,
        totalVolume: Double,
        totalSets: Int,
        totalReps: Int,
        currentStreak: Int,
        longestStreak: Int,
        activeDays: Int,
        mostFrequentWorkout: String?,
        personalRecords: [PersonalRecord] = []
    ) {
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.totalWorkouts = totalWorkouts
        self.totalDuration = totalDuration
        self.totalVolume = totalVolume
        self.totalSets = totalSets
        self.totalReps = totalReps
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.activeDays = activeDays
        self.mostFrequentWorkout = mostFrequentWorkout
        self.personalRecords = personalRecords
    }

    // MARK: - Computation

    /// Compute statistics from a list of sessions
    static func compute(
        from sessions: [DomainWorkoutSession], period: TimePeriod, referenceDate: Date = Date()
    ) -> WorkoutStatistics {
        let dateRange = period.dateRange(from: referenceDate)

        // Filter sessions for this period and only completed ones
        let filteredSessions = sessions.filter { session in
            session.state == .completed && session.startDate >= dateRange.start
                && session.startDate < dateRange.end
        }.sorted { $0.startDate < $1.startDate }

        // Basic stats
        let totalWorkouts = filteredSessions.count
        let totalDuration = filteredSessions.reduce(0.0) { $0 + $1.duration }
        let totalVolume = filteredSessions.reduce(0.0) { $0 + $1.totalVolume }
        let totalSets = filteredSessions.reduce(0) { $0 + $1.completedSets }
        let totalReps = filteredSessions.reduce(0) { total, session in
            total
                + session.exercises.reduce(0) { exerciseTotal, exercise in
                    exerciseTotal + exercise.sets.filter { $0.completed }.reduce(0) { $0 + $1.reps }
                }
        }

        // Calculate streaks
        let streaks = calculateStreaks(from: filteredSessions)

        // Active days
        let activeDays = Set(
            filteredSessions.map { Calendar.current.startOfDay(for: $0.startDate) }
        ).count

        // Most frequent workout
        let workoutCounts = Dictionary(grouping: filteredSessions) { $0.workoutName ?? "Unknown" }
            .mapValues { $0.count }
        let mostFrequentWorkout = workoutCounts.max(by: { $0.value < $1.value })?.key

        // Personal records (simplified for now)
        let personalRecords: [PersonalRecord] = []

        return WorkoutStatistics(
            period: period,
            startDate: dateRange.start,
            endDate: dateRange.end,
            totalWorkouts: totalWorkouts,
            totalDuration: totalDuration,
            totalVolume: totalVolume,
            totalSets: totalSets,
            totalReps: totalReps,
            currentStreak: streaks.current,
            longestStreak: streaks.longest,
            activeDays: activeDays,
            mostFrequentWorkout: mostFrequentWorkout,
            personalRecords: personalRecords
        )
    }

    /// Calculate current and longest workout streaks
    private static func calculateStreaks(from sessions: [DomainWorkoutSession]) -> (
        current: Int, longest: Int
    ) {
        guard !sessions.isEmpty else { return (0, 0) }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Group sessions by day
        let sessionsByDay = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startDate)
        }

        let sortedDays = sessionsByDay.keys.sorted()

        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        var lastDate: Date?

        for day in sortedDays {
            if let last = lastDate {
                let daysDiff = calendar.dateComponents([.day], from: last, to: day).day ?? 0

                if daysDiff == 1 {
                    // Consecutive day
                    tempStreak += 1
                } else {
                    // Streak broken
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                // First day
                tempStreak = 1
            }

            lastDate = day
        }

        longestStreak = max(longestStreak, tempStreak)

        // Calculate current streak (only if includes today or yesterday)
        if let lastDay = sortedDays.last {
            let daysSinceLastWorkout =
                calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysSinceLastWorkout <= 1 {
                // Current streak is valid
                var streakDays = [lastDay]
                var checkDate = lastDay

                for day in sortedDays.reversed().dropFirst() {
                    let daysDiff =
                        calendar.dateComponents([.day], from: day, to: checkDate).day ?? 0

                    if daysDiff == 1 {
                        streakDays.append(day)
                        checkDate = day
                    } else {
                        break
                    }
                }

                currentStreak = streakDays.count
            }
        }

        return (currentStreak, longestStreak)
    }
}

// MARK: - Formatted Helpers

extension WorkoutStatistics {
    /// Formatted total duration (HH:MM)
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        return String(format: "%dh %02dm", hours, minutes)
    }

    /// Formatted average duration (MM:SS)
    var formattedAverageDuration: String {
        let totalSeconds = Int(averageWorkoutDuration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Formatted total volume (kg)
    var formattedTotalVolume: String {
        String(format: "%.0f kg", totalVolume)
    }

    /// Formatted average volume (kg)
    var formattedAverageVolume: String {
        String(format: "%.0f kg", averageVolumePerWorkout)
    }
}

// MARK: - Preview Helpers

#if DEBUG
    extension WorkoutStatistics {
        /// Sample statistics for previews
        static var preview: WorkoutStatistics {
            WorkoutStatistics(
                period: .week,
                startDate: Date().addingTimeInterval(-7 * 24 * 3600),
                endDate: Date(),
                totalWorkouts: 4,
                totalDuration: 3600 * 4,  // 4 hours
                totalVolume: 12500,
                totalSets: 48,
                totalReps: 384,
                currentStreak: 3,
                longestStreak: 5,
                activeDays: 4,
                mostFrequentWorkout: "Push Day",
                personalRecords: []
            )
        }

        static var previewMonth: WorkoutStatistics {
            WorkoutStatistics(
                period: .month,
                startDate: Date().addingTimeInterval(-30 * 24 * 3600),
                endDate: Date(),
                totalWorkouts: 16,
                totalDuration: 3600 * 16,
                totalVolume: 52000,
                totalSets: 192,
                totalReps: 1536,
                currentStreak: 3,
                longestStreak: 7,
                activeDays: 16,
                mostFrequentWorkout: "Push Day",
                personalRecords: []
            )
        }
    }
#endif
