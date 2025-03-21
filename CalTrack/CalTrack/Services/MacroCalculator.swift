//
//  MacroCalculator.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation

/// Utility for calculating macronutrient requirements
struct MacroCalculator {
    
    // MARK: - Constants
    
    /// Calories per gram of each macronutrient
    struct CaloriesPerGram {
        static let carbohydrate: Double = 4.0
        static let protein: Double = 4.0
        static let fat: Double = 9.0
    }
    
    // MARK: - Main Calculation Methods
    
    /// Calculate macronutrient distribution in grams based on percentages
    /// - Parameters:
    ///   - totalCalories: Total daily calorie goal
    ///   - carbPercentage: Percentage of calories from carbohydrates (0.0 - 1.0)
    ///   - proteinPercentage: Percentage of calories from protein (0.0 - 1.0)
    ///   - fatPercentage: Percentage of calories from fat (0.0 - 1.0)
    /// - Returns: Tuple containing grams of each macronutrient
    static func calculateMacros(
        totalCalories: Double,
        carbPercentage: Double,
        proteinPercentage: Double,
        fatPercentage: Double
    ) -> (carbsInGrams: Double, proteinInGrams: Double, fatInGrams: Double) {
        
        // Calculate calories from each macro
        let carbCalories = totalCalories * carbPercentage
        let proteinCalories = totalCalories * proteinPercentage
        let fatCalories = totalCalories * fatPercentage
        
        // Convert calories to grams
        let carbsInGrams = carbCalories / CaloriesPerGram.carbohydrate
        let proteinInGrams = proteinCalories / CaloriesPerGram.protein
        let fatInGrams = fatCalories / CaloriesPerGram.fat
        
        return (carbsInGrams, proteinInGrams, fatInGrams)
    }
    
    /// Calculate recommended protein intake based on weight and activity level
    /// - Parameters:
    ///   - weightKg: Weight in kilograms
    ///   - activityLevel: User's activity level
    /// - Returns: Recommended protein in grams
    static func recommendedProtein(weightKg: Double, activityLevel: ActivityLevel) -> Double {
        // General recommendations based on activity level and weight
        let multiplier: Double
        
        switch activityLevel {
        case .sedentary:
            multiplier = 0.8  // 0.8g per kg for sedentary individuals
        case .light:
            multiplier = 1.0  // 1.0g per kg for light activity
        case .moderate:
            multiplier = 1.2  // 1.2g per kg for moderate activity
        case .active, .veryActive:
            multiplier = 1.6  // 1.6-2.0g per kg for active individuals
        }
        
        return weightKg * multiplier
    }
    
    /// Generate a recommended macro distribution based on weight goal
    /// - Parameter weightGoal: User's weight goal
    /// - Returns: Tuple containing recommended macro percentages (0.0 - 1.0)
    static func recommendedMacroDistribution(weightGoal: WeightGoal) -> (carbs: Double, protein: Double, fat: Double) {
        switch weightGoal {
        case .lose:
            // Higher protein, moderate fat for weight loss
            return (carbs: 0.35, protein: 0.40, fat: 0.25)
        case .maintain:
            // Balanced distribution for maintenance
            return (carbs: 0.40, protein: 0.30, fat: 0.30)
        case .gain:
            // Higher carbs for weight/muscle gain
            return (carbs: 0.45, protein: 0.30, fat: 0.25)
        }
    }
    
    // MARK: - Utility Methods
    
    /// Calculate total calories from macronutrients
    /// - Parameters:
    ///   - carbsInGrams: Grams of carbohydrates
    ///   - proteinInGrams: Grams of protein
    ///   - fatInGrams: Grams of fat
    /// - Returns: Total calories
    static func calculateCaloriesFromMacros(
        carbsInGrams: Double,
        proteinInGrams: Double,
        fatInGrams: Double
    ) -> Double {
        let carbCalories = carbsInGrams * CaloriesPerGram.carbohydrate
        let proteinCalories = proteinInGrams * CaloriesPerGram.protein
        let fatCalories = fatInGrams * CaloriesPerGram.fat
        
        return carbCalories + proteinCalories + fatCalories
    }
    
    /// Normalize macro percentages to ensure they sum to 1.0
    /// - Parameters:
    ///   - carbPercentage: Initial carbohydrate percentage
    ///   - proteinPercentage: Initial protein percentage
    ///   - fatPercentage: Initial fat percentage
    /// - Returns: Tuple containing normalized percentages
    static func normalizeMacroPercentages(
        carbPercentage: Double,
        proteinPercentage: Double,
        fatPercentage: Double
    ) -> (carbs: Double, protein: Double, fat: Double) {
        let total = carbPercentage + proteinPercentage + fatPercentage
        
        guard total > 0 else {
            // Default to 40/30/30 if total is zero
            return (carbs: 0.4, protein: 0.3, fat: 0.3)
        }
        
        let normalizedCarbs = carbPercentage / total
        let normalizedProtein = proteinPercentage / total
        let normalizedFat = fatPercentage / total
        
        return (carbs: normalizedCarbs, protein: normalizedProtein, fat: normalizedFat)
    }
}
