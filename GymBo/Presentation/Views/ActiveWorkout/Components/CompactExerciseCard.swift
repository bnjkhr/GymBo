//
//  CompactExerciseCard.swift
//  GymBo
//
//  Created on 2025-10-22.
//  Active Workout Redesign - Compact Exercise Card
//

import SwiftUI

/// Compact exercise card for the new ScrollView-based design
///
/// **Features:**
/// - Exercise header (name, equipment, indicator)
/// - Compact set rows (weight | reps | checkbox)
/// - Quick-add field for new sets or notes
/// - Context menu for options
///
/// **Design:**
/// - White card with 39pt corner radius (matches iPhone)
/// - Minimal shadow (radius: 4pt, y: 1pt)
/// - Bold fonts (28pt for weight, 24pt for reps)
/// - 20pt horizontal padding
struct CompactExerciseCard: View {

    // MARK: - Properties

    let exercise: DomainSessionExercise
    let exerciseIndex: Int
    let totalExercises: Int
    let exerciseName: String  // TODO: Load from repository
    let equipment: String?  // TODO: Load from repository

    /// Callbacks
    let onToggleCompletion: ((UUID) -> Void)?  // Set ID (not index!)
    let onUpdateWeight: ((UUID, Double) -> Void)?  // (setId, newWeight)
    let onUpdateReps: ((UUID, Int) -> Void)?  // (setId, newReps)
    let onUpdateAllSets: ((Double, Int) -> Void)?  // (weight, reps) - updates all incomplete sets
    let onAddSet: ((Double, Int) -> Void)?  // (weight, reps) - Add new set
    let onRemoveSet: ((UUID) -> Void)?  // (setId) - Remove set
    let onMarkAllComplete: (() -> Void)?
    let onReorder: (() -> Void)?  // Show reorder sheet

    // MARK: - State

    @State private var quickAddText: String = ""

    // MARK: - Layout Constants

    private enum Layout {
        static let headerPadding: CGFloat = 24
        static let setPadding: CGFloat = 24
        static let cornerRadius: CGFloat = 39
        static let shadowRadius: CGFloat = 4
        static let shadowY: CGFloat = 1
        static let indicatorSize: CGFloat = 8
    }

    private enum Typography {
        static let nameFontSize: CGFloat = 20
        static let weightFontSize: CGFloat = 28
        static let repsFontSize: CGFloat = 24
        static let unitFontSize: CGFloat = 14
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            exerciseHeader
                .padding(.horizontal, Layout.headerPadding)
                .padding(.top, 16)

            // Sets
            VStack(spacing: 4) {
                ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                    CompactSetRow(
                        set: set,
                        setNumber: index + 1,
                        onToggle: {
                            onToggleCompletion?(set.id)  // Pass setId, not index!
                        },
                        onUpdateWeight: { newWeight in
                            onUpdateWeight?(set.id, newWeight)
                        },
                        onUpdateReps: { newReps in
                            onUpdateReps?(set.id, newReps)
                        },
                        onUpdateAllSets: { weight, reps in
                            onUpdateAllSets?(weight, reps)
                        }
                    )
                    .padding(.horizontal, Layout.setPadding)
                    .contextMenu {
                        // Only show delete if not the last set
                        if exercise.sets.count > 1 {
                            Button(role: .destructive) {
                                onRemoveSet?(set.id)
                            } label: {
                                Label("Satz löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.top, 12)

            // Quick-add field
            quickAddField
                .padding(.horizontal, Layout.headerPadding)
                .padding(.vertical, 12)

            // Bottom buttons
            bottomButtons
                .padding(.horizontal, Layout.headerPadding)
                .padding(.bottom, 16)
        }
        .background(Color.white)
        .cornerRadius(Layout.cornerRadius)
        .shadow(color: .black.opacity(0.1), radius: Layout.shadowRadius, y: Layout.shadowY)
    }

    // MARK: - Subviews

    /// Exercise header with name and equipment
    private var exerciseHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            // Name and equipment
            VStack(alignment: .leading, spacing: 2) {
                Text(exerciseName)
                    .font(.system(size: Typography.nameFontSize, weight: .semibold))

                if let equipment = equipment {
                    Text(equipment)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    /// Quick-add field for sets or notes
    private var quickAddField: some View {
        TextField("Neuer Satz oder Notiz", text: $quickAddText)
            .textFieldStyle(.plain)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .onSubmit {
                handleQuickAdd()
            }
    }

    /// Bottom action buttons
    private var bottomButtons: some View {
        print("🟢 bottomButtons computed - exercise: \(exercise.id)")
        return HStack(spacing: 16) {
            // Mark all complete (✓)
            Button(action: handleMarkAllComplete) {
                Image(systemName: "checkmark.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Add set (+)
            Button(action: handleAddSet) {
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Reorder (↕)
            Button(action: handleReorder) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Button Actions

    private func handleMarkAllComplete() {
        print("🔴🔴🔴 BUTTON ACTION: Mark All Complete")
        print("🔴 Thread: \(Thread.current)")
        print("🔴 Is main thread: \(Thread.isMainThread)")
        print("🔴 Call stack:")
        Thread.callStackSymbols.prefix(10).forEach { print("  \($0)") }
        onMarkAllComplete?()
    }

    private func handleAddSet() {
        print("🟠🟠🟠 BUTTON ACTION: Add Set")
        print("🟠 Thread: \(Thread.current)")
        print("🟠 Is main thread: \(Thread.isMainThread)")
        print("🟠 Call stack:")
        Thread.callStackSymbols.prefix(10).forEach { print("  \($0)") }

        let lastSet = exercise.sets.last
        let weight = lastSet?.weight ?? 0.0
        let reps = lastSet?.reps ?? 0

        if weight > 0 && reps > 0 {
            onAddSet?(weight, reps)
        }
    }

    private func handleReorder() {
        print("🔵🔵🔵 BUTTON ACTION: Reorder")
        onReorder?()
    }

    // MARK: - Actions

    /// Handle quick-add input
    private func handleQuickAdd() {
        let trimmed = quickAddText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Try to parse as set (e.g., "100 x 8")
        if let (weight, reps) = parseSetInput(trimmed) {
            print("➕ Quick-add set: \(weight)kg x \(reps) reps")
            onAddSet?(weight, reps)
        } else {
            // Save as note
            print("📝 Quick-add note: \(trimmed)")
            // TODO: Save note via callback (future feature)
        }

        quickAddText = ""
    }

    /// Parse set input (e.g., "100 x 8" or "100x8")
    private func parseSetInput(_ input: String) -> (weight: Double, reps: Int)? {
        let pattern = #"(\d+(?:\.\d+)?)\s*[xX×]\s*(\d+)"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
            match.numberOfRanges == 3
        else {
            return nil
        }

        let weightRange = Range(match.range(at: 1), in: input)!
        let repsRange = Range(match.range(at: 2), in: input)!

        guard let weight = Double(input[weightRange]),
            let reps = Int(input[repsRange])
        else {
            return nil
        }

        return (weight, reps)
    }
}

// MARK: - Previews

#Preview("Single Exercise") {
    CompactExerciseCard(
        exercise: .preview,
        exerciseIndex: 0,
        totalExercises: 3,
        exerciseName: "Bankdrücken",
        equipment: "Barbell",
        onToggleCompletion: { _ in },
        onUpdateWeight: { _, _ in },
        onUpdateReps: { _, _ in },
        onUpdateAllSets: { _, _ in },
        onAddSet: { _, _ in },
        onRemoveSet: { _ in },
        onMarkAllComplete: {},
        onReorder: {}
    )
    .padding()
}

#Preview("With Notes") {
    CompactExerciseCard(
        exercise: .previewWithNotes,
        exerciseIndex: 1,
        totalExercises: 3,
        exerciseName: "Lat Pulldown",
        equipment: "Cable",
        onToggleCompletion: { _ in },
        onUpdateWeight: { _, _ in },
        onUpdateReps: { _, _ in },
        onUpdateAllSets: { _, _ in },
        onAddSet: { _, _ in },
        onRemoveSet: { _ in },
        onMarkAllComplete: {},
        onReorder: {}
    )
    .padding()
}
