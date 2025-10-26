//
//  QuickSetupView.swift
//  GymBo
//
//  Created on 2025-10-26.
//  Quick-Setup Feature - 3-Step Wizard
//

import SwiftUI

/// Quick-Setup workout creation wizard
struct QuickSetupView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: Step = .equipment
    @State private var selectedEquipment: Set<EquipmentCategory> = []
    @State private var selectedDuration: WorkoutDuration = .medium
    @State private var selectedGoal: WorkoutGoal = .fullBody

    let onComplete: (QuickSetupConfig) -> Void

    enum Step: Int, CaseIterable {
        case equipment = 0
        case duration = 1
        case goal = 2

        var title: String {
            switch self {
            case .equipment: return "Verfügbare Geräte"
            case .duration: return "Trainingsdauer"
            case .goal: return "Trainingsziel"
            }
        }

        var subtitle: String {
            switch self {
            case .equipment: return "Welche Geräte hast du zur Verfügung?"
            case .duration: return "Wie lange möchtest du trainieren?"
            case .goal: return "Was möchtest du trainieren?"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Indicator
                progressIndicator

                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Step Title
                        VStack(spacing: 8) {
                            Text(currentStep.title)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(currentStep.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 24)

                        // Step Content
                        Group {
                            switch currentStep {
                            case .equipment:
                                equipmentSelectionView
                            case .duration:
                                durationSelectionView
                            case .goal:
                                goalSelectionView
                            }
                        }
                        .animation(.easeInOut, value: currentStep)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)  // Space for bottom button
                }

                // Bottom Button
                bottomButton
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(Step.allCases, id: \.self) { step in
                Capsule()
                    .fill(
                        step.rawValue <= currentStep.rawValue
                            ? Color.appOrange : Color(.tertiarySystemGroupedBackground)
                    )
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Step 1: Equipment Selection

    private var equipmentSelectionView: some View {
        VStack(spacing: 12) {
            ForEach(EquipmentCategory.allCases) { equipment in
                EquipmentToggleCard(
                    equipment: equipment,
                    isSelected: selectedEquipment.contains(equipment),
                    onToggle: {
                        if selectedEquipment.contains(equipment) {
                            selectedEquipment.remove(equipment)
                        } else {
                            selectedEquipment.insert(equipment)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Step 2: Duration Selection

    private var durationSelectionView: some View {
        VStack(spacing: 12) {
            ForEach(WorkoutDuration.allCases) { duration in
                DurationCard(
                    duration: duration,
                    isSelected: selectedDuration == duration,
                    onSelect: {
                        selectedDuration = duration
                    }
                )
            }
        }
    }

    // MARK: - Step 3: Goal Selection

    private var goalSelectionView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(WorkoutGoal.allCases) { goal in
                GoalCard(
                    goal: goal,
                    isSelected: selectedGoal == goal,
                    onSelect: {
                        selectedGoal = goal
                    }
                )
            }
        }
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: handleNextOrGenerate) {
                HStack {
                    Text(isLastStep ? "Workout generieren" : "Weiter")
                        .font(.headline)

                    if !isLastStep {
                        Image(systemName: "arrow.right")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canProceed ? Color.appOrange : Color.secondary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!canProceed)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Helpers

    private var isLastStep: Bool {
        currentStep == .goal
    }

    private var canProceed: Bool {
        switch currentStep {
        case .equipment:
            return !selectedEquipment.isEmpty
        case .duration:
            return true  // Always valid (has default)
        case .goal:
            return true  // Always valid (has default)
        }
    }

    private func handleNextOrGenerate() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if isLastStep {
            // Generate workout
            let config = QuickSetupConfig(
                availableEquipment: selectedEquipment,
                duration: selectedDuration,
                goal: selectedGoal
            )
            dismiss()
            onComplete(config)
        } else {
            // Go to next step
            if let nextStep = Step(rawValue: currentStep.rawValue + 1) {
                withAnimation {
                    currentStep = nextStep
                }
            }
        }
    }
}

// MARK: - Equipment Toggle Card

private struct EquipmentToggleCard: View {
    let equipment: EquipmentCategory
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onToggle()
        }) {
            HStack(spacing: 16) {
                Image(systemName: equipment.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .appOrange : .secondary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )

                Text(equipment.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .appOrange : .secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.appOrange : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Duration Card

private struct DurationCard: View {
    let duration: WorkoutDuration
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onSelect()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(duration.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("~\(duration.recommendedExerciseCount) Übungen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .appOrange : .secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.appOrange : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Goal Card

private struct GoalCard: View {
    let goal: WorkoutGoal
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onSelect()
        }) {
            VStack(spacing: 12) {
                Image(systemName: goal.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .appOrange : .secondary)
                    .frame(height: 44)

                Text(goal.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.appOrange : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    QuickSetupView { config in
        print("Config: \(config)")
    }
}
