//
//  WorkoutTypeSelectionView.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V6 - Superset/Circuit Training Feature
//

import SwiftUI

/// View for selecting workout type (Standard, Superset, or Circuit)
///
/// **Features:**
/// - Three selectable workout type cards
/// - Visual indication of selected type
/// - Description of each workout type
/// - Icon representation for each type
///
/// **iOS HIG Compliance:**
/// - Clear visual hierarchy
/// - Accessible labels and hints
/// - Proper spacing and padding
/// - Touch targets meet minimum size
struct WorkoutTypeSelectionView: View {

    // MARK: - Binding

    @Binding var selectedType: WorkoutType

    // MARK: - Constants

    private enum Layout {
        static let cardCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 20
        static let spacing: CGFloat = 16
        static let iconSize: CGFloat = 48
        static let selectedBorderWidth: CGFloat = 3
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            // Section header
            Text("Trainingstyp wählen")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            // Workout type cards
            VStack(spacing: 12) {
                WorkoutTypeCard(
                    type: .standard,
                    icon: "list.bullet.rectangle.portrait",
                    title: "Standard",
                    description: "Übungen nacheinander, klassisches Krafttraining",
                    isSelected: selectedType == .standard,
                    onTap: { selectedType = .standard }
                )

                WorkoutTypeCard(
                    type: .superset,
                    icon: "arrow.left.arrow.right",
                    title: "Superset",
                    description: "Übungspaare im Wechsel, zeitsparendes Training",
                    isSelected: selectedType == .superset,
                    onTap: { selectedType = .superset }
                )

                WorkoutTypeCard(
                    type: .circuit,
                    icon: "arrow.triangle.2.circlepath",
                    title: "Zirkeltraining",
                    description: "Alle Stationen durchlaufen, maximale Intensität",
                    isSelected: selectedType == .circuit,
                    onTap: { selectedType = .circuit }
                )
            }
        }
    }
}

// MARK: - Workout Type Card

/// Individual workout type selection card
struct WorkoutTypeCard: View {

    // MARK: - Properties

    let type: WorkoutType
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let onTap: () -> Void

    // MARK: - Constants

    private enum Layout {
        static let cardCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 20
        static let iconSize: CGFloat = 48
        static let selectedBorderWidth: CGFloat = 3
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                        .frame(width: Layout.iconSize, height: Layout.iconSize)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(Layout.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: Layout.selectedBorderWidth
                    )
            )
            .shadow(
                color: isSelected ? Color.accentColor.opacity(0.2) : Color.black.opacity(0.05),
                radius: isSelected ? 8 : 4,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) - \(description)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Preview

#if DEBUG
    #Preview("Workout Type Selection") {
        WorkoutTypeSelectionView(selectedType: .constant(.standard))
            .padding()
            .background(Color(.systemGroupedBackground))
    }

    #Preview("Superset Selected") {
        WorkoutTypeSelectionView(selectedType: .constant(.superset))
            .padding()
            .background(Color(.systemGroupedBackground))
    }

    #Preview("Circuit Selected") {
        WorkoutTypeSelectionView(selectedType: .constant(.circuit))
            .padding()
            .background(Color(.systemGroupedBackground))
    }
#endif
