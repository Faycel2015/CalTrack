//
//  CalTrackApp.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

@main
struct CalTrackApp: App {
    // MARK: - SwiftData Setup
    
    // Define the model container for our app
    let modelContainer: ModelContainer
    
    // MARK: - Initializers
    
    init() {
        // Configure model container for all our model entities
        do {
            modelContainer = try ModelContainer(
                for: [
                    UserProfile.self,
                    Meal.self,
                    FoodItem.self
                ],
                configurations: ModelConfiguration(
                    isStoredInMemoryOnly: false
                )
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear {
                    // Initialize app services with the model context
                    if let modelContext = modelContainer.mainContext as? ModelContext {
                        AppServices.shared.initialize(with: modelContext)
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}
