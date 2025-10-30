//
//  SessionHistoryView.swift
//  GymBo
//
//  Created on 2025-10-29.
//  V2 Clean Architecture - Presentation Layer
//

import SwiftUI

/// View displaying workout session history
///
/// **Features:**
/// - List of past workout sessions
/// - Filter by time period
/// - Statistics overview
/// - Tap to view session details
///
/// **Usage:**
/// ```swift
/// SessionHistoryView()
///     .environment(sessionHistoryStore)
/// ```
struct SessionHistoryView: View {

    @Environment(SessionHistoryStore.self) private var historyStore
    @State private var selectedFilter: SessionHistoryFilter = .recent(limit: 20)
    @State private var selectedSession: DomainWorkoutSession?
    @State private var showFilterPicker = false
    @State private var currentPeriod: WorkoutStatistics.TimePeriod = .week

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if historyStore.isLoadingHistory {
                    ProgressView("Lade Verlauf...")
                        .tint(.white)
                } else if !historyStore.hasHistory {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .navigationTitle("Verlauf")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterButton
                }
            }
            .task {
                await historyStore.loadAll(filter: selectedFilter, period: currentPeriod)
            }
            .refreshable {
                await historyStore.refreshHistory()
                await historyStore.refreshStatistics()
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
            .confirmationDialog("Filter", isPresented: $showFilterPicker, titleVisibility: .visible)
            {
                Button("Letzte 20") { selectFilter(.recent(limit: 20)) }
                Button("Letzte Woche") { selectFilter(.lastWeek) }
                Button("Letzter Monat") { selectFilter(.lastMonth) }
                Button("Letzte 3 Monate") { selectFilter(.lastThreeMonths) }
                Button("Letztes Jahr") { selectFilter(.lastYear) }
                Button("Alle") { selectFilter(.all) }
                Button("Abbrechen", role: .cancel) {}
            }
        }
    }

    // MARK: - Subviews

    private var historyListView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Statistics Card
                if let stats = historyStore.statistics {
                    StatisticsCard(statistics: stats)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }

                // Session List
                VStack(spacing: 16) {
                    ForEach(historyStore.sessionsByMonth, id: \.0) { month, sessions in
                        VStack(alignment: .leading, spacing: 12) {
                            // Month Header
                            Text(month)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)

                            // Sessions for this month
                            ForEach(sessions) { session in
                                SessionHistoryCard(session: session)
                                    .padding(.horizontal, 16)
                                    .onTapGesture {
                                        selectedSession = session
                                    }
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Noch keine Workouts")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text("Starte dein erstes Workout, um deinen Verlauf zu sehen")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var filterButton: some View {
        Button(action: { showFilterPicker = true }) {
            HStack(spacing: 4) {
                Text(selectedFilter.displayName)
                    .font(.subheadline)
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.body)
            }
            .foregroundStyle(.white)
        }
    }

    // MARK: - Actions

    private func sessionHistoryFilterToPeriod(_ filter: SessionHistoryFilter) -> WorkoutStatistics.TimePeriod {
        // Map filters to periods (update if new cases are added)
        switch filter {
        case .all, .lastYear:
            return .year
        case .lastThreeMonths, .lastMonth:
            return .month
        case .lastWeek:
            return .week
        case .dateRange:
            return .allTime // Or derive based on range?
        case .forWorkout, .recent:
            return .week // Or decide on default
        }
    }

    private func selectFilter(_ filter: SessionHistoryFilter) {
        selectedFilter = filter
        currentPeriod = sessionHistoryFilterToPeriod(filter)
        Task {
            await historyStore.loadHistory(filter: filter)
        }
    }
}

// MARK: - Statistics Card

struct StatisticsCard: View {
    let statistics: WorkoutStatistics

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(statistics.period.localizedDisplayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Color.appOrange)
            }

            // Stats Grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 12
            ) {
                StatItem(
                    icon: "figure.run",
                    label: "Workouts",
                    value: "\(statistics.totalWorkouts)"
                )

                StatItem(
                    icon: "clock.fill",
                    label: "Dauer",
                    value: statistics.formattedTotalDuration
                )

                StatItem(
                    icon: "flame.fill",
                    label: "Volumen",
                    value: statistics.formattedTotalVolume
                )

                StatItem(
                    icon: "checkmark.circle.fill",
                    label: "Streak",
                    value: "\(statistics.currentStreak) Tage"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.appOrange)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// MARK: - Session History Card

struct SessionHistoryCard: View {
    let session: DomainWorkoutSession

    private var completionPercentage: Double {
        session.progress * 100
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.appOrange.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title3)
                    .foregroundStyle(Color.appOrange)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutName ?? "Workout")
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    Label(session.formattedDuration, systemImage: "clock")
                    Label("\(session.completedSets) Sets", systemImage: "checkmark.circle")
                    Label(String(format: "%.0f kg", session.totalVolume), systemImage: "scalemass")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Time
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDate(session.startDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(formatTime(session.startDate))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Previews

#Preview("With Data") {
    SessionHistoryView()
        .environment(SessionHistoryStore.preview(withData: true))
}

#Preview("Empty") {
    SessionHistoryView()
        .environment(SessionHistoryStore.preview(withData: false))
}
