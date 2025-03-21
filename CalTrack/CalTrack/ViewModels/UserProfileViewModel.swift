//
//  UserProfileViewModel.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftData
import Combine

@Observable
class UserProfileViewModel {
    // User profile
    private var modelContext: ModelContext
    private var profile: UserProfile?
    
    // Form input values
    var name: String = ""
    var age: String = ""
    var gender: Gender = .notSpecified
    var heightCm: String = ""
    var weightKg: String = ""
    var activityLevel: ActivityLevel = .moderate
    var weightGoal: WeightGoal = .maintain
    var carbPercentage: Double = 40
    var proteinPercentage: Double = 30
    var fatPercentage: Double = 30
    
    // Validation states
    var nameIsValid: Bool = true
    var ageIsValid: Bool = true
    var heightIsValid: Bool = true
    var weightIsValid: Bool = true
    
    // Computed properties for display
    var bmrDisplay: String {
        guard let profile = profile, profile.bmr > 0 else { return "0" }
        return String(format: "%.0f", profile.bmr)
    }
    
    var tdeeDisplay: String {
        guard let profile = profile, profile.tdee > 0 else { return "0" }
        return String(format: "%.0f", profile.tdee)
    }
    
    var dailyCalorieGoalDisplay: String {
        guard let profile = profile, profile.dailyCalorieGoal > 0 else { return "0" }
        return String(format: "%.0f", profile.dailyCalorieGoal)
    }
    
    var carbGoalDisplay: String {
        guard let profile = profile, profile.carbGoalGrams > 0 else { return "0g" }
        return String(format: "%.0fg", profile.carbGoalGrams)
    }
    
    var proteinGoalDisplay: String {
        guard let profile = profile, profile.proteinGoalGrams > 0 else { return "0g" }
        return String(format: "%.0fg", profile.proteinGoalGrams)
    }
    
    var fatGoalDisplay: String {
        guard let profile = profile, profile.fatGoalGrams > 0 else { return "0g" }
        return String(format: "%.0fg", profile.fatGoalGrams)
    }
    
    var isProfileComplete: Bool {
        return nameIsValid && ageIsValid && heightIsValid && weightIsValid &&
               name.count > 0 && Int(age) ?? 0 > 0 &&
               Double(heightCm) ?? 0 > 0 && Double(weightKg) ?? 0 > 0
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserProfile()
    }
    
    func loadUserProfile() {
        do {
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try modelContext.fetch(descriptor)
            
            if let existingProfile = profiles.first {
                self.profile = existingProfile
                
                // Populate form fields with existing data
                self.name = existingProfile.name
                self.age = "\(existingProfile.age)"
                self.gender = existingProfile.gender
                self.heightCm = "\(existingProfile.height)"
                self.weightKg = "\(existingProfile.weight)"
                self.activityLevel = existingProfile.activityLevel
                self.weightGoal = existingProfile.weightGoal
                self.carbPercentage = existingProfile.carbPercentage * 100
                self.proteinPercentage = existingProfile.proteinPercentage * 100
                self.fatPercentage = existingProfile.fatPercentage * 100
            }
        } catch {
            print("Error loading user profile: \(error)")
        }
    }
    
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
    
    func saveProfile() {
        guard validateInput() else { return }
        
        // Convert string inputs to appropriate types
        let ageInt = Int(age) ?? 0
        let heightDouble = Double(heightCm) ?? 0.0
        let weightDouble = Double(weightKg) ?? 0.0
        
        // Convert percentages to decimal
        let carbPerc = carbPercentage / 100.0
        let proteinPerc = proteinPercentage / 100.0
        let fatPerc = fatPercentage / 100.0
        
        if let existingProfile = profile {
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
            
            // Save to context
            modelContext.insert(newProfile)
            self.profile = newProfile
        }
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Error saving profile: \(error)")
        }
    }
    
    // Method to update macros when sliders change
    func updateMacroPercentages(carbs: Double, protein: Double, fat: Double) {
        // Normalize to ensure they add up to 100%
        let total = carbs + protein + fat
        if total > 0 {
            self.carbPercentage = (carbs / total) * 100
            self.proteinPercentage = (protein / total) * 100
            self.fatPercentage = (fat / total) * 100
        }
    }
    
    // Helper to check if profile exists
    var hasExistingProfile: Bool {
        return profile != nil
    }
}
