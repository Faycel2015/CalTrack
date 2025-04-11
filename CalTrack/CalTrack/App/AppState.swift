//
//  AppState.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftUI

/// Global application state
@MainActor // Add MainActor attribute for Swift 6 compliance
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
    
    // Deep linking
    @Published var deepLink: DeepLink? = nil
    
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
        // Ensure the tab index is valid (now including the insights tab)
        if tabIndex >= 0 && tabIndex <= 4 {
            selectedTab = tabIndex
        }
    }
    
    /// Handle deep link navigation
    /// - Parameter deepLink: The deep link to handle
    func handleDeepLink(_ deepLink: DeepLink) {
        switch deepLink {
        case .mealDetail(_):
            selectedTab = 1
            // Additional logic to navigate to specific meal can be added
            
        case .macroDetail(_):
            selectedTab = 2
            // Additional logic for macro details can be added
            
        case .insights:
            selectedTab = 4
            
        case .profile:
            selectedTab = 3
        }
        
        // Clear the deep link after handling
        self.deepLink = nil
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
        
        // Load color scheme with system default as fallback
        if let schemeString = userDefaults.string(forKey: "colorScheme") {
            colorScheme = schemeString == "dark" ? .dark : .light
        }
    }
    
    // Optional: Persist color scheme preference
    private func saveColorSchemePreference() {
        UserDefaults.standard.set(
            colorScheme == .dark ? "dark" : (colorScheme == .light ? "light" : "system"),
            forKey: "AppColorScheme"
        )
    }
}

// MARK: - Feature Flags

/// Application error handling
public enum AppError: Error, Identifiable {
    case dataError(String)
    case networkError(String)
    case userError(String)
    case serverError(String)
    case serviceUnavailable(String)
    case unknown(String)
    case initializationError(String)
    
    public var id: String {
        switch self {
        case .dataError(let message): return "data_\(message.hashValue)"
        case .networkError(let message): return "network_\(message.hashValue)"
        case .userError(let message): return "user_\(message.hashValue)"
        case .serverError(let message): return "server_\(message.hashValue)"
        case .serviceUnavailable(let message): return "service_\(message.hashValue)"
        case .unknown(let message): return "unknown_\(message.hashValue)"
        case .initializationError(let message): return "init_\(message.hashValue)"
        }
    }
    
    public var message: String {
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
        case .initializationError(let message):
            return "Initialization Error: \(message)"
        }
    }
}

/// Application feature flags
enum AppFeature: String, CaseIterable, Identifiable {
    case aiMealSuggestions = "AI Meal Suggestions"
    case barcodeScan = "Barcode Scanning"
    case waterTracking = "Water Tracking"
    case exerciseTracking = "Exercise Tracking"
    case weightTracking = "Weight Tracking"
    case exportData = "Export Data"
    case darkMode = "Dark Mode"
    case aiNutritionAssistant = "AI Nutrition Assistant"
    
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
        case .aiNutritionAssistant:
            return "Get AI-powered insights and recommendations for your nutrition"
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
        case .aiNutritionAssistant: return "brain.fill"
        }
    }
}

// MARK: - Deep Link

/// Deep link enum for app navigation
enum DeepLink: Equatable {
    case mealDetail(String)
    case macroDetail(MacroType)
    case insights
    case profile
}
