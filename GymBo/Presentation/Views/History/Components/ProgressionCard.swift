//
//  ProgressionCard.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V2 Clean Architecture - Presentation Layer
//

import Foundation
import SwiftUI

/// Progression card with tabs for Gewicht, Volumen, and PRs
///
/// **Features:**
/// - 3 tabs: Gewicht | Volumen | PRs
/// - Mini sparkline chart showing trend
/// - Top lifts/achievements list
/// - Horizontal scrollable content
///
/// **Layout:**
/// ```
/// ┌─────────────────────────────────────┐
/// │ Progression                          │
/// │ [Gewicht] Volumen  PRs              │  ← Tab Bar
/// │                                      │
/// │    ╱╲        Mini Chart             │
/// │   ╱  ╲    ╱╲                        │
/// │  ╱    ╲  ╱  ╲                       │
/// │ ╱      ╲╱    ╲                      │
/// │                                      │
/// │ Top Lifts diese Woche:              │
/// │ • Bankdrücken: 100 kg (+5 kg)       │
/// │ • Kniebeugen:  140 kg (+10 kg)      │
/// │ • Kreuzheben:  160 kg (PR! 🎉)      │
/// └─────────────────────────────────────┘
/// ```
struct ProgressionCard: View {

    let sessions: [DomainWorkoutSession]
    @State private var selectedTab: ProgressionTab = .weight
    @State private var chartProgress: CGFloat = 0
    private let prService = PersonalRecordService()

    enum ProgressionTab: String, CaseIterable {
        case weight = "Gewicht"
        case volume = "Volumen"
        case prs = "PRs"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            header

            // Tab Bar
            tabBar

            // Content (switches based on selected tab)
            tabContent
        }
        .padding(20)
        .frame(maxWidth: .infinity)
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

    private var header: some View {
        HStack {
            Text("Progression")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundStyle(Color.appOrange)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 12) {
            ForEach(ProgressionTab.allCases, id: \.self) { tab in
                TabButton(
                    title: tab.rawValue,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .weight:
            weightContent
        case .volume:
            volumeContent
        case .prs:
            prsContent
        }
    }

    private var weightContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Mini Chart Placeholder
            miniChartPlaceholder(title: "Gewichtsprogression")

            // Top Lifts
            topLiftsSection(type: .weight)
        }
    }

    private var volumeContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Mini Chart Placeholder
            miniChartPlaceholder(title: "Volumen-Trend")

            // Volume Stats
            volumeStatsSection()
        }
    }

    private var prsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // PR Count
            prCountSection()

            // Recent PRs
            topLiftsSection(type: .pr)
        }
    }

    // MARK: - Content Sections

    private func miniChartPlaceholder(title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Simple sparkline placeholder (will be replaced with actual chart)
            ZStack(alignment: .bottom) {
                // Background grid
                HStack(spacing: 0) {
                    ForEach(0..<7) { _ in
                        Rectangle()
                            .fill(Color.secondary.opacity(0.1))
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 80)

                // Placeholder trend line
                GeometryReader { geometry in
                    Path { path in
                        let points = generateSampleData()
                        let width = geometry.size.width
                        let height = geometry.size.height

                        guard !points.isEmpty else { return }

                        let maxValue = points.max() ?? 1
                        let step = width / CGFloat(points.count - 1)

                        path.move(
                            to: CGPoint(
                                x: 0,
                                y: height - (CGFloat(points[0]) / CGFloat(maxValue)) * height
                            ))

                        let visiblePoints = Int(CGFloat(points.count - 1) * chartProgress) + 1
                        for (index, value) in points.prefix(visiblePoints).dropFirst().enumerated()
                        {
                            path.addLine(
                                to: CGPoint(
                                    x: CGFloat(index + 1) * step,
                                    y: height - (CGFloat(value) / CGFloat(maxValue)) * height
                                ))
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [Color.appOrange, Color.appOrange.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
                    .onAppear {
                        withAnimation(AnimationHelper.chartDrawAnimation) {
                            chartProgress = 1.0
                        }
                    }
                }
                .frame(height: 80)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func topLiftsSection(type: LiftType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(type == .weight ? "Top Lifts diese Woche:" : "Neue Personal Records:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary.opacity(0.8))

            VStack(alignment: .leading, spacing: 6) {
                ForEach(getTopLifts(type: type), id: \.exercise) { lift in
                    HStack(spacing: 8) {
                        Text("•")
                            .foregroundStyle(lift.isPR ? .yellow : Color.appOrange)

                        Text(lift.exercise)
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(lift.value)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Text(lift.delta)
                            .font(.caption)
                            .foregroundStyle(lift.isPR ? .yellow : .green)

                        if lift.isPR {
                            Text("🎉")
                                .font(.caption)
                        }
                    }
                }
            }
            .padding(.leading, 8)
        }
    }

    private func volumeStatsSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Volumen-Statistiken:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary.opacity(0.8))

            HStack(spacing: 16) {
                VolumeStatItem(
                    title: "Diese Woche",
                    value: calculateWeekVolume(),
                    delta: calculateVolumeChange()
                )

                Divider()
                    .frame(height: 40)

                VolumeStatItem(
                    title: "Durchschnitt",
                    value: calculateAverageVolume(),
                    delta: nil
                )
            }
        }
    }

    private func prCountSection() -> some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(getTotalPRs())")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Color.appOrange)

                Text("Personal Records")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("+\(getRecentPRs())")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)

                Text("diese Woche")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Helper Views

    private struct TabButton: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: {
                AnimationHelper.selectionFeedback()
                withAnimation(AnimationHelper.tabTransition) {
                    action()
                }
            }) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.appOrange : .secondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.appOrange.opacity(0.15) : Color.clear)
                    )
            }
        }
    }

    private struct VolumeStatItem: View {
        let title: String
        let value: String
        let delta: String?

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                if let delta = delta {
                    Text(delta)
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
    }

    // MARK: - Data Helpers

    enum LiftType {
        case weight
        case pr
    }

    struct TopLift {
        let exercise: String
        let value: String
        let delta: String
        let isPR: Bool
    }

    private func getTopLifts(type: LiftType) -> [TopLift] {
        switch type {
        case .weight:
            let topLifts = prService.getTopLiftsByWeight(from: sessions, limit: 3)
            return topLifts.map { lift in
                TopLift(
                    exercise: lift.exerciseName,
                    value: String(format: "%.0f kg", lift.weight),
                    delta: "",  // TODO: Calculate delta from previous weeks
                    isPR: false
                )
            }
        case .pr:
            let recentPRs = prService.getRecentPRs(from: sessions, days: 7)
            return recentPRs.prefix(3).map { pr in
                TopLift(
                    exercise: pr.exerciseName,
                    value: String(format: "%.0f kg", pr.value),
                    delta: "Neuer PR!",
                    isPR: true
                )
            }
        }
    }

    private func calculateWeekVolume() -> String {
        let volume =
            sessions
            .filter { Calendar.current.isDateInThisWeek($0.startDate) }
            .reduce(0.0) { $0 + $1.totalVolume }

        if volume >= 1000 {
            return String(format: "%.1fk kg", volume / 1000)
        } else {
            return String(format: "%.0f kg", volume)
        }
    }

    private func calculateAverageVolume() -> String {
        let weekSessions = sessions.filter { Calendar.current.isDateInThisWeek($0.startDate) }
        guard !weekSessions.isEmpty else { return "0 kg" }

        let avgVolume =
            weekSessions.reduce(0.0) { $0 + $1.totalVolume } / Double(weekSessions.count)

        if avgVolume >= 1000 {
            return String(format: "%.1fk kg", avgVolume / 1000)
        } else {
            return String(format: "%.0f kg", avgVolume)
        }
    }

    private func calculateVolumeChange() -> String {
        // TODO: Calculate actual change from previous week
        return "+12%"
    }

    private func getTotalPRs() -> Int {
        let allPRs = prService.detectPersonalRecords(in: sessions)
        return allPRs.count
    }

    private func getRecentPRs() -> Int {
        let recentPRs = prService.getRecentPRs(from: sessions, days: 7)
        return recentPRs.count
    }

    private func generateSampleData() -> [Double] {
        // Sample trend data for the chart
        [65, 72, 68, 75, 80, 78, 85]
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func isDateInThisWeek(_ date: Date) -> Bool {
        let now = Date()
        guard
            let weekStart = self.date(
                from: dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))
        else {
            return false
        }
        guard let weekEnd = self.date(byAdding: .day, value: 7, to: weekStart) else {
            return false
        }
        return date >= weekStart && date < weekEnd
    }
}

// MARK: - Previews

#Preview("Weight Tab") {
    ZStack {
        Color(uiColor: .systemBackground).ignoresSafeArea()

        VStack {
            ProgressionCard(sessions: [.previewCompleted, .preview])
                .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.top, 20)
    }
}

#Preview("Dark Mode") {
    ZStack {
        Color(uiColor: .systemBackground).ignoresSafeArea()

        VStack {
            ProgressionCard(sessions: [.previewCompleted, .preview])
                .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.top, 20)
    }
    .preferredColorScheme(.dark)
}
