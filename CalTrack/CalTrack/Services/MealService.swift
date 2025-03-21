//
//  MealService.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation

/// Service class that coordinates meal-related operations
class MealService {
    private let mealRepository: MealRepository
    private let foodRepository: FoodRepository
    
    init(mealRepository: MealRepository, foodRepository: FoodRepository) {
        self.mealRepository = mealRepository
        self.foodRepository = foodRepository
    }
    
    // MARK: - Meal Operations
    
    /// Create a new meal
    /// - Parameters:
    ///   - name: Name of the meal
    ///   - date: Date of the meal
    ///   - mealType: Type of meal (breakfast, lunch, etc.)
    ///   - foodItems: Food items in the meal
    /// - Returns: The created meal
    func createMeal(
        name: String,
        date: Date,
        mealType: MealType,
        foodItems: [FoodItem] = []
    ) throws -> Meal {
        // Create the meal
        let meal = Meal(
            name: name,
            date: date,
            mealType: mealType
        )
        
        // Add food items to the meal
        for item in foodItems {
            item.meal = meal
            try foodRepository.recordFoodItemUsage(item)
        }
        
        // Update nutrition values
        meal.updateNutrition()
        
        // Save the meal
        try mealRepository.saveMeal(meal)
        
        return meal
    }
    
    /// Update an existing meal
    /// - Parameters:
    ///   - meal: The meal to update
    ///   - name: New name (optional)
    ///   - date: New date (optional)
    ///   - mealType: New meal type (optional)
    ///   - foodItems: New food items (optional)
    /// - Returns: The updated meal
    func updateMeal(
        meal: Meal,
        name: String? = nil,
        date: Date? = nil,
        mealType: MealType? = nil,
        foodItems: [FoodItem]? = nil
    ) throws -> Meal {
        // Update meal properties
        if let name = name {
            meal.name = name
        }
        
        if let date = date {
            meal.date = date
        }
        
        if let mealType = mealType {
            meal.mealType = mealType
        }
        
        // Update food items if provided
        if let foodItems = foodItems {
            // Remove existing items
            meal.foodItems = []
            
            // Add new items
            for item in foodItems {
                item.meal = meal
                try foodRepository.recordFoodItemUsage(item)
            }
        }
        
        // Update nutrition values
        meal.updateNutrition()
        
        // Save changes
        try mealRepository.updateMeal(meal)
        
        return meal
    }
    
    /// Delete a meal
    /// - Parameter meal: The meal to delete
    func deleteMeal(_ meal: Meal) throws {
        try mealRepository.deleteMeal(meal)
    }
    
    /// Toggle favorite status for a meal
    /// - Parameter meal: The meal to toggle favorite status for
    /// - Returns: Updated favorite status
    func toggleFavoriteMeal(_ meal: Meal) throws -> Bool {
        meal.isFavorite.toggle()
        try mealRepository.updateMeal(meal)
        return meal.isFavorite
    }
    
    // MARK: - Food Item Operations
    
    /// Add a food item to a meal
    /// - Parameters:
    ///   - meal: The meal to add the food item to
    ///   - foodItem: The food item to add
    ///   - quantity: Serving quantity (default: 1.0)
    /// - Returns: The updated meal
    func addFoodItemToMeal(
        meal: Meal,
        foodItem: FoodItem,
        quantity: Double = 1.0
    ) throws -> Meal {
        // Create a copy of the food item with the specified quantity
        let newItem = FoodItem(
            name: foodItem.name,
            servingSize: foodItem.servingSize,
            servingQuantity: quantity,
            calories: foodItem.calories,
            carbs: foodItem.carbs,
            protein: foodItem.protein,
            fat: foodItem.fat,
            sugar: foodItem.sugar,
            fiber: foodItem.fiber,
            sodium: foodItem.sodium,
            cholesterol: foodItem.cholesterol,
            saturatedFat: foodItem.saturatedFat,
            transFat: foodItem.transFat,
            isCustom: foodItem.isCustom,
            barcode: foodItem.barcode,
            foodDatabaseId: foodItem.foodDatabaseId,
            isFavorite: foodItem.isFavorite
        )
        
        // Add to meal
        newItem.meal = meal
        
        // Record usage
        try foodRepository.recordFoodItemUsage(foodItem)
        
        // Update nutrition values
        meal.updateNutrition()
        
        // Save changes
        try mealRepository.updateMeal(meal)
        
        return meal
    }
    
    /// Remove a food item from a meal
    /// - Parameters:
    ///   - meal: The meal to remove the food item from
    ///   - foodItem: The food item to remove
    /// - Returns: The updated meal
    func removeFoodItemFromMeal(
        meal: Meal,
        foodItem: FoodItem
    ) throws -> Meal {
        // Remove the food item
        meal.foodItems.removeAll { $0.id == foodItem.id }
        
        // Update nutrition values
        meal.updateNutrition()
        
        // Save changes
        try mealRepository.updateMeal(meal)
        
        return meal
    }
    
    /// Create a custom food item
    /// - Parameters:
    ///   - name: Name of the food
    ///   - servingSize: Serving size description
    ///   - calories: Calories per serving
    ///   - carbs: Carbs per serving
    ///   - protein: Protein per serving
    ///   - fat: Fat per serving
    ///   - additionalNutrition: Additional nutrition information (optional)
    /// - Returns: The created food item
    func createCustomFoodItem(
        name: String,
        servingSize: String,
        calories: Double,
        carbs: Double,
        protein: Double,
        fat: Double,
        additionalNutrition: AdditionalNutrition? = nil
    ) throws -> FoodItem {
        let item = FoodItem(
            name: name,
            servingSize: servingSize,
            servingQuantity: 1.0,
            calories: calories,
            carbs: carbs,
            protein: protein,
            fat: fat,
            sugar: additionalNutrition?.sugar,
            fiber: additionalNutrition?.fiber,
            sodium: additionalNutrition?.sodium,
            cholesterol: additionalNutrition?.cholesterol,
            saturatedFat: additionalNutrition?.saturatedFat,
            transFat: additionalNutrition?.transFat,
            isCustom: true
        )
        
        try foodRepository.saveFoodItem(item)
        return item
    }
    
    // MARK: - Meal Querying
    
    /// Get meals for a specific date
    /// - Parameter date: The date to get meals for
    /// - Returns: Array of meals for the date
    func getMealsForDate(_ date: Date) throws -> [Meal] {
        return try mealRepository.getMealsForDate(date)
    }
    
    /// Get meals by type
    /// - Parameter type: The meal type to filter by
    /// - Returns: Array of meals of the specified type
    func getMealsByType(_ type: MealType) throws -> [Meal] {
        return try mealRepository.getMealsByType(type)
    }
    
    /// Get favorite meals
    /// - Returns: Array of favorite meals
    func getFavoriteMeals() throws -> [Meal] {
        return try mealRepository.getFavoriteMeals()
    }
    
    /// Get recent meals
    /// - Parameter limit: Maximum number of meals to return
    /// - Returns: Array of recent meals
    func getRecentMeals(limit: Int = 10) throws -> [Meal] {
        return try mealRepository.getRecentMeals(limit: limit)
    }
    
    // MARK: - Food Querying
    
    /// Search for food items
    /// - Parameter query: The search query
    /// - Returns: Array of matching food items
    func searchFoodItems(_ query: String) throws -> [FoodItem] {
        return try foodRepository.searchFoodItems(query)
    }
    
    /// Get favorite food items
    /// - Returns: Array of favorite food items
    func getFavoriteFoodItems() throws -> [FoodItem] {
        return try foodRepository.getFavoriteFoodItems()
    }
    
    /// Get recent food items
    /// - Parameter limit: Maximum number of items to return
    /// - Returns: Array of recent food items
    func getRecentFoodItems(limit: Int = 10) throws -> [FoodItem] {
        return try foodRepository.getRecentFoodItems(limit: limit)
    }
    
    /// Get frequently used food items
    /// - Parameter limit: Maximum number of items to return
    /// - Returns: Array of frequently used food items
    func getFrequentlyUsedFoodItems(limit: Int = 10) throws -> [FoodItem] {
        return try foodRepository.getFrequentlyUsedFoodItems(limit: limit)
    }
    
    /// Toggle favorite status for a food item
    /// - Parameter foodItem: The food item to toggle favorite status for
    /// - Returns: Updated favorite status
    func toggleFavoriteFoodItem(_ foodItem: FoodItem) throws -> Bool {
        return try foodRepository.toggleFavorite(for: foodItem)
    }
}

// MARK: - Data Models

/// Additional nutrition information for food items
struct AdditionalNutrition {
    let sugar: Double?
    let fiber: Double?
    let sodium: Double?
    let cholesterol: Double?
    let saturatedFat: Double?
    let transFat: Double?
}

// MARK: - Errors

enum MealServiceError: Error {
    case invalidMealData(String)
    case invalidFoodItemData(String)
    case failedToSave(Error)
    
    var errorDescription: String {
        switch self {
        case .invalidMealData(let reason):
            return "Invalid meal data: \(reason)"
        case .invalidFoodItemData(let reason):
            return "Invalid food item data: \(reason)"
        case .failedToSave(let error):
            return "Failed to save: \(error.localizedDescription)"
        }
    }
}
