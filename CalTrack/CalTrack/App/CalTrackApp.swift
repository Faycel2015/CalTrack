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

    init() {
        AppFonts.registerCustomFonts()
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
                .preferredColorScheme(appState.colorScheme) // Dynamically apply theme
                .environmentObject(appState)
                .onAppear {
                    AppServices.shared.initialize(with: modelContainer.mainContext)
                }
        }
        .modelContainer(modelContainer)
    }
}
