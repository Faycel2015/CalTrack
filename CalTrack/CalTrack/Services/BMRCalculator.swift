//
//  BMRCalculator.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

/// Utility for calculating BMR (Basal Metabolic Rate) and TDEE (Total Daily Energy Expenditure)
struct BMRCalculator {
    // MARK: - Main Calculation Methods
    public typealias Gender = UserProfile.Gender
    
    /// Calculate BMR using the Mifflin-St Jeor Equation
    /// - Parameters:
    ///   - weight: Weight in kilograms
    ///   - height: Height in centimeters
    ///   - age: Age in years
    ///   - gender: Gender of the user
    /// - Returns: BMR in calories per day
    static func calculateBMR(weight: Double, height: Double, age: Int, gender: Gender) -> Double {
        switch gender {
        case .male:
            return (10.0 * weight) + (6.25 * height) - (5.0 * Double(age)) + 5.0
        case .female:
            return (10.0 * weight) + (6.25 * height) - (5.0 * Double(age)) - 161.0
        case .nonBinary, .notSpecified:
            // For non-binary or not specified, calculate average of male and female
            let maleBMR = (10.0 * weight) + (6.25 * height) - (5.0 * Double(age)) + 5.0
            let femaleBMR = (10.0 * weight) + (6.25 * height) - (5.0 * Double(age)) - 161.0
            return (maleBMR + femaleBMR) / 2.0
        }
    }
    
    /// Calculate TDEE based on BMR and activity level
    /// - Parameters:
    ///   - bmr: Base Metabolic Rate
    ///   - activityLevel: User's activity level
    /// - Returns: TDEE in calories per day
    static func calculateTDEE(bmr: Double, activityLevel: ActivityLevel) -> Double {
        return bmr * activityLevel.multiplier
    }
    
    /// Calculate daily calorie goal based on TDEE and weight goal
    /// - Parameters:
    ///   - tdee: Total Daily Energy Expenditure
    ///   - weightGoal: User's weight goal
    /// - Returns: Daily calorie goal in calories per day
    static func calculateDailyCalorieGoal(tdee: Double, weightGoal: WeightGoal) -> Double {
        return tdee + weightGoal.calorieAdjustment
    }
    
    // MARK: - Utility Methods
    
    /// Convert pounds to kilograms
    /// - Parameter pounds: Weight in pounds
    /// - Returns: Weight in kilograms
    static func poundsToKg(_ pounds: Double) -> Double {
        return pounds * 0.45359237
    }
    
    /// Convert kilograms to pounds
    /// - Parameter kg: Weight in kilograms
    /// - Returns: Weight in pounds
    static func kgToPounds(_ kg: Double) -> Double {
        return kg * 2.2046226218
    }
    
    /// Convert feet and inches to centimeters
    /// - Parameters:
    ///   - feet: Height in feet
    ///   - inches: Additional inches
    /// - Returns: Height in centimeters
    static func feetInchesToCm(feet: Int, inches: Double) -> Double {
        let totalInches = Double(feet) * 12.0 + inches
        return totalInches * 2.54
    }
    
    /// Convert centimeters to feet and inches
    /// - Parameter cm: Height in centimeters
    /// - Returns: Tuple containing feet and inches
    static func cmToFeetInches(cm: Double) -> (feet: Int, inches: Double) {
        let totalInches = cm / 2.54
        let feet = Int(totalInches / 12.0)
        let inches = totalInches.truncatingRemainder(dividingBy: 12.0)
        return (feet, inches)
    }
}
