//
//  ExercisesViewPlaceholder.swift
//  GymTracker
//
//  Created on 2025-10-22.
//  V2 Clean Architecture - Exercises View Placeholder
//

import SwiftUI

/// Placeholder exercises view for V2 MVP
///
/// **Features:**
/// - Shows exercise count
/// - TODO: Replace with ExerciseListView in Phase 1 Day 4
struct ExercisesViewPlaceholder: View {

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header: Übungen (consistent with Home)
                HStack(alignment: .center) {
                    Text("Übungen")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color(.systemBackground))

                // Content
                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: "figure.run")
                        .font(.system(size: 80))
                        .foregroundColor(.secondary)

                    Text("Exercise Library")
                        .font(.title2.bold())

                    Text("161 exercises available")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Text("Coming in Phase 1 - Day 4")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

#Preview {
    ExercisesViewPlaceholder()
}
