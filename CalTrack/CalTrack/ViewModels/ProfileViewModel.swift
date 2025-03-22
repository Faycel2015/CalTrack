//
//  ProfileViewModel.swift
//  CalTrack
//
//  Created by FayTek on 3/22/25.
//

import Foundation
import SwiftData
import Combine

/// View model for user profile screen
class ProfileViewModel: ObservableObject {
    // MARK: - Services
    
    private let userRepository: UserRepository
    
    // MARK: - Published Properties
    
    // UI State
    @Published var isLoading: Bool = false
    @Published var error: AppError? = nil
    
    // User profile data
    @Published var userProfile: UserProfile?
    
    // Edit state
    @Published var isEditing: Bool = false
    @Published var showOnboarding: Bool = false
    
    // Weight tracking
    @Published var weightHistory: [WeightEntry] = []
    @Published var showAddWeightEntry: Bool = false
    @Published var newWeight: String = ""
    
    // Settings
    @Published var showSettings: Bool = false
    @Published var enabledFeatures: [AppFeature] = AppFeature.allCases
    
    // MARK: - Computed Properties
    
    var hasUserProfile: Bool {
        return userProfile != nil
    }
    
    var formattedHeight: String {
        guard let height = userProfile?.height else { return "Not set" }
        return "\(Int(height)) cm"
    }
    
    var formattedWeight: String {
        guard let weight = userProfile?.weight else { return "Not set" }
        return String(format: "%.1f kg", weight)
    }
    
    var formattedBMI: String {
        guard let profile = userProfile, profile.height > 0, profile.weight > 0 else { return "Not available" }
        
        let heightInMeters = profile.height / 100.0
        let bmi = profile.weight / (heightInMeters * heightInMeters)
        
        return String(format: "%.1f", bmi)
    }
    
    var bmiCategory: String {
        guard let bmi = Double(formattedBMI) else { return "Unknown" }
        
        switch bmi {
        case ..<18.5:
            return "Underweight"
        case 18.5..<25:
            return "Normal weight"
        case 25..<30:
            return "Overweight"
        case 30...:
            return "Obese"
        default:
            return "Unknown"
        }
    }
    
    var weightChange: (value: Double, isGain: Bool) {
        // If we have at least two entries, calculate change
        if weightHistory.count >= 2,
           let latest = weightHistory.first?.weight,
           let previous = weightHistory.dropFirst().first?.weight {
            let change = latest - previous
            return (abs(change), change > 0)
        }
        
        return (0, false)
    }
    
    // MARK: - Initializer
    
    init() {
        // Get repository from service locator
        self.userRepository = AppServices.shared.getUserRepository()
        
        // Load user profile
        loadUserProfile()
        
        // Load weight history
        loadWeightHistory()
    }
    
    // MARK: - Public Methods
    
    /// Load the user profile
    func loadUserProfile() {
        isLoading = true
        
        do {
            userProfile = try userRepository.getCurrentUserProfile()
            isLoading = false
        } catch {
            self.error = AppError.dataError("Failed to load user profile: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    /// Start editing the profile
    func startEditingProfile() {
        showOnboarding = true
    }
    
    /// Update user weight
    func updateWeight() {
        guard let weightValue = Double(newWeight.replacingOccurrences(of: ",", with: ".")),
              weightValue > 0 else {
            error = AppError.userError("Please enter a valid weight")
            return
        }
        
        isLoading = true
        
        // Add to weight history
        let newEntry = WeightEntry(date: Date(), weight: weightValue)
        weightHistory.insert(newEntry, at: 0)
        
        // Update user profile
        do {
            try userRepository.updateWeight(weightValue)
            userProfile?.weight = weightValue
            isLoading = false
            newWeight = ""
            showAddWeightEntry = false
        } catch {
            self.error = AppError.dataError("Failed to update weight: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    /// Toggle a feature flag
    /// - Parameter feature: The feature to toggle
    func toggleFeature(_ feature: AppFeature) {
        if enabledFeatures.contains(feature) {
            enabledFeatures.removeAll { $0 == feature }
        } else {
            enabledFeatures.append(feature)
        }
        
        // In a real app, this would save to user preferences
    }
    
    /// Check if a feature is enabled
    /// - Parameter feature: The feature to check
    /// - Returns: Whether the feature is enabled
    func isFeatureEnabled(_ feature: AppFeature) -> Bool {
        return enabledFeatures.contains(feature)
    }
    
    /// Clear all app data
    func clearAllData() {
        isLoading = true
        
        do {
            try userRepository.deleteUserProfile()
            userProfile = nil
            weightHistory = []
            isLoading = false
        } catch {
            self.error = AppError.dataError("Failed to clear data: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    // MARK: - Private Methods
    
    /// Load weight history
    private func loadWeightHistory() {
        // In a real app, this would load from a repository
        // For now, generate mock data
        
        guard let currentWeight = userProfile?.weight else {
            return
        }
        
        // Start with current weight
        var entries: [WeightEntry] = [
            WeightEntry(date: Date(), weight: currentWeight)
        ]
        
        // Generate some historical entries
        let calendar = Calendar.current
        var mockWeight = currentWeight
        
        // Add an entry for each of the last 10 weeks
        for i in 1...10 {
            if let date = calendar.date(byAdding: .day, value: -7 * i, to: Date()) {
                // Randomize weight changes
                let change = Double.random(in: -0.5...0.5)
                mockWeight += change
                
                entries.append(WeightEntry(date: date, weight: mockWeight))
            }
        }
        
        // Sort by date (newest first)
        weightHistory = entries.sorted { $0.date > $1.date }
    }
}

// MARK: - Supporting Types

/// Weight history entry
struct WeightEntry: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
