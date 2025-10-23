//
//  SuccessPill.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - UI Component
//

import SwiftUI

/// Success pill notification that appears below Dynamic Island
///
/// **Design:**
/// - Green pill with white text
/// - Appears below Dynamic Island (~60pt from top)
/// - Auto-dismisses after 2 seconds
/// - Smooth slide-in/out animation
///
/// **Usage:**
/// ```swift
/// @State private var showSuccess = false
/// @State private var successMessage = ""
///
/// ZStack {
///     // Your main content
///
///     if showSuccess {
///         SuccessPill(message: successMessage)
///             .transition(.move(edge: .top).combined(with: .opacity))
///     }
/// }
/// ```
struct SuccessPill: View {

    let message: String

    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)

                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.green)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            )
            .padding(.top, 8)  // Directly below Dynamic Island

            Spacer()
        }
    }
}

// MARK: - View Modifier

/// View modifier to show success pill notifications
///
/// **Usage:**
/// ```swift
/// .successPill(isPresented: $showSuccess, message: "Übung hinzugefügt")
/// ```
struct SuccessPillModifier: ViewModifier {

    @Binding var isPresented: Bool
    let message: String
    let duration: TimeInterval

    @State private var task: Task<Void, Never>?

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                SuccessPill(message: message)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)  // Above everything
                    .onAppear {
                        // Auto-dismiss after duration
                        task?.cancel()
                        task = Task {
                            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                            if !Task.isCancelled {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isPresented = false
                                }
                            }
                        }
                    }
                    .onDisappear {
                        task?.cancel()
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
    }
}

extension View {
    /// Show a success pill notification
    /// - Parameters:
    ///   - isPresented: Binding to control visibility
    ///   - message: Success message to display
    ///   - duration: How long to show (default: 2 seconds)
    func successPill(
        isPresented: Binding<Bool>,
        message: String,
        duration: TimeInterval = 2.0
    ) -> some View {
        modifier(
            SuccessPillModifier(
                isPresented: isPresented,
                message: message,
                duration: duration
            ))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Tap to show success")
            .font(.headline)

        Button("Show Success Pill") {
            // Demo
        }
        .buttonStyle(.borderedProminent)
    }
    .successPill(isPresented: .constant(true), message: "Übung hinzugefügt")
}
