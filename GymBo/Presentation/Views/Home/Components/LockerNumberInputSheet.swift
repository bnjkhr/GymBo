//
//  LockerNumberInputSheet.swift
//  GymTracker
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Locker Number Input
//

import SwiftUI

/// Sheet for entering or changing locker number
struct LockerNumberInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lockerNumber") private var storedLockerNumber: String?

    @State private var inputNumber: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding(.top, 40)

                // Title & Description
                VStack(spacing: 8) {
                    Text("Spintnummer")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Gib deine Spintnummer ein, damit du sie nicht vergisst")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Input Field
                TextField("Nummer", text: $inputNumber)
                    .keyboardType(.numberPad)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal, 40)
                    .focused($isInputFocused)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveNumber()
                    }
                    .disabled(inputNumber.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Pre-fill with existing number if available
                inputNumber = storedLockerNumber ?? ""
                // Auto-focus input field
                isInputFocused = true
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Actions

    private func saveNumber() {
        // Trim whitespace and validate
        let trimmed = inputNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { return }

        // Save to AppStorage
        storedLockerNumber = trimmed

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Dismiss sheet
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    LockerNumberInputSheet()
}

#Preview("With Existing Number") {
    LockerNumberInputSheet()
        .onAppear {
            UserDefaults.standard.set("127", forKey: "lockerNumber")
        }
}
