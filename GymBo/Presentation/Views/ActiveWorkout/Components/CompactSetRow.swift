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

    // Local state for editing
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case weight
        case reps
    }

    var body: some View {
        HStack(spacing: 16) {
            // Weight TextField
            HStack(spacing: 4) {
                TextField("", text: $weightText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(set.completed ? .gray : .primary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .frame(minWidth: 50)
                    .focused($focusedField, equals: .weight)
                    .disabled(set.completed)
                    .onSubmit {
                        saveWeight()
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Fertig") {
                                saveCurrentField()
                                focusedField = nil
                            }
                        }
                    }

                Text("kg")
                    .font(.system(size: 16))
                    .foregroundStyle(.gray)
            }

            // Reps TextField
            HStack(spacing: 4) {
                TextField("", text: $repsText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(set.completed ? .gray : .primary)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.leading)
                    .frame(minWidth: 40)
                    .focused($focusedField, equals: .reps)
                    .disabled(set.completed)
                    .onSubmit {
                        saveReps()
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Fertig") {
                                saveCurrentField()
                                focusedField = nil
                            }
                        }
                    }

                Text("reps")
                    .font(.system(size: 16))
                    .foregroundStyle(.gray)
            }

            Spacer()

            // Checkbox
            Button {
                saveCurrentField()
                focusedField = nil
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
        .onAppear {
            // Initialize text fields with current values
            weightText = formatNumber(set.weight)
            repsText = "\(set.reps)"
        }
        .onChange(of: set.weight) { _, newValue in
            // Update text when set changes externally
            if focusedField != .weight {
                weightText = formatNumber(newValue)
            }
        }
        .onChange(of: set.reps) { _, newValue in
            // Update text when set changes externally
            if focusedField != .reps {
                repsText = "\(newValue)"
            }
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

    private func saveCurrentField() {
        switch focusedField {
        case .weight:
            saveWeight()
        case .reps:
            saveReps()
        case nil:
            break
        }
    }

    private func saveWeight() {
        guard let weight = Double(weightText), weight > 0 else {
            // Revert to original value if invalid
            weightText = formatNumber(set.weight)
            return
        }
        onUpdateWeight?(weight)
    }

    private func saveReps() {
        guard let reps = Int(repsText), reps > 0 else {
            // Revert to original value if invalid
            repsText = "\(set.reps)"
            return
        }
        onUpdateReps?(reps)
    }
}
