//
//  AnimationHelper.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V2 Clean Architecture - Presentation Layer
//

import SwiftUI

/// Helper for consistent animations across SessionHistory components
struct AnimationHelper {

    // MARK: - Card Animations

    /// Slide up with fade animation for cards
    static func cardEntryAnimation(delay: Double = 0) -> Animation {
        .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
            .delay(delay)
    }

    /// Scale effect for tappable items
    static let scaleAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.6)

    // MARK: - Chart Animations

    /// Draw animation for charts (left to right)
    static let chartDrawAnimation: Animation = .easeInOut(duration: 1.0)

    /// Delayed chart draw (for staggered effect)
    static func chartDrawAnimation(delay: Double) -> Animation {
        .easeInOut(duration: 1.0).delay(delay)
    }

    // MARK: - Tab Animations

    /// Smooth tab transition
    static let tabTransition: Animation = .spring(response: 0.4, dampingFraction: 0.75)

    // MARK: - Haptic Feedback

    /// Light impact for selections
    static func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact for confirmations
    static func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Success feedback
    static func successFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Selection feedback
    static func selectionFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - View Modifiers

/// Card entry animation modifier
struct CardEntryModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(AnimationHelper.cardEntryAnimation(delay: delay)) {
                    isVisible = true
                }
            }
    }
}

/// Scale effect on tap modifier
struct ScaleEffectModifier: ViewModifier {
    @State private var isPressed = false
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .onTapGesture {
                // Press animation
                withAnimation(AnimationHelper.scaleAnimation) {
                    isPressed = true
                }

                // Haptic feedback
                AnimationHelper.lightImpact()

                // Execute action and release
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(AnimationHelper.scaleAnimation) {
                        isPressed = false
                    }
                    action()
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply card entry animation
    func cardEntryAnimation(delay: Double = 0) -> some View {
        modifier(CardEntryModifier(delay: delay))
    }

    /// Apply scale effect with haptic feedback
    func scaleEffectTap(action: @escaping () -> Void) -> some View {
        modifier(ScaleEffectModifier(action: action))
    }
}
