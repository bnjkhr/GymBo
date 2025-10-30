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
/// - Small black dot above day indicates workout completion
/// - Minimalist, clean design
/// - Auto-scrolls to show today as last visible day
///
/// **Design:**
/// - No streak display
/// - No colored circles
/// - Simple dot indicator (5pt black circle)
struct WorkoutCalendarStripView: View {
    @Environment(\.dependencyContainer) private var dependencyContainer
    @Environment(\.scenePhase) private var scenePhase
    @State private var workoutDates: Set<Date> = []
    @State private var lastWorkoutDate: Date?
    @State private var weeklyWorkoutGoal: Int = 3
    @State private var isLoading = true
    @State private var refreshTrigger = UUID()

    // Calendar helper
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
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
                    // Auto-scroll to today (last day)
                    if let today = last14Days.last {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo(today, anchor: .trailing)
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
        .task(id: refreshTrigger) {
            await loadWorkoutHistory()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshTrigger = UUID()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userProfileDidChange)) { _ in
            refreshTrigger = UUID()
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

    /// Count workouts this week (Monday to today)
    private var thisWeekWorkoutCount: Int {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else {
            return 0
        }

        let today = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        return workoutDates.filter { date in
            date >= weekStart && date < endOfToday
        }.count
    }

    // MARK: - Data Loading

    private func loadWorkoutHistory() async {
        guard let container = dependencyContainer else { return }

        do {
            let sessionRepository = container.makeSessionRepository()
            let userProfileRepository = container.makeUserProfileRepository()

            // Fetch user profile to get weekly goal
            let userProfile = try await userProfileRepository.fetchOrCreate()

            // Fetch sessions from last 14 days
            let startDate = calendar.startOfDay(for: last14Days.first ?? Date())
            let endDate =
                calendar.date(
                    byAdding: .day, value: 1,
                    to: calendar.startOfDay(for: last14Days.last ?? Date()))
                ?? Date()

            let sessions = try await sessionRepository.fetchCompletedSessions(
                from: startDate, to: endDate)

            // Extract unique workout dates (normalized to start of day)
            let dates = Set(
                sessions.map { session in
                    calendar.startOfDay(for: session.startDate)
                }
            )

            // Find most recent workout date
            let mostRecentDate =
                sessions
                .map { $0.startDate }
                .max()

            await MainActor.run {
                workoutDates = dates
                lastWorkoutDate = mostRecentDate
                weeklyWorkoutGoal = userProfile.weeklyWorkoutGoal
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

    /// Format date for display (e.g. "24.10." or "Heute")
    private func formatDate(_ date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Heute"
        } else if calendar.isDateInYesterday(date) {
            return "Gestern"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM."
            formatter.locale = Locale(identifier: "de_DE")
            return formatter.string(from: date)
        }
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let date: Date
    let hasWorkout: Bool
    let isToday: Bool

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            // Small black dot indicator (above day number)
            Circle()
                .fill(hasWorkout ? Color.black : Color.clear)
                .frame(width: 5, height: 5)

            // Day number
            Text("\(dayNumber)")
                .font(.body)
                .fontWeight(.regular)
                .foregroundStyle(.primary)
                .monospacedDigit()

            // Weekday
            Text(weekdayShort)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
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
