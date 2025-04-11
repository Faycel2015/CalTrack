//
//  CalTrackApp.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftData
import SwiftUI

@main
struct CalTrackApp: App {
    let modelContainer: ModelContainer
    @StateObject private var appState = AppState()
    
    // Handle URL schemes for deep linking
    @Environment(\.openURL) var openURL
    
    init() {
        // Register custom fonts if needed
        AppFonts.registerCustomFonts()
        
        // Initialize model container
        do {
            modelContainer = try ModelContainer(
                for: UserProfile.self, Meal.self, FoodItem.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(appState.colorScheme ?? nil)
                .environmentObject(appState)
                .onAppear {
                    AppServices.shared.initialize(with: modelContainer.mainContext)
                    
                    // Set default features if not already set
                    if appState.enabledFeatures.isEmpty {
                        appState.enabledFeatures = [
                            .barcodeScan,
                            .weightTracking,
                            .aiMealSuggestions,
                            .aiNutritionAssistant // Enable the AI Nutrition Assistant by default
                        ]
                    }
                }
                // Handle deep links
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(modelContainer)
    }
    
    // Handle deep linking from URL schemes
    private func handleDeepLink(_ url: URL) {
        // Get the main view model and delegate handling
        Task { @MainActor in
            // Simplified handling directly in the app if needed
            let urlString = url.absoluteString
            
            if urlString.contains("meal") {
                appState.deepLink = .mealDetail(urlString.components(separatedBy: "/").last ?? "")
            } else if urlString.contains("insights") {
                appState.deepLink = .insights
            } else if urlString.contains("profile") {
                appState.deepLink = .profile
            }
        }
    }
}
