//
//  WorkoutCalendarStripView.swift
//  GymTracker
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Workout Calendar Strip
//

import SwiftUI

/// Horizontal calendar strip showing workout history
///
/// **Features:**
/// - Shows last 14 days
/// - Highlights days with completed workouts
/// - Shows current streak (consecutive workout days)
/// - Auto-scrolls to today
struct WorkoutCalendarStripView: View {
    @Environment(\.dependencyContainer) private var dependencyContainer
    @State private var workoutDates: Set<Date> = []
    @State private var currentStreak: Int = 0
    @State private var isLoading = true

    // Calendar helper
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 12) {
            // Streak Badge (if exists)
            if currentStreak > 0 {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.subheadline)
                            .foregroundStyle(.appOrange)

                        Text("\(currentStreak)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .monospacedDigit()

                        Text(currentStreak == 1 ? "Tag" : "Tage")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.appOrange.opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.appOrange.opacity(0.3), lineWidth: 1)
                    )

                    Spacer()
                }
            }

            // Calendar Strip
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(last14Days, id: \.self) { date in
                            DayCell(
                                date: date,
                                hasWorkout: workoutDates.contains(normalizeDate(date)),
                                isToday: calendar.isDateInToday(date)
                            )
                            .id(date)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                }
                .onAppear {
                    // Auto-scroll to today
                    if let today = last14Days.first(where: { calendar.isDateInToday($0) }) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo(today, anchor: .center)
                            }
                        }
                    }
                }
            }
            .frame(height: 70)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .task {
            await loadWorkoutHistory()
        }
    }

    // MARK: - Computed Properties

    /// Last 14 days including today
    private var last14Days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<14).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }
    }

    // MARK: - Data Loading

    private func loadWorkoutHistory() async {
        guard let container = dependencyContainer else { return }

        do {
            let repository = container.makeSessionRepository()

            // Fetch sessions from last 14 days
            let startDate = calendar.startOfDay(for: last14Days.first ?? Date())
            let endDate =
                calendar.date(
                    byAdding: .day, value: 1,
                    to: calendar.startOfDay(for: last14Days.last ?? Date()))
                ?? Date()

            let sessions = try await repository.fetchCompletedSessions(
                from: startDate, to: endDate)

            // Extract unique workout dates (normalized to start of day)
            let dates = Set(
                sessions.map { session in
                    calendar.startOfDay(for: session.startDate)
                }
            )

            await MainActor.run {
                workoutDates = dates
                currentStreak = calculateStreak(from: dates)
                isLoading = false
            }
        } catch {
            print("❌ WorkoutCalendarStripView: Failed to load workout history: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }

    // MARK: - Helpers

    /// Normalize date to start of day for comparison
    private func normalizeDate(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Calculate consecutive workout days streak (ending today or most recent day)
    private func calculateStreak(from dates: Set<Date>) -> Int {
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today

        // Count backwards from today
        while dates.contains(currentDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate)
            else { break }
            currentDate = previousDay
        }

        return streak
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let date: Date
    let hasWorkout: Bool
    let isToday: Bool

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 6) {
            // Weekday
            Text(weekdayShort)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(isToday ? .primary : .secondary)

            // Day Circle
            ZStack {
                Circle()
                    .fill(hasWorkout ? Color.green : Color(.tertiarySystemFill))
                    .frame(width: 32, height: 32)

                if isToday {
                    Circle()
                        .strokeBorder(Color.blue, lineWidth: 2)
                        .frame(width: 32, height: 32)
                }

                Text("\(dayNumber)")
                    .font(.caption)
                    .fontWeight(hasWorkout ? .semibold : .regular)
                    .foregroundStyle(hasWorkout ? .white : .secondary)
                    .monospacedDigit()
            }
        }
        .frame(width: 40)
    }

    // MARK: - Computed Properties

    private var weekdayShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date).prefix(2).uppercased()
    }

    private var dayNumber: Int {
        calendar.component(.day, from: date)
    }
}

// MARK: - Preview

#Preview("With Workouts") {
    WorkoutCalendarStripView()
        .padding()
        .onAppear {
            // Mock workout dates: today, yesterday, 2 days ago
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            // Note: In production, this would come from the repository
        }
}

#Preview("No Workouts") {
    WorkoutCalendarStripView()
        .padding()
}
