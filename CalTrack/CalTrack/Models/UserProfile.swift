//
//  UserProfile.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftData

@Model
class UserProfile {
    // Personal Information
    var name: String
    var age: Int
    var gender: Gender
    var height: Double // in cm
    var weight: Double // in kg
    var activityLevel: ActivityLevel
    var weightGoal: WeightGoal
    
    // Calculated values
    var bmr: Double
    var tdee: Double
    var dailyCalorieGoal: Double
    
    // Macro distribution (default 40/30/30)
    var carbPercentage: Double
    var proteinPercentage: Double
    var fatPercentage: Double
    
    // Macro goals in grams
    var carbGoalGrams: Double
    var proteinGoalGrams: Double
    var fatGoalGrams: Double
    
    // Creation date
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String = "",
        age: Int = 0,
        gender: Gender = .notSpecified,
        height: Double = 0.0,
        weight: Double = 0.0,
        activityLevel: ActivityLevel = .moderate,
        weightGoal: WeightGoal = .maintain,
        carbPercentage: Double = 0.4,
        proteinPercentage: Double = 0.3,
        fatPercentage: Double = 0.3
    ) {
        self.name = name
        self.age = age
        self.gender = gender
        self.height = height
        self.weight = weight
        self.activityLevel = activityLevel
        self.weightGoal = weightGoal
        self.carbPercentage = carbPercentage
        self.proteinPercentage = proteinPercentage
        self.fatPercentage = fatPercentage
        
        // Initialize calculated values
        self.bmr = 0.0
        self.tdee = 0.0
        self.dailyCalorieGoal = 0.0
        self.carbGoalGrams = 0.0
        self.proteinGoalGrams = 0.0
        self.fatGoalGrams = 0.0
        
        self.createdAt = Date()
        self.updatedAt = Date()
        
        // Calculate initial values
        calculateNutritionGoals()
    }
    
    func calculateNutritionGoals() {
        // Calculate BMR using Mifflin-St Jeor Equation
        if gender == .male {
            bmr = (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
        } else if gender == .female {
            bmr = (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
        } else {
            // For non-binary or not specified, use average of male and female equations
            let maleBMR = (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
            let femaleBMR = (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
            bmr = (maleBMR + femaleBMR) / 2
        }
        
        // Calculate TDEE by applying activity multiplier
        tdee = bmr * activityLevel.multiplier
        
        // Apply weight goal modifier to get daily calorie goal
        dailyCalorieGoal = tdee + weightGoal.calorieAdjustment
        
        // Calculate macro goals in grams
        // 1g carbs = 4 calories, 1g protein = 4 calories, 1g fat = 9 calories
        carbGoalGrams = (dailyCalorieGoal * carbPercentage) / 4
        proteinGoalGrams = (dailyCalorieGoal * proteinPercentage) / 4
        fatGoalGrams = (dailyCalorieGoal * fatPercentage) / 9
        
        // Update the timestamp
        updatedAt = Date()
    }
}

// Enums for UserProfile properties
enum Gender: String, Codable, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    case nonBinary = "Non-binary"
    case notSpecified = "Prefer not to say"
    
    var id: String { self.rawValue }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary = "Sedentary (little or no exercise)"
    case light = "Lightly active (light exercise 1-3 days/week)"
    case moderate = "Moderately active (moderate exercise 3-5 days/week)"
    case active = "Active (hard exercise 6-7 days/week)"
    case veryActive = "Very active (very hard exercise & physical job)"
    
    var id: String { self.rawValue }
    
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }
}

enum WeightGoal: String, Codable, CaseIterable, Identifiable {
    case lose = "Lose weight"
    case maintain = "Maintain weight"
    case gain = "Gain weight"
    
    var id: String { self.rawValue }
    
    var calorieAdjustment: Double {
        switch self {
        case .lose: return -500.0  // 500 calorie deficit (approximately 1lb per week)
        case .maintain: return 0.0
        case .gain: return 500.0   // 500 calorie surplus (approximately 1lb per week)
        }
    }
}
