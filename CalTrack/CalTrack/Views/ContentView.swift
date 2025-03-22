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
    
    @State private var mainViewModel: MainViewModel?
    
    @EnvironmentObject var appState: AppState
    
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
        }
        .onAppear {
            // Show onboarding if no user profile exists
            if userProfiles.isEmpty {
                showOnboarding = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
}
