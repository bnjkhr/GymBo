//
//  CompactSetRow.swift
//  GymBo
//
//  Created on 2025-10-22.
//

import SwiftUI

struct CompactSetRow: View {

    let set: DomainSessionSet
    let setNumber: Int
    let onToggle: () -> Void
    let onUpdateWeight: ((Double) -> Void)?
    let onUpdateReps: ((Int) -> Void)?
    let onUpdateAllSets: ((Double, Int) -> Void)?

    @State private var showEditSheet = false
    @State private var editingWeight: String = ""
    @State private var editingReps: String = ""

    var body: some View {
        HStack(spacing: 16) {
            // Weight (Tappable)
            Button {
                if !set.completed {
                    editingWeight = formatNumber(set.weight)
                    editingReps = "\(set.reps)"
                    showEditSheet = true
                }
            } label: {
                HStack(spacing: 4) {
                    Text(formatNumber(set.weight))
                        .font(.system(size: 28, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(set.completed ? .gray : .primary)

                    Text("kg")
                        .font(.system(size: 16))
                        .foregroundStyle(.gray)
                }
            }

            .buttonStyle(.plain)

            // Reps (Tappable)
            Button {
                if !set.completed {
                    editingWeight = formatNumber(set.weight)
                    editingReps = "\(set.reps)"
                    showEditSheet = true
                }
            } label: {
                HStack(spacing: 4) {
                    Text("\(set.reps)")
                        .font(.system(size: 28, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(set.completed ? .gray : .primary)

                    Text("reps")
                        .font(.system(size: 16))
                        .foregroundStyle(.gray)
                }
            }

            .buttonStyle(.plain)

            Spacer()

            // Checkbox
            Button {
                onToggle()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 32))
                    .foregroundStyle(set.completed ? .green : .gray.opacity(0.3))
            }
            .disabled(set.completed)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .sheet(isPresented: $showEditSheet) {
            EditSetSheet(
                weight: $editingWeight,
                reps: $editingReps,
                onSave: { updateAll in
                    saveChanges(updateAll: updateAll)
                }
            )
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Helper Methods

    private func formatNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }

    private func saveChanges(updateAll: Bool) {
        // Parse and validate values
        guard let weight = Double(editingWeight), weight > 0,
              let reps = Int(editingReps), reps > 0 else {
            return
        }

        if updateAll {
            // Update all sets in exercise
            onUpdateAllSets?(weight, reps)
        } else {
            // Update only this set
            onUpdateWeight?(weight)
            onUpdateReps?(reps)
        }
    }
}
// MARK: - Edit Sheet

struct EditSetSheet: View {
    @Binding var weight: String
    @Binding var reps: String
    let onSave: (Bool) -> Void  // Bool = updateAll

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var updateAllSets: Bool = false

    enum Field {
        case weight, reps
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Weight Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gewicht")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField("100", text: $weight)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 32, weight: .bold))
                            .focused($focusedField, equals: .weight)

                        Text("kg")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Reps Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wiederholungen")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField("8", text: $reps)
                            .keyboardType(.numberPad)
                            .font(.system(size: 32, weight: .bold))
                            .focused($focusedField, equals: .reps)

                        Text("reps")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Update All Sets Toggle
                Toggle(isOn: $updateAllSets) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alle Sätze aktualisieren")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Werte für alle verbleibenden Sätze übernehmen")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.orange)
                .padding(.top, 8)

                Spacer()
            }
            .padding()
            .navigationTitle("Satz bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        onSave(updateAllSets)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Auto-focus weight field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    focusedField = .weight
                }
            }
        }
    }
}
