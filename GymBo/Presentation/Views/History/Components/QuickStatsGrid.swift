//
//  QuickStatsGrid.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V2 Clean Architecture - Presentation Layer
//

import SwiftUI

/// Quick stats grid showing key metrics in 2x2 tile layout
///
/// **Features:**
/// - Total Workouts with weekly delta
/// - Total Volume with weekly delta
/// - Total Duration with weekly delta
/// - Personal Bests with weekly delta
/// - Glassmorphism design
///
/// **Layout:**
/// ```
/// ┌─────────────┬─────────────┐
/// │  Workouts   │   Volumen   │
/// ├─────────────┼─────────────┤
/// │    Zeit     │     PRs     │
/// └─────────────┴─────────────┘
/// ```
struct QuickStatsGrid: View {

    let allTimeStats: WorkoutStatistics?
    let weekStats: WorkoutStatistics?
    let personalRecordsCount: Int  // TODO: Get from actual PR tracking
    let personalRecordsThisWeek: Int  // TODO: Get from actual PR tracking

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ],
            spacing: 12
        ) {
            // Row 1
            StatTile(
                icon: "figure.run",
                emoji: "💪",
                value: "\(allTimeStats?.totalWorkouts ?? 0)",
                label: "Total Workouts",
                delta: "+\(weekStats?.totalWorkouts ?? 0) diese Woche",
                deltaColor: .green
            )

            StatTile(
                icon: "scalemass",
                emoji: "⚖️",
                value: formatVolume(allTimeStats?.totalVolume ?? 0),
                label: "Total Volumen",
                delta: formatVolumeDelta(weekStats?.totalVolume ?? 0),
                deltaColor: (weekStats?.totalVolume ?? 0) > 0 ? .green : .secondary
            )

            // Row 2
            StatTile(
                icon: "clock",
                emoji: "⏱️",
                value: formatDuration(allTimeStats?.totalDuration ?? 0),
                label: "Gesamt Zeit",
                delta: formatDurationDelta(weekStats?.totalDuration ?? 0),
                deltaColor: (weekStats?.totalDuration ?? 0) > 0 ? .green : .secondary
            )

            StatTile(
                icon: "trophy",
                emoji: "🏆",
                value: "\(personalRecordsCount)",
                label: "Personal Bests",
                delta: personalRecordsThisWeek > 0
                    ? "+\(personalRecordsThisWeek) diese Woche" : "Keine diese Woche",
                deltaColor: personalRecordsThisWeek > 0 ? .yellow : .secondary
            )
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

    private func formatVolumeDelta(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "+%.1fk kg diese W.", volume / 1000)
        } else if volume > 0 {
            return String(format: "+%.0f kg diese W.", volume)
        } else {
            return "Keine diese W."
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return String(format: "%.1f Std", Double(hours) + Double(minutes) / 60.0)
        } else {
            return String(format: "%d Min", minutes)
        }
    }

    private func formatDurationDelta(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return String(format: "+%.1f Std diese W.", Double(hours) + Double(minutes) / 60.0)
        } else if minutes > 0 {
            return String(format: "+%d Min diese W.", minutes)
        } else {
            return "Keine diese W."
        }
    }
}

// MARK: - Stat Tile Component

struct StatTile: View {
    let icon: String
    let emoji: String
    let value: String
    let label: String
    let delta: String
    let deltaColor: Color

    var body: some View {
        VStack(spacing: 12) {
            // Icon/Emoji
            Text(emoji)
                .font(.system(size: 36))

            // Value
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Label
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Delta
            Text(delta)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(deltaColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Previews

#Preview("With Data") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            QuickStatsGrid(
                allTimeStats: WorkoutStatistics(
                    period: .allTime,
                    startDate: Date().addingTimeInterval(-365 * 24 * 3600),
                    endDate: Date(),
                    totalWorkouts: 234,
                    totalDuration: 3600 * 156.5,
                    totalVolume: 15420,
                    totalSets: 2808,
                    totalReps: 22464,
                    currentStreak: 7,
                    longestStreak: 12,
                    activeDays: 120,
                    mostFrequentWorkout: "Push Day"
                ),
                weekStats: .preview,
                personalRecordsCount: 12,
                personalRecordsThisWeek: 2
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
            QuickStatsGrid(
                allTimeStats: nil,
                weekStats: nil,
                personalRecordsCount: 0,
                personalRecordsThisWeek: 0
            )
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.top, 20)
    }
}
