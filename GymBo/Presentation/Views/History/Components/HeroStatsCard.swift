//
//  HeroStatsCard.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V2 Clean Architecture - Presentation Layer
//

import Foundation
import SwiftUI

/// Hero stats card displaying current streak and weekly progress
///
/// **Features:**
/// - Current streak with fire icon
/// - Weekly goal progress bar
/// - Key metrics: Volume delta, total volume, total duration
/// - Glassmorphism design
///
/// **Design:**
/// - Full-width card (~200pt height)
/// - Orange accents for highlights
/// - Week-over-week comparison
struct HeroStatsCard: View {

    let weekStats: WorkoutStatistics?
    let previousWeekStats: WorkoutStatistics?
    let weeklyGoal: Int = 5  // TODO: Make this configurable in settings

    // MARK: - Computed Properties

    private var currentStreak: Int {
        weekStats?.currentStreak ?? 0
    }

    private var weekProgress: Double {
        guard let stats = weekStats else { return 0.0 }
        return min(Double(stats.totalWorkouts) / Double(weeklyGoal), 1.0)
    }

    private var volumeDelta: Double {
        guard let current = weekStats?.totalVolume,
            let previous = previousWeekStats?.totalVolume,
            previous > 0
        else { return 0 }
        return current - previous
    }

    private var totalVolume: Double {
        weekStats?.totalVolume ?? 0
    }

    private var totalDuration: TimeInterval {
        weekStats?.totalDuration ?? 0
    }

    private var workoutsThisWeek: Int {
        weekStats?.totalWorkouts ?? 0
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Streak Section
            streakSection

            // Weekly Progress
            weeklyProgressSection

            // Key Metrics Row
            keyMetricsRow
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Subviews

    private var streakSection: some View {
        HStack(spacing: 8) {
            // Fire Icon with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: streakGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Text("🔥")
                    .font(.system(size: 28))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(currentStreak) Tage Streak")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                if currentStreak > 0 {
                    Text(streakMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Diese Woche")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Spacer()

                Text("\(workoutsThisWeek) / \(weeklyGoal) Workouts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))

                    // Progress Fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.appOrange, Color.appOrange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * weekProgress)
                }
            }
            .frame(height: 12)
        }
    }

    private var keyMetricsRow: some View {
        HStack(spacing: 0) {
            // Volume Delta
            MetricItem(
                value: formatVolumeDelta(volumeDelta),
                label: "Gewicht",
                valueColor: volumeDelta >= 0 ? .green : .red,
                showPlusMinus: true
            )

            Divider()
                .background(Color.white.opacity(0.1))
                .frame(height: 40)

            // Total Volume
            MetricItem(
                value: formatVolume(totalVolume),
                label: "Volumen",
                valueColor: .white
            )

            Divider()
                .background(Color.white.opacity(0.1))
                .frame(height: 40)

            // Total Duration
            MetricItem(
                value: formatDuration(totalDuration),
                label: "Dauer",
                valueColor: .white
            )
        }
    }

    // MARK: - Helper Views

    private struct MetricItem: View {
        let value: String
        let label: String
        let valueColor: Color
        var showPlusMinus: Bool = false

        var body: some View {
            VStack(spacing: 4) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(valueColor)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Formatting Helpers

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk kg", volume / 1000)
        } else {
            return String(format: "%.0f kg", volume)
        }
    }

    private func formatVolumeDelta(_ delta: Double) -> String {
        let absValue = abs(delta)
        let formatted: String

        if absValue >= 1000 {
            formatted = String(format: "%.1fk kg", absValue / 1000)
        } else {
            formatted = String(format: "%.0f kg", absValue)
        }

        if delta > 0 {
            return "+\(formatted)"
        } else if delta < 0 {
            return "-\(formatted)"
        } else {
            return "±0 kg"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return String(format: "%d.%d Std", hours, minutes / 6)
        } else {
            return String(format: "%d Min", minutes)
        }
    }

    // MARK: - Streak Helpers

    private var streakGradientColors: [Color] {
        switch currentStreak {
        case 0:
            return [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
        case 1...3:
            return [Color.appOrange, Color.appOrange.opacity(0.7)]
        case 4...6:
            return [Color.appOrange, Color.red.opacity(0.8)]
        default:  // 7+
            return [Color.yellow, Color.orange]
        }
    }

    private var streakMessage: String {
        switch currentStreak {
        case 0:
            return "Starte deine Streak heute!"
        case 1:
            return "Guter Start! 💪"
        case 2...3:
            return "Du bist on fire! 🔥"
        case 4...6:
            return "Unglaublich! Keep going!"
        default:  // 7+
            return "Streak-Legende! 🏆"
        }
    }
}

// MARK: - Previews

#Preview("With Data") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            HeroStatsCard(
                weekStats: .preview,
                previousWeekStats: WorkoutStatistics(
                    period: .week,
                    startDate: Date().addingTimeInterval(-14 * 24 * 3600),
                    endDate: Date().addingTimeInterval(-7 * 24 * 3600),
                    totalWorkouts: 3,
                    totalDuration: 3600 * 3,
                    totalVolume: 10000,
                    totalSets: 36,
                    totalReps: 288,
                    currentStreak: 2,
                    longestStreak: 4,
                    activeDays: 3,
                    mostFrequentWorkout: "Push Day"
                )
            )
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.top, 20)
    }
}

#Preview("No Data") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            HeroStatsCard(
                weekStats: nil,
                previousWeekStats: nil
            )
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.top, 20)
    }
}

#Preview("High Streak") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            HeroStatsCard(
                weekStats: WorkoutStatistics(
                    period: .week,
                    startDate: Date().addingTimeInterval(-7 * 24 * 3600),
                    endDate: Date(),
                    totalWorkouts: 5,
                    totalDuration: 3600 * 5,
                    totalVolume: 15000,
                    totalSets: 60,
                    totalReps: 480,
                    currentStreak: 12,
                    longestStreak: 12,
                    activeDays: 5,
                    mostFrequentWorkout: "Push Day"
                ),
                previousWeekStats: WorkoutStatistics(
                    period: .week,
                    startDate: Date().addingTimeInterval(-14 * 24 * 3600),
                    endDate: Date().addingTimeInterval(-7 * 24 * 3600),
                    totalWorkouts: 4,
                    totalDuration: 3600 * 4,
                    totalVolume: 12000,
                    totalSets: 48,
                    totalReps: 384,
                    currentStreak: 8,
                    longestStreak: 8,
                    activeDays: 4,
                    mostFrequentWorkout: "Push Day"
                )
            )
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.top, 20)
    }
}
