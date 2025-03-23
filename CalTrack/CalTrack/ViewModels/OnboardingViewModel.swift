//
//  OnboardingViewModel.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

/// View model for the onboarding flow
class OnboardingViewModel: ObservableObject {
    
    // MARK: - Services
    public typealias Gender = UserProfile.Gender
    private let userRepository: UserRepository
    private let modelContext: ModelContext
    
    // MARK: - Published Properties
    
    // UI State
    @Published var isLoading: Bool = false
    @Published var error: AppError? = nil
    @Published var currentStep: Int = 0
    @Published var showResults: Bool = false
    
    // Form input values - Personal Info
    @Published var name: String = ""
    @Published var age: String = ""
    @Published var gender: Gender = .notSpecified
    
    // Form input values - Body Measurements
    @Published var heightCm: String = ""
    @Published var weightKg: String = ""
    
    // Form input values - Activity & Goals
    @Published var activityLevel: ActivityLevel = .moderate
    @Published var weightGoal: WeightGoal = .maintain
    
    // Form input values - Macro Settings
    @Published var carbPercentage: Double = 40
    @Published var proteinPercentage: Double = 30
    @Published var fatPercentage: Double = 30
    
    // Form validation
    @Published var nameIsValid: Bool = true
    @Published var ageIsValid: Bool = true
    @Published var heightIsValid: Bool = true
    @Published var weightIsValid: Bool = true
    
    // User profile
    @Published var userProfile: UserProfile? = nil
    
    // Completion handler
    var onComplete: (() -> Void)?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var hasExistingProfile: Bool {
        return userProfile != nil
    }
    
    var isProfileComplete: Bool {
        return nameIsValid && ageIsValid && heightIsValid && weightIsValid &&
               name.count > 0 && Int(age) ?? 0 > 0 &&
               Double(heightCm) ?? 0 > 0 && Double(weightKg) ?? 0 > 0
    }
    
    var isStep1Valid: Bool {
        return !name.isEmpty &&
               (Int(age) ?? 0) >= 15 &&
               (Int(age) ?? 0) <= 100
    }
    
    var isStep2Valid: Bool {
        return (Double(heightCm) ?? 0) > 0 &&
               (Double(weightKg) ?? 0) > 0
    }
    
    var bmrDisplay: String {
        guard let profile = userProfile, profile.bmr > 0 else { return "0" }
        return String(format: "%.0f", profile.bmr)
    }
    
    var tdeeDisplay: String {
        guard let profile = userProfile, profile.tdee > 0 else { return "0" }
        return String(format: "%.0f", profile.tdee)
    }
    
    var dailyCalorieGoalDisplay: String {
        guard let profile = userProfile, profile.dailyCalorieGoal > 0 else { return "0" }
        return String(format: "%.0f", profile.dailyCalorieGoal)
    }
    
    var carbGoalDisplay: String {
        guard let profile = userProfile, profile.carbGoalGrams > 0 else { return "0g" }
        return String(format: "%.0fg", profile.carbGoalGrams)
    }
    
    var proteinGoalDisplay: String {
        guard let profile = userProfile, profile.proteinGoalGrams > 0 else { return "0g" }
        return String(format: "%.0fg", profile.proteinGoalGrams)
    }
    
    var fatGoalDisplay: String {
        guard let profile = userProfile, profile.fatGoalGrams > 0 else { return "0g" }
        return String(format: "%.0fg", profile.fatGoalGrams)
    }
    
    // MARK: - Initializer
    
    init(modelContext: ModelContext, onComplete: (() -> Void)? = nil) {
        self.modelContext = modelContext
        self.userRepository = UserRepository(modelContext: modelContext)
        self.onComplete = onComplete
        
        loadUserProfile()
    }
    
    // MARK: - Public Methods
    
    /// Load the user profile
    func loadUserProfile() {
        isLoading = true
        
        do {
            if let existingProfile = try userRepository.getCurrentUserProfile() {
                userProfile = existingProfile
                
                // Populate form fields with existing data
                name = existingProfile.name
                age = "\(existingProfile.age)"
                gender = existingProfile.gender
                heightCm = "\(existingProfile.height)"
                weightKg = "\(existingProfile.weight)"
                activityLevel = existingProfile.activityLevel
                weightGoal = existingProfile.weightGoal
                carbPercentage = existingProfile.carbPercentage * 100
                proteinPercentage = existingProfile.proteinPercentage * 100
                fatPercentage = existingProfile.fatPercentage * 100
            }
        } catch {
            self.error = AppError.dataError("Failed to load user profile: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Move to the next step in the onboarding flow
    func nextStep() {
        if currentStep < 3 {
            currentStep += 1
        } else {
            saveProfile()
            showResults = true
        }
    }
    
    /// Move to the previous step in the onboarding flow
    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }
    
    /// Validate form inputs
    /// - Returns: Whether all inputs are valid
    func validateInput() -> Bool {
        // Validate name
        nameIsValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        // Validate age
        if let ageInt = Int(age), ageInt >= 15 && ageInt <= 100 {
            ageIsValid = true
        } else {
            ageIsValid = false
        }
        
        // Validate height
        if let heightDouble = Double(heightCm), heightDouble > 0 {
            heightIsValid = true
        } else {
            heightIsValid = false
        }
        
        // Validate weight
        if let weightDouble = Double(weightKg), weightDouble > 0 {
            weightIsValid = true
        } else {
            weightIsValid = false
        }
        
        return nameIsValid && ageIsValid && heightIsValid && weightIsValid
    }
    
    /// Save the user profile
    func saveProfile() {
        guard validateInput() else { return }
        
        isLoading = true
        
        // Convert string inputs to appropriate types
        let ageInt = Int(age) ?? 0
        let heightDouble = Double(heightCm) ?? 0.0
        let weightDouble = Double(weightKg) ?? 0.0
        
        // Convert percentages to decimal
        let carbPerc = carbPercentage / 100.0
        let proteinPerc = proteinPercentage / 100.0
        let fatPerc = fatPercentage / 100.0
        
        do {
            if let existingProfile = userProfile {
                // Update existing profile
                existingProfile.name = name
                existingProfile.age = ageInt
                existingProfile.gender = gender
                existingProfile.height = heightDouble
                existingProfile.weight = weightDouble
                existingProfile.activityLevel = activityLevel
                existingProfile.weightGoal = weightGoal
                existingProfile.carbPercentage = carbPerc
                existingProfile.proteinPercentage = proteinPerc
                existingProfile.fatPercentage = fatPerc
                
                existingProfile.calculateNutritionGoals()
                
                try userRepository.saveUserProfile(existingProfile)
                userProfile = existingProfile
            } else {
                // Create new profile
                let newProfile = UserProfile(
                    name: name,
                    age: ageInt,
                    gender: gender,
                    height: heightDouble,
                    weight: weightDouble,
                    activityLevel: activityLevel,
                    weightGoal: weightGoal,
                    carbPercentage: carbPerc,
                    proteinPercentage: proteinPerc,
                    fatPercentage: fatPerc
                )
                
                try userRepository.saveUserProfile(newProfile)
                userProfile = newProfile
            }
            
            // Notify completion if needed
            if showResults {
                onComplete?()
            }
        } catch {
            self.error = AppError.dataError("Failed to save profile: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Complete the onboarding process
    func completeOnboarding() {
        onComplete?()
    }
    
    /// Update macro percentages when sliders change
    /// - Parameters:
    ///   - carbs: Carbs percentage
    ///   - protein: Protein percentage
    ///   - fat: Fat percentage
    func updateMacroPercentages(carbs: Double, protein: Double, fat: Double) {
        // Normalize to ensure they add up to 100%
        let total = carbs + protein + fat
        if total > 0 {
            self.carbPercentage = (carbs / total) * 100
            self.proteinPercentage = (protein / total) * 100
            self.fatPercentage = (fat / total) * 100
        }
    }
    
    /// Get recommended macro distribution based on weight goal
    func getRecommendedMacroDistribution() -> (carbs: Double, protein: Double, fat: Double) {
        return weightGoal.recommendedMacroDistribution
    }
    
    /// Apply recommended macro distribution
    func applyRecommendedMacroDistribution() {
        let recommended = getRecommendedMacroDistribution()
        carbPercentage = recommended.carbs * 100
        proteinPercentage = recommended.protein * 100
        fatPercentage = recommended.fat * 100
    }
}
