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
    let onExerciseDeleted: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencyContainer) private var dependencyContainer

    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    init(exercise: ExerciseEntity, onExerciseDeleted: (() -> Void)? = nil) {
        self.exercise = exercise
        self.onExerciseDeleted = onExerciseDeleted
    }

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

                // Description Section
                if !exercise.descriptionText.isEmpty {
                    infoSection(
                        title: "Beschreibung",
                        icon: "text.alignleft",
                        content: exercise.descriptionText
                    )
                }

                // Instructions Section
                if !exercise.instructions.isEmpty {
                    instructionsSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            // Only show delete button for custom exercises
            if exercise.createdAt != nil {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .disabled(isDeleting)
                }
            }
        }
        .confirmationDialog(
            "Übung löschen?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) {
                Task {
                    await deleteExercise()
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Diese Aktion kann nicht rückgängig gemacht werden.")
        }
        .alert("Fehler", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .disabled(isDeleting)
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

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: "list.number")
                    .font(.body)
                    .foregroundStyle(.primary)

                Text("Anleitung")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }

            // Instruction Steps
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(exercise.instructions.enumerated()), id: \.offset) {
                    index, instruction in
                    HStack(alignment: .top, spacing: 12) {
                        // Step Number
                        Text("\(index + 1)")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.accentColor)
                            .clipShape(Circle())

                        // Step Text
                        Text(instruction)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Actions

    @MainActor
    private func deleteExercise() async {
        isDeleting = true
        defer { isDeleting = false }

        guard let container = dependencyContainer else {
            errorMessage = "Dependency Container nicht verfügbar"
            return
        }

        // Create use case
        let repository = container.makeExerciseRepository()
        let useCase = DefaultDeleteExerciseUseCase(exerciseRepository: repository)

        do {
            try await useCase.execute(exerciseId: exercise.id)
            print("✅ Deleted exercise: \(exercise.name)")

            // Dismiss detail view
            dismiss()

            // Call callback to refresh list
            onExerciseDeleted?()

        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to delete exercise: \(error)")
        }
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
                difficultyLevelRaw: "Fortgeschritten",
                descriptionText: "Langhantel von der Brust nach oben drücken",
                instructions: [
                    "Auf flacher Bank liegen",
                    "Langhantel etwas breiter als schulterbreit greifen",
                    "Zur Brust absenken",
                    "Nach oben drücken bis Arme gestreckt",
                ]
            )
        )
    }
}
