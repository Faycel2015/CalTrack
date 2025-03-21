//
//  MealRepository.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftData

/// Repository class for handling meal data operations
class MealRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Meal Operations
    
    /// Fetch meals for a specific date
    /// - Parameter date: The date to fetch meals for
    /// - Returns: Array of meals for the specified date
    func getMealsForDate(_ date: Date) throws -> [Meal] {
        let startOfDay = date.startOfDay()
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<Meal> { meal in
            meal.date >= startOfDay && meal.date < endOfDay
        }
        
        let descriptor = FetchDescriptor<Meal>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetch meals for a date range
    /// - Parameters:
    ///   - startDate: The start date of the range
    ///   - endDate: The end date of the range
    /// - Returns: Array of meals within the date range
    func getMealsForDateRange(startDate: Date, endDate: Date) throws -> [Meal] {
        let startOfStartDay = startDate.startOfDay()
        let endOfEndDay = Calendar.current.date(byAdding: .day, value: 1, to: endDate.startOfDay())!
        
        let predicate = #Predicate<Meal> { meal in
            meal.date >= startOfStartDay && meal.date < endOfEndDay
        }
        
        let descriptor = FetchDescriptor<Meal>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }
    
    /// Save a meal to the database
    /// - Parameter meal: The meal to save
    func saveMeal(_ meal: Meal) throws {
        modelContext.insert(meal)
        try modelContext.save()
    }
    
    /// Update an existing meal
    /// - Parameter meal: The meal to update
    func updateMeal(_ meal: Meal) throws {
        // Recalculate nutrition values based on food items
        meal.updateNutrition()
        meal.updatedAt = Date()
        
        try modelContext.save()
    }
    
    /// Delete a meal
    /// - Parameter meal: The meal to delete
    func deleteMeal(_ meal: Meal) throws {
        modelContext.delete(meal)
        try modelContext.save()
    }
    
    /// Save multiple meals in a batch
    /// - Parameter meals: Array of meals to save
    func saveMeals(_ meals: [Meal]) throws {
        for meal in meals {
            modelContext.insert(meal)
        }
        try modelContext.save()
    }
    
    // MARK: - Meal Querying
    
    /// Get all meals by type
    /// - Parameter type: The meal type to filter by
    /// - Returns: Array of meals of the specified type
    func getMealsByType(_ type: MealType) throws -> [Meal] {
        let predicate = #Predicate<Meal> { meal in
            meal.mealType == type
        }
        
        let descriptor = FetchDescriptor<Meal>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }
    
    /// Get favorite meals
    /// - Returns: Array of favorite meals
    func getFavoriteMeals() throws -> [Meal] {
        let predicate = #Predicate<Meal> { meal in
            meal.isFavorite == true
        }
        
        let sortDescriptor = SortDescriptor<Meal>(\.updatedAt, order: .reverse)
        let descriptor = FetchDescriptor<Meal>(predicate: predicate, sortBy: [sortDescriptor])
        return try modelContext.fetch(descriptor)
    }
    
    /// Get recent meals
    /// - Parameter limit: Maximum number of meals to return
    /// - Returns: Array of recent meals, ordered by date
    func getRecentMeals(limit: Int = 10) throws -> [Meal] {
        let sortDescriptor = SortDescriptor<Meal>(\.date, order: .reverse)
        var descriptor = FetchDescriptor<Meal>(sortBy: [sortDescriptor])
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Nutrition Summary
    
    /// Get total nutrition for a specific date
    /// - Parameter date: The date to calculate nutrition for
    /// - Returns: Tuple with total calories, carbs, protein, and fat
    func getTotalNutritionForDate(_ date: Date) throws -> (calories: Double, carbs: Double, protein: Double, fat: Double) {
        let meals = try getMealsForDate(date)
        
        var totalCalories: Double = 0
        var totalCarbs: Double = 0
        var totalProtein: Double = 0
        var totalFat: Double = 0
        
        for meal in meals {
            totalCalories += meal.calories
            totalCarbs += meal.carbs
            totalProtein += meal.protein
            totalFat += meal.fat
        }
        
        return (totalCalories, totalCarbs, totalProtein, totalFat)
    }
    
    /// Get total nutrition for a date range
    /// - Parameters:
    ///   - startDate: The start date of the range
    ///   - endDate: The end date of the range
    /// - Returns: Tuple with total and average nutrition values
    func getTotalNutritionForDateRange(
        startDate: Date,
        endDate: Date
    ) throws -> (
        totalCalories: Double,
        totalCarbs: Double,
        totalProtein: Double,
        totalFat: Double,
        avgCalories: Double,
        avgCarbs: Double,
        avgProtein: Double,
        avgFat: Double
    ) {
        let meals = try getMealsForDateRange(startDate: startDate, endDate: endDate)
        
        var totalCalories: Double = 0
        var totalCarbs: Double = 0
        var totalProtein: Double = 0
        var totalFat: Double = 0
        
        for meal in meals {
            totalCalories += meal.calories
            totalCarbs += meal.carbs
            totalProtein += meal.protein
            totalFat += meal.fat
        }
        
        // Calculate number of days in the range
        let numberOfDays = max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
        
        // Calculate daily averages
        let avgCalories = totalCalories / Double(numberOfDays)
        let avgCarbs = totalCarbs / Double(numberOfDays)
        let avgProtein = totalProtein / Double(numberOfDays)
        let avgFat = totalFat / Double(numberOfDays)
        
        return (
            totalCalories,
            totalCarbs,
            totalProtein,
            totalFat,
            avgCalories,
            avgCarbs,
            avgProtein,
            avgFat
        )
    }
}

/// Errors that can occur during meal operations
enum MealRepositoryError: Error {
    case mealNotFound
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    
    var errorDescription: String {
        switch self {
        case .mealNotFound:
            return "Meal not found"
        case .saveFailed(let error):
            return "Failed to save meal: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch meals: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete meal: \(error.localizedDescription)"
        }
    }
}
