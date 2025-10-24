//
//  ExerciseDetailView.swift
//  GymBo
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Exercise Detail View
//

import SwiftUI

/// Detail view for a single exercise showing all information
///
/// **Features:**
/// - Exercise name and icon
/// - Muscle groups (primary and secondary)
/// - Equipment required
/// - Difficulty level
/// - Future: Description, video, tips
///
/// **Design:**
/// - Modern card-based layout
/// - Clean information hierarchy
/// - iOS 26 design standards
struct ExerciseDetailView: View {

    let exercise: ExerciseEntity

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Exercise Header
                exerciseHeader

                // Equipment Section
                if !exercise.equipmentTypeRaw.isEmpty {
                    infoSection(
                        title: "Equipment",
                        icon: equipmentIcon,
                        content: exercise.equipmentTypeRaw
                    )
                }

                // Muscle Groups Section
                if !exercise.muscleGroupsRaw.isEmpty {
                    muscleGroupsSection
                }

                // Difficulty Section
                if !exercise.difficultyLevelRaw.isEmpty {
                    infoSection(
                        title: "Schwierigkeit",
                        icon: "chart.bar.fill",
                        content: exercise.difficultyLevelRaw
                    )
                }

                // Placeholder for future content
                placeholderSections
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Subviews

    private var exerciseHeader: some View {
        VStack(spacing: 16) {
            // Large Icon
            Image(systemName: equipmentIcon)
                .font(.system(size: 60))
                .foregroundStyle(.primary)
                .frame(width: 100, height: 100)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(Circle())

            // Exercise Name
            Text(exercise.name)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var muscleGroupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: "figure.arms.open")
                    .font(.body)
                    .foregroundStyle(.primary)

                Text("Muskelgruppen")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }

            // Muscle Group Pills
            FlowLayout(spacing: 8) {
                ForEach(exercise.muscleGroupsRaw, id: \.self) { group in
                    Text(group)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                }
            }
        }
    }

    private func infoSection(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }

            // Content Card
            Text(content)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
        }
    }

    private var placeholderSections: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: "info.circle")
                    .font(.body)
                    .foregroundStyle(.primary)

                Text("Weitere Informationen")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }

            // Placeholder Content
            VStack(alignment: .leading, spacing: 8) {
                placeholderRow(icon: "text.alignleft", title: "Beschreibung")
                placeholderRow(icon: "play.rectangle", title: "Video-Anleitung")
                placeholderRow(icon: "lightbulb", title: "Tipps & Hinweise")
            }

            Text("Wird in zukünftigen Updates hinzugefügt")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .padding(.top, 4)
        }
    }

    private func placeholderRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(title)
                .font(.body)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Helper Properties

    private var equipmentIcon: String {
        switch exercise.equipmentTypeRaw.lowercased() {
        case "langhantel": return "figure.strengthtraining.traditional"
        case "kurzhantel": return "dumbbell.fill"
        case "bodyweight": return "figure.walk"
        case "maschine": return "gearshape.fill"
        case "kabelzug": return "arrow.left.and.right"
        default: return "dumbbell.fill"
        }
    }
}

// MARK: - Flow Layout for Pills

/// Simple flow layout for wrapping content
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.frames[index].minX,
                    y: bounds.minY + result.frames[index].minY),
                proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize
        var frames: [CGRect]

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var frames: [CGRect] = []
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    // New line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(
                    CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.frames = frames
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ExerciseDetailView(
            exercise: ExerciseEntity(
                id: UUID(),
                name: "Bankdrücken",
                muscleGroupsRaw: ["Brust", "Schultern", "Trizeps"],
                equipmentTypeRaw: "Langhantel",
                difficultyLevelRaw: "Fortgeschritten"
            )
        )
    }
}
