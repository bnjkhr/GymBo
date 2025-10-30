//
//  WarmupCalculator.swift
//  GymBo
//
//  Created on 2025-10-30.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Utility for calculating warmup set weights and reps
///
/// **Purpose:**
/// - Auto-calculate warmup weights as percentage of working weight
/// - Provide sensible rep ranges for warmup sets
/// - Support multiple warmup progression strategies
///
/// **Usage:**
/// ```swift
/// let warmups = WarmupCalculator.calculateWarmupSets(
///     workingWeight: 100.0,
///     workingReps: 8,
///     strategy: .standard
/// )
/// // Returns 3 warmup sets: 40kg x 5, 60kg x 5, 80kg x 3
/// ```
struct WarmupCalculator {

    /// Warmup progression strategy
    enum Strategy: Equatable, Hashable, RawRepresentable {
        /// Standard 3-set progression: 40%, 60%, 80%
        case standard

        /// Conservative 4-set progression: 30%, 50%, 70%, 85%
        case conservative

        /// Minimal 2-set progression: 50%, 75%
        case minimal

        /// Custom percentages
        case custom([Double])

        /// No warmup sets
        case none

        // MARK: - RawRepresentable

        public var rawValue: String {
            switch self {
            case .standard: return "standard"
            case .conservative: return "conservative"
            case .minimal: return "minimal"
            case .custom(let percentages):
                return "custom:\(percentages.map { String($0) }.joined(separator: ","))"
            case .none: return "none"
            }
        }

        public init?(rawValue: String) {
            switch rawValue {
            case "standard":
                self = .standard
            case "conservative":
                self = .conservative
            case "minimal":
                self = .minimal
            case "none":
                self = .none
            default:
                // Parse custom format: "custom:40.0,60.0,80.0"
                if rawValue.hasPrefix("custom:") {
                    let percentagesString = String(rawValue.dropFirst("custom:".count))
                    let percentages = percentagesString.split(separator: ",").compactMap {
                        Double($0)
                    }
                    if !percentages.isEmpty {
                        self = .custom(percentages)
                        return
                    }
                }
                return nil
            }
        }
    }

    /// Calculated warmup set
    struct WarmupSet {
        let weight: Double
        let reps: Int
        let percentageOfMax: Double
    }

    // MARK: - Public Methods

    /// Calculate warmup sets based on working weight and strategy
    /// - Parameters:
    ///   - workingWeight: Target working weight in kg
    ///   - workingReps: Target working reps (used to estimate appropriate warmup reps)
    ///   - strategy: Warmup progression strategy
    /// - Returns: Array of warmup sets
    static func calculateWarmupSets(
        workingWeight: Double,
        workingReps: Int,
        strategy: Strategy = .standard
    ) -> [WarmupSet] {
        let percentages = getPercentages(for: strategy)

        return percentages.map { percentage in
            let weight = round(workingWeight * percentage / 2.5) * 2.5  // Round to nearest 2.5kg
            let reps = calculateWarmupReps(
                percentage: percentage,
                workingReps: workingReps
            )

            return WarmupSet(
                weight: max(weight, 5.0),  // Minimum 5kg (empty bar might be 20kg)
                reps: reps,
                percentageOfMax: percentage
            )
        }
    }

    /// Calculate recommended number of warmup sets based on working weight
    /// - Parameter workingWeight: Target working weight in kg
    /// - Returns: Recommended number of warmup sets
    static func recommendedWarmupSetCount(for workingWeight: Double) -> Int {
        switch workingWeight {
        case 0..<40:
            return 1  // Very light weight - minimal warmup
        case 40..<80:
            return 2  // Light to moderate - 2 warmup sets
        case 80..<120:
            return 3  // Moderate to heavy - standard warmup
        default:
            return 4  // Heavy weight - conservative warmup
        }
    }

    /// Get recommended strategy based on working weight
    /// - Parameter workingWeight: Target working weight in kg
    /// - Returns: Recommended warmup strategy
    static func recommendedStrategy(for workingWeight: Double) -> Strategy {
        switch workingWeight {
        case 0..<40:
            return .minimal
        case 40..<120:
            return .standard
        default:
            return .conservative
        }
    }

    // MARK: - Private Methods

    /// Get percentage progression for strategy
    private static func getPercentages(for strategy: Strategy) -> [Double] {
        switch strategy {
        case .standard:
            return [0.40, 0.60, 0.80]  // 40%, 60%, 80%
        case .conservative:
            return [0.30, 0.50, 0.70, 0.85]  // 30%, 50%, 70%, 85%
        case .minimal:
            return [0.50, 0.75]  // 50%, 75%
        case .custom(let percentages):
            return percentages
        case .none:
            return []  // No warmup sets
        }
    }

    /// Calculate appropriate reps for warmup set based on percentage and working reps
    private static func calculateWarmupReps(percentage: Double, workingReps: Int) -> Int {
        switch percentage {
        case 0..<0.5:
            return 5  // Light warmup: 5 reps
        case 0.5..<0.7:
            return 5  // Moderate warmup: 5 reps
        case 0.7..<0.85:
            return 3  // Heavy warmup: 3 reps
        default:
            return 1  // Very heavy warmup: 1 rep (priming)
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
    extension WarmupCalculator {
        /// Sample warmup sets for previews
        static var previewSets: [WarmupSet] {
            calculateWarmupSets(
                workingWeight: 100.0,
                workingReps: 8,
                strategy: .standard
            )
        }

        /// Sample conservative warmup sets
        static var previewConservative: [WarmupSet] {
            calculateWarmupSets(
                workingWeight: 140.0,
                workingReps: 5,
                strategy: .conservative
            )
        }
    }
#endif
