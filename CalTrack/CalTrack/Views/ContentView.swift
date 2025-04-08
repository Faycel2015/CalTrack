//
//  ContentView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    
    // Using StateObject to ensure the view model persists
    @ObservedObject var viewModel: MainViewModel
    @EnvironmentObject var appState: AppState
    
    // Local state
    @State private var showOnboarding = false
    
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
            
            // New Insights tab - only show if feature is enabled
            if appState.isFeatureEnabled(.aiNutritionAssistant) {
                NutritionInsightsView()
                    .tabItem {
                        Label("Insights", systemImage: "brain.fill")
                    }
                    .tag(4)
            }
        }
        .task {
            // Use task instead of onAppear for async operations
            await checkOnboardingStatus()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(modelContext: modelContext)
        }
        // Enable deep linking via appState
        .onChange(of: appState.deepLink) { oldValue, newValue in
            if let deepLink = newValue {
                appState.handleDeepLink(deepLink)
            }
        }
    }
    
    // Move async logic to separate function
    @MainActor
    private func checkOnboardingStatus() async {
        // Show onboarding if no user profile exists
        if userProfiles.isEmpty {
            showOnboarding = true
            
            // Update the app state to reflect no user
            appState.hasCompletedOnboarding = false
            appState.showOnboarding = true
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserProfile.self, configurations: config)
    
    // Create a dummy AppState for the preview
    let appState = AppState()
    appState.enabledFeatures = [.aiNutritionAssistant, .barcodeScan, .waterTracking]
    
    // Create a dummy MainViewModel for the preview
    let viewModel = MainViewModel(
        modelContext: container.mainContext,
        appState: appState
    )
    
    return ContentView(viewModel: viewModel)
        .modelContainer(container)
        .environmentObject(appState)
}
