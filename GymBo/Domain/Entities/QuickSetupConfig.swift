//
//  QuickSetupConfig.swift
//  GymBo
//
//  Created on 2025-10-26.
//  Domain Layer - Quick-Setup Configuration
//

import Foundation

/// Configuration for Quick-Setup workout generation
struct QuickSetupConfig {
    let availableEquipment: Set<EquipmentCategory>
    let duration: WorkoutDuration
    let goal: WorkoutGoal
}

/// Equipment categories for Quick-Setup
enum EquipmentCategory: String, CaseIterable, Identifiable {
    case machines = "Maschine"
    case freeWeights = "Freie Gewichte"
    case bodyweight = "Körpergewicht"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .machines: return "figure.strengthtraining.traditional"
        case .freeWeights: return "dumbbell.fill"
        case .bodyweight: return "figure.arms.open"
        }
    }

    var displayName: String {
        rawValue
    }
}

/// Workout duration options
enum WorkoutDuration: Int, CaseIterable, Identifiable {
    case short = 20
    case medium = 30
    case long = 45
    case extended = 60

    var id: Int { rawValue }

    var displayName: String {
        "\(rawValue) Min"
    }

    /// Recommended number of exercises based on duration
    var recommendedExerciseCount: Int {
        switch self {
        case .short: return 4
        case .medium: return 6
        case .long: return 8
        case .extended: return 10
        }
    }
}

/// Workout goal/focus
enum WorkoutGoal: String, CaseIterable, Identifiable {
    case fullBody = "Ganzkörper"
    case upperBody = "Oberkörper"
    case lowerBody = "Unterkörper"
    case push = "Push"
    case pull = "Pull"
    case cardio = "Cardio"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fullBody: return "figure.mixed.cardio"
        case .upperBody: return "figure.arms.open"
        case .lowerBody: return "figure.walk"
        case .push: return "arrow.up.circle.fill"
        case .pull: return "arrow.down.circle.fill"
        case .cardio: return "heart.circle.fill"
        }
    }

    var displayName: String {
        rawValue
    }

    /// Primary muscle groups for this goal
    var targetMuscleGroups: [String] {
        switch self {
        case .fullBody:
            return ["Beine", "Brust", "Rücken", "Schultern", "Core"]
        case .upperBody:
            return ["Brust", "Rücken", "Schultern", "Bizeps", "Trizeps"]
        case .lowerBody:
            return ["Beine", "Gesäß", "Beinbeuger", "Waden"]
        case .push:
            return ["Brust", "Schultern", "Trizeps"]
        case .pull:
            return ["Rücken", "Bizeps", "Unterarme"]
        case .cardio:
            return ["Cardio"]
        }
    }

    /// Default set/rep scheme for this goal
    var defaultSetRepScheme: (sets: Int, reps: Int, rest: TimeInterval) {
        switch self {
        case .fullBody:
            return (3, 12, 90)
        case .upperBody, .lowerBody:
            return (3, 10, 90)
        case .push, .pull:
            return (4, 8, 120)
        case .cardio:
            return (3, 0, 60)  // Time-based
        }
    }
}
