//
//  AppState.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftUI

/// Global application state
class AppState: ObservableObject {
    // MARK: - Published Properties
    
    // Authentication state
    @Published var isAuthenticated: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    @Published var showOnboarding: Bool = false
    
    // Navigation state
    @Published var selectedTab: Int = 0
    @Published var showingSettings: Bool = false
    
    // Error handling
    @Published var globalError: AppError? = nil
    
    // Feature flags
    @Published var enabledFeatures: [AppFeature] = []
    
    // Theme
    @Published var colorScheme: ColorScheme? = nil
    
    // MARK: - Initializer
    
    init() {
        // Load saved app state
        loadAppState()
        
        // Set default features
        if enabledFeatures.isEmpty {
            enabledFeatures = defaultEnabledFeatures
        }
    }
    
    // MARK: - Default Values
    
    /// Default enabled features
    private var defaultEnabledFeatures: [AppFeature] {
        return [.barcodeScan, .weightTracking, .aiMealSuggestions]
    }
    
    // MARK: - Methods
    
    /// Complete the onboarding process
    func completeOnboarding() {
        hasCompletedOnboarding = true
        showOnboarding = false
        saveAppState()
    }
    
    /// Show error to the user
    /// - Parameter error: The error to display
    func showError(_ error: AppError) {
        globalError = error
    }
    
    /// Clear the current error
    func clearError() {
        globalError = nil
    }
    
    /// Check if a feature is enabled
    /// - Parameter feature: The feature to check
    /// - Returns: Boolean indicating if the feature is enabled
    func isFeatureEnabled(_ feature: AppFeature) -> Bool {
        return enabledFeatures.contains(feature)
    }
    
    /// Toggle a specific feature
    /// - Parameter feature: The feature to toggle
    func toggleFeature(_ feature: AppFeature) {
        if enabledFeatures.contains(feature) {
            enabledFeatures.removeAll { $0 == feature }
        } else {
            enabledFeatures.append(feature)
        }
        
        saveAppState()
    }
    
    /// Set app color scheme
    /// - Parameter scheme: The color scheme to use
    func setColorScheme(_ scheme: ColorScheme?) {
        colorScheme = scheme
        saveAppState()
    }
    
    /// Navigate to a specific tab
    /// - Parameter tabIndex: The tab index to select
    func navigateToTab(_ tabIndex: Int) {
        // Ensure the tab index is valid
        if tabIndex >= 0 && tabIndex <= 3 {
            selectedTab = tabIndex
        }
    }
    
    // MARK: - Persistence
    
    /// Save app state to user defaults
    private func saveAppState() {
        let userDefaults = UserDefaults.standard
        
        // Save onboarding state
        userDefaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        
        // Save enabled features
        let featureStrings = enabledFeatures.map { $0.rawValue }
        userDefaults.set(featureStrings, forKey: "enabledFeatures")
        
        // Save color scheme
        if let scheme = colorScheme {
            userDefaults.set(scheme == .dark ? "dark" : "light", forKey: "colorScheme")
        } else {
            userDefaults.removeObject(forKey: "colorScheme")
        }
    }
    
    /// Load app state from user defaults
    private func loadAppState() {
        let userDefaults = UserDefaults.standard
        
        // Load onboarding state
        hasCompletedOnboarding = userDefaults.bool(forKey: "hasCompletedOnboarding")
        
        // Load enabled features
        if let featureStrings = userDefaults.stringArray(forKey: "enabledFeatures") {
            enabledFeatures = featureStrings.compactMap { rawValue in
                AppFeature.allCases.first { $0.rawValue == rawValue }
            }
        }
        
        // Load color scheme
        if let schemeString = userDefaults.string(forKey: "colorScheme") {
            colorScheme = schemeString == "dark" ? .dark : .light
        }
    }
}

// MARK: - Error Handling

/// Application error types
enum AppError: Error, Identifiable {
    case dataError(String)
    case networkError(String)
    case userError(String)
    case serverError(String)
    case serviceUnavailable(String)
    case unknown(String)
    
    var id: String {
        switch self {
        case .dataError(let message): return "data_\(message.hashValue)"
        case .networkError(let message): return "network_\(message.hashValue)"
        case .userError(let message): return "user_\(message.hashValue)"
        case .serverError(let message): return "server_\(message.hashValue)"
        case .serviceUnavailable(let message): return "service_\(message.hashValue)"
        case .unknown(let message): return "unknown_\(message.hashValue)"
        }
    }
    
    var message: String {
        switch self {
        case .dataError(let message):
            return "Data Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .userError(let message):
            return "User Error: \(message)"
        case .serverError(let message):
            return "Server Error: \(message)"
        case .serviceUnavailable(let message):
            return "Service Unavailable: \(message)"
        case .unknown(let message):
            return "Unknown Error: \(message)"
        }
    }
}

// MARK: - Feature Flags

/// Application feature flags
enum AppFeature: String, CaseIterable, Identifiable {
    case aiMealSuggestions = "AI Meal Suggestions"
    case barcodeScan = "Barcode Scanning"
    case waterTracking = "Water Tracking"
    case exerciseTracking = "Exercise Tracking"
    case weightTracking = "Weight Tracking"
    case exportData = "Export Data"
    case darkMode = "Dark Mode"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .aiMealSuggestions:
            return "Get personalized meal suggestions using AI"
        case .barcodeScan:
            return "Scan food barcodes to easily log meals"
        case .waterTracking:
            return "Track daily water intake"
        case .exerciseTracking:
            return "Log and track exercise activities"
        case .weightTracking:
            return "Track weight changes over time"
        case .exportData:
            return "Export nutrition data in CSV format"
        case .darkMode:
            return "Use dark mode appearance"
        }
    }
    
    var icon: String {
        switch self {
        case .aiMealSuggestions: return "sparkles"
        case .barcodeScan: return "barcode.viewfinder"
        case .waterTracking: return "drop.fill"
        case .exerciseTracking: return "figure.walk"
        case .weightTracking: return "scalemass.fill"
        case .exportData: return "square.and.arrow.up"
        case .darkMode: return "moon.fill"
        }
    }
}
