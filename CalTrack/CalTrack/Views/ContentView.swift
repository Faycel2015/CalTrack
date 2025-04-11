//
//  ContentView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    @ObservedObject var viewModel: MainViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)

            MealTrackingView(modelContext: modelContext)
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
                .tag(1)

            MacroTrackingView()
                .tabItem {
                    Label("Nutrition", systemImage: "chart.pie.fill")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)

            // Insights tab added conditionally using Group to conform to ViewBuilder
            Group {
                if appState.isFeatureEnabled(.aiNutritionAssistant) {
                    NutritionInsightsView()
                        .tabItem {
                            Label("Insights", systemImage: "brain.fill")
                        }
                        .tag(4)
                }
            }
        }
        .task {
            await checkOnboardingStatus()
        }
        .sheet(isPresented: $appState.showOnboarding) {
            OnboardingView(modelContext: modelContext)
        }
        .onChange(of: appState.deepLink) { oldValue, newValue in
            if let deepLink = newValue {
                appState.handleDeepLink(deepLink)
            }
        }
    }

    @MainActor
    private func checkOnboardingStatus() async {
        // Check if user profiles are empty, and show onboarding if necessary
        if userProfiles.isEmpty {
            appState.showOnboarding = true
            appState.hasCompletedOnboarding = false
        } else {
            appState.showOnboarding = false
            appState.hasCompletedOnboarding = true
        }
    }
}
