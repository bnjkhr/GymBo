//
//  HapticFeedback.swift
//  GymBo
//
//  Created on 2025-10-26.
//  Utility for haptic feedback without simulator warnings
//

import UIKit

/// Utility for haptic feedback that only works on physical devices
///
/// **Usage:**
/// ```swift
/// HapticFeedback.impact(.light)
/// HapticFeedback.selection()
/// ```
///
/// **Note:**
/// Haptic feedback is disabled in the simulator to avoid console warnings
/// about missing haptic pattern library files.
enum HapticFeedback {

    /// Trigger impact haptic feedback
    /// - Parameter style: The impact style (light, medium, heavy, soft, rigid)
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        #if targetEnvironment(simulator)
            // Do nothing in simulator to avoid haptic warnings
        #else
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        #endif
    }

    /// Trigger selection haptic feedback
    static func selection() {
        #if targetEnvironment(simulator)
            // Do nothing in simulator to avoid haptic warnings
        #else
            UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    /// Trigger notification haptic feedback
    /// - Parameter type: The notification type (success, warning, error)
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        #if targetEnvironment(simulator)
            // Do nothing in simulator to avoid haptic warnings
        #else
            UINotificationFeedbackGenerator().notificationOccurred(type)
        #endif
    }
}
