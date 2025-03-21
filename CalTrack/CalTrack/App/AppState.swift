//
//  AppState.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

// MARK: - App State

/// Global application state
class AppState: ObservableObject {
    // Authentication state
    @Published var isAuthenticated: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    
    // Navigation state
    @Published var selectedTab: Int = 0
    @Published var showingSettings: Bool = false
    
    // Error handling
    @Published var globalError: AppError? = nil
    
    // Feature flags
    @Published var enabledFeatures: [AppFeature] = []
    
    // MARK: - Methods
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func showError(_ error: AppError) {
        globalError = error
    }
    
    func clearError() {
        globalError = nil
    }
    
    func isFeatureEnabled(_ feature: AppFeature) -> Bool {
        return enabledFeatures.contains(feature)
    }
}
