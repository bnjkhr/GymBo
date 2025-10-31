//
//  AddWarmupSetsSheet.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V2 Clean Architecture - Presentation Layer
//

import SwiftUI

/// Sheet for adding warmup sets to an exercise
///
/// **Features:**
/// - Shows warmup set preview based on working weight
/// - Strategy selection (Standard, Conservative, Minimal)
/// - Visual preview of warmup progression
///
/// **Design:**
/// - Clean iOS 26 card design
/// - Preview of warmup sets before adding
/// - Confirm/Cancel buttons
struct AddWarmupSetsSheet: View {

    // MARK: - Properties

    let workingWeight: Double
    let workingReps: Int
    let onAdd: ([WarmupCalculator.WarmupSet], WarmupCalculator.Strategy) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedStrategy: WarmupCalculator.Strategy = WarmupCalculator.Strategy
        .standard

    // MARK: - Computed Properties

    private var warmupSets: [WarmupCalculator.WarmupSet] {
        WarmupCalculator.calculateWarmupSets(
            workingWeight: workingWeight,
            workingReps: workingReps,
            strategy: selectedStrategy
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Working Set Info
                    workingSetCard

                    // Strategy Selection
                    strategySelection

                    // Warmup Preview
                    warmupPreview
                }
                .padding()
            }
            .navigationTitle("Aufwärmsätze")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        onAdd(warmupSets, selectedStrategy)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Subviews

    private var workingSetCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Arbeitssatz")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(formatWeight(workingWeight))")
                            .font(.system(size: 32, weight: .bold))
                            .monospacedDigit()
                        Text("kg")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }

                    Text("\(workingReps) Wiederholungen")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private var strategySelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strategie")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 8) {
                StrategyButton(
                    title: "Standard",
                    subtitle: "3 Sätze: 40%, 60%, 80%",
                    isSelected: selectedStrategy == WarmupCalculator.Strategy.standard,
                    action: { selectedStrategy = WarmupCalculator.Strategy.standard }
                )

                StrategyButton(
                    title: "Konservativ",
                    subtitle: "4 Sätze: 30%, 50%, 70%, 85%",
                    isSelected: selectedStrategy == WarmupCalculator.Strategy.conservative,
                    action: { selectedStrategy = WarmupCalculator.Strategy.conservative }
                )

                StrategyButton(
                    title: "Minimal",
                    subtitle: "2 Sätze: 50%, 75%",
                    isSelected: selectedStrategy == WarmupCalculator.Strategy.minimal,
                    action: { selectedStrategy = WarmupCalculator.Strategy.minimal }
                )
            }
        }
    }

    private var warmupPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vorschau")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 8) {
                ForEach(Array(warmupSets.enumerated()), id: \.offset) { index, warmupSet in
                    WarmupSetPreviewRow(
                        setNumber: index + 1,
                        warmupSet: warmupSet
                    )
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        } else {
            return String(format: "%.1f", weight)
        }
    }
}

// MARK: - Strategy Button

private struct StrategyButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? .orange : .primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }
            }
            .padding(14)
            .background(
                isSelected
                    ? Color.orange.opacity(0.05)
                    : Color(.secondarySystemGroupedBackground)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Warmup Set Preview Row

private struct WarmupSetPreviewRow: View {
    let setNumber: Int
    let warmupSet: WarmupCalculator.WarmupSet

    var body: some View {
        HStack(spacing: 16) {
            // Warmup Badge
            Text("W")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.orange)
                .frame(width: 24, height: 24)
                .background(Color.orange.opacity(0.1))
                .clipShape(Circle())

            // Weight
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(formatWeight(warmupSet.weight))
                    .font(.system(size: 24, weight: .bold))
                    .monospacedDigit()

                Text("kg")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }

            // Reps
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(warmupSet.reps)")
                    .font(.system(size: 24, weight: .bold))
                    .monospacedDigit()

                Text("reps")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }

            Spacer()

            // Percentage
            Text("\(Int(warmupSet.percentageOfMax * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(6)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        } else {
            return String(format: "%.1f", weight)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    AddWarmupSetsSheet(
        workingWeight: 100.0,
        workingReps: 8,
        onAdd: { sets, strategy in
            print("Adding \(sets.count) warmup sets with \(strategy)")
        }
    )
}
#endif
