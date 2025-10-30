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
                Color(uiColor: .systemBackground).ignoresSafeArea()

                if historyStore.isLoadingHistory {
                    ProgressView("Lade Verlauf...")
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
                // Hero Stats Card
                HeroStatsCard(
                    weekStats: historyStore.weekStats,
                    previousWeekStats: historyStore.previousWeekStats
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Quick Stats Grid
                QuickStatsGrid(
                    allTimeStats: historyStore.allTimeStats,
                    weekStats: historyStore.weekStats,
                    personalRecordsCount: 0,  // TODO: Implement PR tracking
                    personalRecordsThisWeek: 0  // TODO: Implement PR tracking
                )
                .padding(.horizontal, 16)

                // Session List with new timeline cards
                sessionsListSection

                    .padding(.bottom, 24)
            }
        }
    }

    private var sessionsListSection: some View {
        VStack(spacing: 16) {
            ForEach(groupedSessions, id: \.section) { group in
                VStack(alignment: .leading, spacing: 12) {
                    // Sticky Section Header
                    sectionHeader(group.section, count: group.sessions.count)
                        .padding(.horizontal, 16)

                    // Sessions for this section
                    ForEach(group.sessions) { session in
                        SessionTimelineCard(session: session)
                            .padding(.horizontal, 16)
                            .onTapGesture {
                                selectedSession = session
                            }
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Text("(\(count))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground).opacity(0.95))
    }

    /// Group sessions by relative time (Heute, Gestern, Diese Woche, etc.)
    private var groupedSessions: [SessionGroup] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        var groups: [SessionGroup] = []

        // Group 1: Heute
        let todaySessions = historyStore.sessions.filter {
            calendar.isDate($0.startDate, inSameDayAs: now)
        }
        if !todaySessions.isEmpty {
            groups.append(SessionGroup(section: "Heute", sessions: todaySessions))
        }

        // Group 2: Gestern
        let yesterdaySessions = historyStore.sessions.filter {
            calendar.isDate($0.startDate, inSameDayAs: yesterday)
        }
        if !yesterdaySessions.isEmpty {
            groups.append(SessionGroup(section: "Gestern", sessions: yesterdaySessions))
        }

        // Group 3: Diese Woche (excluding today and yesterday)
        let thisWeekSessions = historyStore.sessions.filter { session in
            session.startDate >= weekAgo && session.startDate < yesterday
                && !calendar.isDate(session.startDate, inSameDayAs: now)
        }
        if !thisWeekSessions.isEmpty {
            groups.append(SessionGroup(section: "Diese Woche", sessions: thisWeekSessions))
        }

        // Group 4+: By month for older sessions
        let olderSessions = historyStore.sessions.filter { $0.startDate < weekAgo }
        let monthGroups = Dictionary(grouping: olderSessions) { session -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: session.startDate)
        }

        for (month, sessions) in monthGroups.sorted(by: {
            $0.value.first!.startDate > $1.value.first!.startDate
        }) {
            groups.append(
                SessionGroup(
                    section: month, sessions: sessions.sorted { $0.startDate > $1.startDate }))
        }

        return groups
    }

    private struct SessionGroup {
        let section: String
        let sessions: [DomainWorkoutSession]
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Noch keine Workouts")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

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
            .foregroundStyle(.primary)
        }
    }

    // MARK: - Actions

    private func sessionHistoryFilterToPeriod(_ filter: SessionHistoryFilter)
        -> WorkoutStatistics.TimePeriod
    {
        // Map filters to periods (update if new cases are added)
        switch filter {
        case .all, .lastYear:
            return .year
        case .lastThreeMonths, .lastMonth:
            return .month
        case .lastWeek:
            return .week
        case .dateRange:
            return .allTime  // Or derive based on range?
        case .forWorkout, .recent:
            return .week  // Or decide on default
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

// MARK: - Previews

#Preview("With Data") {
    SessionHistoryView()
        .environment(SessionHistoryStore.preview(withData: true))
}

#Preview("Empty") {
    SessionHistoryView()
        .environment(SessionHistoryStore.preview(withData: false))
}
