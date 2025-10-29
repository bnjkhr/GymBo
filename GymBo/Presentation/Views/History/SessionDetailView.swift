//
//  SessionDetailView.swift
//  GymBo
//
//  Created on 2025-10-29.
//  V2 Clean Architecture - Presentation Layer
//

import SwiftUI

/// Read-only view displaying details of a completed workout session
///
/// **Features:**
/// - Session overview (duration, volume, date)
/// - Exercise list with all sets
/// - Performance metrics
/// - Share functionality
///
/// **Usage:**
/// ```swift
/// SessionDetailView(session: completedSession)
/// ```
struct SessionDetailView: View {

    let session: DomainWorkoutSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header with overview
                        sessionOverview
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        // Exercises
                        VStack(spacing: 16) {
                            ForEach(session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }))
                            { exercise in
                                ExerciseDetailCard(exercise: exercise)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    shareButton
                }
            }
        }
    }

    // MARK: - Subviews

    private var sessionOverview: some View {
        VStack(spacing: 20) {
            // Workout Name & Date
            VStack(spacing: 8) {
                Text(session.workoutName ?? "Workout")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(formatFullDate(session.startDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Key Metrics
            HStack(spacing: 0) {
                MetricView(
                    icon: "clock.fill",
                    value: session.formattedDuration,
                    label: "Dauer"
                )

                Divider()
                    .background(Color.white.opacity(0.1))
                    .frame(height: 40)

                MetricView(
                    icon: "scalemass.fill",
                    value: String(format: "%.0f kg", session.totalVolume),
                    label: "Volumen"
                )

                Divider()
                    .background(Color.white.opacity(0.1))
                    .frame(height: 40)

                MetricView(
                    icon: "checkmark.circle.fill",
                    value: "\(session.completedSets)",
                    label: "Sets"
                )
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var shareButton: some View {
        Button(action: shareWorkout) {
            Image(systemName: "square.and.arrow.up")
                .foregroundStyle(.white)
        }
    }

    // MARK: - Actions

    private func shareWorkout() {
        // TODO: Implement share functionality
        // Could share as text, image, or to social media
    }

    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Metric View

struct MetricView: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
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
    }
}

// MARK: - Exercise Detail Card

struct ExerciseDetailCard: View {
    let exercise: DomainSessionExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Exercise Header
            HStack {
                Text(exercise.exerciseName)
                    .font(.headline)
                    .foregroundStyle(.black)

                Spacer()

                if exercise.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            // Sets
            VStack(spacing: 8) {
                ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                    SetDetailRow(setNumber: index + 1, set: set)
                }
            }

            // Exercise Notes
            if let notes = exercise.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notizen")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(.black)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
        )
    }
}

// MARK: - Set Detail Row

struct SetDetailRow: View {
    let setNumber: Int
    let set: DomainSessionSet

    var body: some View {
        HStack(spacing: 16) {
            // Set Number
            Text("Set \(setNumber)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            // Weight
            HStack(spacing: 4) {
                Image(systemName: "scalemass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1f kg", set.weight))
                    .font(.subheadline)
                    .foregroundStyle(.black)
            }
            .frame(width: 80, alignment: .leading)

            // Reps
            HStack(spacing: 4) {
                Image(systemName: "repeat")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(set.reps) Wdh")
                    .font(.subheadline)
                    .foregroundStyle(.black)
            }
            .frame(width: 70, alignment: .leading)

            Spacer()

            // Completion Status
            if set.completed {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(set.completed ? Color.green.opacity(0.05) : Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Previews

#Preview {
    SessionDetailView(session: .previewCompleted)
}
