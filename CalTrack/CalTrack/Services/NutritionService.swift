//
//  NutritionService.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftUI
import SwiftData

/// Service class that coordinates nutrition-related operations
class NutritionService {
    private let userRepository: UserRepository
    private let mealRepository: MealRepository
    
    // Cache for nutrition data
    private var cachedDailySummaries: [Date: NutritionSummary] = [:]
    private var cachedWeeklySummary: WeeklyNutritionSummary?
    private var lastRefreshDate: Date?
    
    init(userRepository: UserRepository, mealRepository: MealRepository) {
        self.userRepository = userRepository
        self.mealRepository = mealRepository
    }
    
    // MARK: - Data Loading and Caching
    
    /// Load cached nutrition data
    func loadCachedData() async throws {
        // Get today's date
        let today = Date()
        
        // Load today's nutrition data
        let todaySummary = try await getNutritionSummary(for: today)
        cachedDailySummaries[today] = todaySummary
        
        // Load weekly data
        let weeklySummary = try await getWeeklyNutritionSummary(endDate: today)
        cachedWeeklySummary = weeklySummary
        
        // Store last refresh time
        lastRefreshDate = Date()
    }
    
    /// Refresh nutrition data
    func refreshData() async throws {
        // Clear cache
        cachedDailySummaries.removeAll()
        cachedWeeklySummary = nil
        
        // Reload data
        try await loadCachedData()
    }
    
    /// Get cached nutrition summary or fetch new one
    func getCachedNutritionSummary(for date: Date) async throws -> NutritionSummary {
        // Check if we have a cached version for this date
        if let cachedSummary = cachedDailySummaries[date] {
            return cachedSummary
        }
        
        // Fetch fresh data
        let summary = try await getNutritionSummary(for: date)
        
        // Cache the result
        cachedDailySummaries[date] = summary
        
        return summary
    }
    
    /// Get cached weekly summary or fetch new one
    func getCachedWeeklySummary(endDate: Date = Date()) async throws -> WeeklyNutritionSummary {
        // Check if we have a cached version that's not too old
        if let cachedSummary = cachedWeeklySummary,
           let lastRefresh = lastRefreshDate,
           Calendar.current.isDate(endDate, inSameDayAs: cachedSummary.endDate),
           Calendar.current.dateComponents([.hour], from: lastRefresh, to: Date()).hour! < 1 {
            return cachedSummary
        }
        
        // Fetch fresh data
        let summary = try await getWeeklyNutritionSummary(endDate: endDate)
        
        // Cache the result
        cachedWeeklySummary = summary
        
        return summary
    }
    
    // MARK: - Daily Nutrition Analysis
    
    /// Get nutrition summary for a specific date
    /// - Parameter date: The date to analyze
    /// - Returns: Detailed nutrition summary
    func getNutritionSummary(for date: Date) async throws -> NutritionSummary {
        // Get user profile for goals
        guard let userProfile = try userRepository.getCurrentUserProfile() else {
            throw NutritionServiceError.userProfileNotFound
        }
        
        // Get meals for the date
        let meals = try mealRepository.getMealsForDate(date)
        
        // Calculate totals from meals
        let (totalCalories, totalCarbs, totalProtein, totalFat) = try mealRepository.getTotalNutritionForDate(date)
        
        // Calculate remaining values
        let remainingCalories = max(0, userProfile.dailyCalorieGoal - totalCalories)
        let remainingCarbs = max(0, userProfile.carbGoalGrams - totalCarbs)
        let remainingProtein = max(0, userProfile.proteinGoalGrams - totalProtein)
        let remainingFat = max(0, userProfile.fatGoalGrams - totalFat)
        
        // Calculate percentages
        let caloriePercentage = min(1.0, totalCalories / max(1, userProfile.dailyCalorieGoal))
        let carbPercentage = min(1.0, totalCarbs / max(1, userProfile.carbGoalGrams))
        let proteinPercentage = min(1.0, totalProtein / max(1, userProfile.proteinGoalGrams))
        let fatPercentage = min(1.0, totalFat / max(1, userProfile.fatGoalGrams))
        
        // Calculate macro distribution (percentage of total calories)
        let carbCalories = totalCarbs * 4
        let proteinCalories = totalProtein * 4
        let fatCalories = totalFat * 9
        let totalFromMacros = carbCalories + proteinCalories + fatCalories
        
        let carbDistribution = totalFromMacros > 0 ? carbCalories / totalFromMacros : userProfile.carbPercentage
        let proteinDistribution = totalFromMacros > 0 ? proteinCalories / totalFromMacros : userProfile.proteinPercentage
        let fatDistribution = totalFromMacros > 0 ? fatCalories / totalFromMacros : userProfile.fatPercentage
        
        // Organize meals by type
        var mealsByType: [MealType: [Meal]] = [:]
        for type in MealType.allCases {
            mealsByType[type] = meals.filter { $0.mealType == type }
        }
        
        return NutritionSummary(
            date: date,
            totalCalories: totalCalories,
            totalCarbs: totalCarbs,
            totalProtein: totalProtein,
            totalFat: totalFat,
            goalCalories: userProfile.dailyCalorieGoal,
            goalCarbs: userProfile.carbGoalGrams,
            goalProtein: userProfile.proteinGoalGrams,
            goalFat: userProfile.fatGoalGrams,
            remainingCalories: remainingCalories,
            remainingCarbs: remainingCarbs,
            remainingProtein: remainingProtein,
            remainingFat: remainingFat,
            caloriePercentage: caloriePercentage,
            carbPercentage: carbPercentage,
            proteinPercentage: proteinPercentage,
            fatPercentage: fatPercentage,
            carbDistribution: carbDistribution,
            proteinDistribution: proteinDistribution,
            fatDistribution: fatDistribution,
            meals: meals,
            mealsByType: mealsByType
        )
    }
    
    // MARK: - Weekly Nutrition Analysis
    
    /// Get weekly nutrition summary
    /// - Parameter endDate: The end date of the week (defaults to today)
    /// - Returns: Weekly nutrition summary
    func getWeeklyNutritionSummary(endDate: Date = Date()) async throws -> WeeklyNutritionSummary {
        // Calculate start date (7 days before end date)
        let startDate = Calendar.current.date(byAdding: .day, value: -6, to: endDate)!
        
        // Get user profile for goals
        guard let userProfile = try userRepository.getCurrentUserProfile() else {
            throw NutritionServiceError.userProfileNotFound
        }
        
        // Get weekly totals and averages
        let nutritionData = try mealRepository.getTotalNutritionForDateRange(
            startDate: startDate,
            endDate: endDate
        )
        
        // Get daily summaries
        var dailySummaries: [Date: NutritionSummary] = [:]
        for dayOffset in 0...6 {
            let currentDate = Calendar.current.date(byAdding: .day, value: -dayOffset, to: endDate)!
            // Skip future dates
            if currentDate <= Date() {
                dailySummaries[currentDate] = try await getNutritionSummary(for: currentDate)
            }
        }
        
        // Calculate weekly goals
        let weeklyCalorieGoal = userProfile.dailyCalorieGoal * 7
        let weeklyCarbGoal = userProfile.carbGoalGrams * 7
        let weeklyProteinGoal = userProfile.proteinGoalGrams * 7
        let weeklyFatGoal = userProfile.fatGoalGrams * 7
        
        // Calculate weekly percentages
        let weeklyCaloriePercentage = min(1.0, nutritionData.totalCalories / max(1, weeklyCalorieGoal))
        let weeklyCarbPercentage = min(1.0, nutritionData.totalCarbs / max(1, weeklyCarbGoal))
        let weeklyProteinPercentage = min(1.0, nutritionData.totalProtein / max(1, weeklyProteinGoal))
        let weeklyFatPercentage = min(1.0, nutritionData.totalFat / max(1, weeklyFatGoal))
        
        return WeeklyNutritionSummary(
            startDate: startDate,
            endDate: endDate,
            totalCalories: nutritionData.totalCalories,
            totalCarbs: nutritionData.totalCarbs,
            totalProtein: nutritionData.totalProtein,
            totalFat: nutritionData.totalFat,
            avgCalories: nutritionData.avgCalories,
            avgCarbs: nutritionData.avgCarbs,
            avgProtein: nutritionData.avgProtein,
            avgFat: nutritionData.avgFat,
            weeklyCalorieGoal: weeklyCalorieGoal,
            weeklyCarbGoal: weeklyCarbGoal,
            weeklyProteinGoal: weeklyProteinGoal,
            weeklyFatGoal: weeklyFatGoal,
            weeklyCaloriePercentage: weeklyCaloriePercentage,
            weeklyCarbPercentage: weeklyCarbPercentage,
            weeklyProteinPercentage: weeklyProteinPercentage,
            weeklyFatPercentage: weeklyFatPercentage,
            dailySummaries: dailySummaries
        )
    }
    
    // MARK: - Recommendations
    
    /// Get meal recommendations based on remaining macros
    /// - Parameter date: The date to generate recommendations for
    /// - Returns: Array of meal recommendations
    func getMealRecommendations(for date: Date) async throws -> [MealRecommendation] {
        // Get current nutrition summary
        let summary = try await getNutritionSummary(for: date)
        
        // Determine which meal types haven't been logged yet
        let missingMealTypes = MealType.allCases.filter { summary.mealsByType[$0]?.isEmpty ?? true }
        
        // Generate recommendations based on remaining macros and missing meal types
        var recommendations: [MealRecommendation] = []
        
        // Simplified recommendation logic (in a real app, this would be more sophisticated)
        if summary.remainingCalories > 500 && missingMealTypes.contains(.dinner) {
            recommendations.append(
                MealRecommendation(
                    title: "Balanced Dinner",
                    calories: 500,
                    carbs: 50,
                    protein: 30,
                    fat: 15,
                    mealType: .dinner,
                    reasoning: "Provides balanced nutrition to complete your daily goals."
                )
            )
        }
        
        if summary.remainingCalories > 200 && summary.remainingProtein > 20 && missingMealTypes.contains(.snack) {
            recommendations.append(
                MealRecommendation(
                    title: "Protein Snack",
                    calories: 200,
                    carbs: 10,
                    protein: 25,
                    fat: 8,
                    mealType: .snack,
                    reasoning: "Helps meet your remaining protein goals."
                )
            )
        }
        
        if summary.remainingCalories < 300 && summary.remainingCalories > 0 {
            recommendations.append(
                MealRecommendation(
                    title: "Light Snack",
                    calories: min(summary.remainingCalories, 150),
                    carbs: min(summary.remainingCarbs, 15),
                    protein: min(summary.remainingProtein, 10),
                    fat: min(summary.remainingFat, 5),
                    mealType: .snack,
                    reasoning: "Light option to complete your daily goals without exceeding limits."
                )
            )
        }
        
        return recommendations
    }
}

// MARK: - Data Models

/// Detailed nutrition summary for a specific date
struct NutritionSummary {
    let date: Date
    
    // Totals
    let totalCalories: Double
    let totalCarbs: Double
    let totalProtein: Double
    let totalFat: Double
    
    // Goals
    let goalCalories: Double
    let goalCarbs: Double
    let goalProtein: Double
    let goalFat: Double
    
    // Remaining
    let remainingCalories: Double
    let remainingCarbs: Double
    let remainingProtein: Double
    let remainingFat: Double
    
    // Progress percentages
    let caloriePercentage: Double
    let carbPercentage: Double
    let proteinPercentage: Double
    let fatPercentage: Double
    
    // Macro distribution (percentage of total calories)
    let carbDistribution: Double
    let proteinDistribution: Double
    let fatDistribution: Double
    
    // Meals
    let meals: [Meal]
    let mealsByType: [MealType: [Meal]]
}

/// Weekly nutrition summary
struct WeeklyNutritionSummary {
    let startDate: Date
    let endDate: Date
    
    // Weekly totals
    let totalCalories: Double
    let totalCarbs: Double
    let totalProtein: Double
    let totalFat: Double
    
    // Daily averages
    let avgCalories: Double
    let avgCarbs: Double
    let avgProtein: Double
    let avgFat: Double
    
    // Weekly goals
    let weeklyCalorieGoal: Double
    let weeklyCarbGoal: Double
    let weeklyProteinGoal: Double
    let weeklyFatGoal: Double
    
    // Weekly progress percentages
    let weeklyCaloriePercentage: Double
    let weeklyCarbPercentage: Double
    let weeklyProteinPercentage: Double
    let weeklyFatPercentage: Double
    
    // Daily breakdowns
    let dailySummaries: [Date: NutritionSummary]
}

/// Meal recommendation based on remaining macros
struct MealRecommendation {
    let title: String
    let calories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
    let mealType: MealType
    let reasoning: String
}

// MARK: - Errors

enum NutritionServiceError: Error {
    case userProfileNotFound
    case failedToCalculateNutrition(String)
    case cachingError(String)
    
    var errorDescription: String {
        switch self {
        case .userProfileNotFound:
            return "User profile not found. Please complete your profile setup."
        case .failedToCalculateNutrition(let reason):
            return "Failed to calculate nutrition: \(reason)"
        case .cachingError(let reason):
            return "Error caching nutrition data: \(reason)"
        }
    }
}
