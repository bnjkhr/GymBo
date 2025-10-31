//
//  SessionTimelineCard.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V2 Clean Architecture - Presentation Layer
//

import SwiftUI

/// Timeline card for individual workout sessions (Variante B: Detailed with Insights)
///
/// **Features:**
/// - Workout icon and name
/// - Date and time
/// - 3-column stats (Duration, Sets, Volume)
/// - Highlights section with insights (PRs, improvements, achievements)
/// - Glassmorphism design
///
/// **Layout:**
/// ```
/// ┌────────────────────────────────────┐
/// │ [ICON] Push Day      Heute, 10:30  │
/// │                                    │
/// │ ┌─────────┬──────────┬──────────┐ │
/// │ │ 1:15 Std│ 48 Sets  │ 3.2k kg  │ │
/// │ └─────────┴──────────┴──────────┘ │
/// │                                    │
/// │ Highlights:                        │
/// │ • Neuer PR: Kreuzheben 160kg 🎉   │
/// │ • +5kg auf Bankdrücken 💪         │
/// │ • Schnellstes Workout diese W. ⚡  │
/// └────────────────────────────────────┘
/// ```
struct SessionTimelineCard: View {

    let session: DomainWorkoutSession
    let insights: [WorkoutInsight]  // Auto-generated insights

    init(session: DomainWorkoutSession) {
        self.session = session
        self.insights = WorkoutInsight.generate(from: session)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Icon + Name + Date
            header

            // Stats Row (3 columns)
            statsRow

            // Highlights/Insights
            if !insights.isEmpty {
                highlightsSection
            }
        }
        .padding(16)
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

    // MARK: - Subviews

    private var header: some View {
        HStack(spacing: 12) {
            // Workout Icon
            workoutIcon

            // Workout Name
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutName ?? "Workout")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(formatDateTime(session.startDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Completion Badge
            if session.state == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
        }
    }

    private var workoutIcon: some View {
        ZStack {
            Circle()
                .fill(Color.appOrange.opacity(0.2))
                .frame(width: 44, height: 44)

            Image(systemName: workoutIconName)
                .font(.title3)
                .foregroundStyle(Color.appOrange)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            // Duration
            StatColumn(
                icon: "clock.fill",
                value: session.formattedDuration,
                label: "Dauer"
            )

            Divider()
                .background(Color.white.opacity(0.1))
                .frame(height: 40)

            // Sets
            StatColumn(
                icon: "checkmark.circle.fill",
                value: "\(session.completedSets)",
                label: "Sets"
            )

            Divider()
                .background(Color.white.opacity(0.1))
                .frame(height: 40)

            // Volume
            StatColumn(
                icon: "scalemass.fill",
                value: formatVolume(session.totalVolume),
                label: "Volumen"
            )
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Highlights")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary.opacity(0.8))

            VStack(alignment: .leading, spacing: 6) {
                ForEach(insights.prefix(3)) { insight in
                    HStack(spacing: 8) {
                        Text("•")
                            .foregroundStyle(insight.color)

                        Text(insight.icon)
                            .font(.caption)

                        Text(insight.message)
                            .font(.caption)
                            .foregroundStyle(.primary.opacity(0.9))
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    private struct StatColumn: View {
        let icon: String
        let value: String
        let label: String

        var body: some View {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(Color.appOrange.opacity(0.8))

                Text(value)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers

    private var workoutIconName: String {
        // TODO: Map workout type to icon
        // For now, use default strength training icon
        "figure.strengthtraining.traditional"
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk kg", volume / 1000)
        } else {
            return String(format: "%.0f kg", volume)
        }
    }
}

// MARK: - Workout Insight Model

/// Auto-generated insights about a workout session
struct WorkoutInsight: Identifiable {
    let id = UUID()
    let icon: String
    let message: String
    let type: InsightType

    enum InsightType {
        case achievement  // PRs, milestones
        case progress  // Improvements, gains
        case reminder  // Streaks, goals
        case speed  // Fastest/slowest workout

        var color: Color {
            switch self {
            case .achievement: return .yellow
            case .progress: return .green
            case .reminder: return .orange
            case .speed: return .blue
            }
        }
    }

    var color: Color {
        type.color
    }

    /// Generate insights from a workout session
    static func generate(from session: DomainWorkoutSession) -> [WorkoutInsight] {
        var insights: [WorkoutInsight] = []

        // TODO: Implement proper insight generation with:
        // - PR detection (compare with previous sessions)
        // - Weight progression (compare exercise weights)
        // - Speed comparison (fastest/slowest workout)
        // - Volume milestones (e.g., "First time over 3000kg!")
        // - Completion rate (100% = 🎉)

        // Placeholder: Completion insight
        if session.progress >= 1.0 {
            insights.append(
                WorkoutInsight(
                    icon: "🎉",
                    message: "100% aller Sets abgeschlossen",
                    type: .achievement
                )
            )
        }

        // Placeholder: Volume milestone
        if session.totalVolume >= 3000 {
            insights.append(
                WorkoutInsight(
                    icon: "💪",
                    message: String(format: "Starkes Volumen: %.0f kg", session.totalVolume),
                    type: .progress
                )
            )
        }

        // Placeholder: Long workout
        if session.duration >= 3600 {  // 1 hour
            insights.append(
                WorkoutInsight(
                    icon: "⏱️",
                    message: "Intensives Training: \(session.formattedDuration)",
                    type: .speed
                )
            )
        }

        return insights
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Completed Session") {
    ZStack {
        Color(uiColor: .systemBackground).ignoresSafeArea()

        VStack {
            SessionTimelineCard(session: .previewCompleted)
                .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.top, 20)
    }
}
#endif

#if DEBUG
#Preview("Active Session") {
    ZStack {
        Color(uiColor: .systemBackground).ignoresSafeArea()

        VStack {
            SessionTimelineCard(session: .preview)
                .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.top, 20)
    }
}
#endif

#if DEBUG
#Preview("High Volume Session") {
    ZStack {
        Color(uiColor: .systemBackground).ignoresSafeArea()

        VStack {
            SessionTimelineCard(
                session: DomainWorkoutSession(
                    id: UUID(),
                    workoutId: UUID(),
                    startDate: Date().addingTimeInterval(-3700),
                    endDate: Date(),
                    exercises: [.preview, .preview, .previewWithNotes],
                    state: .completed,
                    workoutName: "Push Day"
                )
            )
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.top, 20)
    }
}
#endif
