//
//  MainTabView.swift
//  GymTracker
//
//  Created on 2025-10-22.
//  V2 Clean Architecture - Main Tab Navigation
//  Updated on 2025-10-29 - Added Session History & Statistics
//

import SwiftUI

/// Main tab bar navigation for GymTracker V2.0
///
/// **Tabs:**
/// 1. Home - Workout list, quick start, calendar
/// 2. Exercises - Browse exercise library
/// 3. Verlauf - Session history and statistics
struct MainTabView: View {

    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dependencyContainer) private var dependencyContainer
    @State private var selectedTab = 0
    @State private var sessionHistoryStore: SessionHistoryStore?

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Start", systemImage: "house.fill")
                }
                .tag(0)

            ExercisesView()
                .tabItem {
                    Label("Übungen", systemImage: "figure.run")
                }
                .tag(1)

            Group {
                if let historyStore = sessionHistoryStore {
                    SessionHistoryView()
                        .environment(historyStore)
                } else {
                    ProgressView()
                }
            }
            .tabItem {
                Label("Verlauf", systemImage: "clock.arrow.circlepath")
            }
            .tag(2)
        }
        .tint(.appOrange)
        .tabBarMinimizeBehavior(.onScrollDown)
        .task {
            // Initialize SessionHistoryStore on first load
            if sessionHistoryStore == nil, let container = dependencyContainer {
                sessionHistoryStore = container.makeSessionHistoryStore()
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
    #Preview {
        MainTabView()
            .environment(SessionStore.preview)
    }
#endif
