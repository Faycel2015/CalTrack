//
//  NutritionService.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftData

/// Repository class for handling food item data operations
class FoodRepository {
    private let modelContext: ModelContext
    private let foodDatabase = FoodDatabase.shared
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD Operations
    
    /// Save a food item to the database
    /// - Parameter foodItem: The food item to save
    func saveFoodItem(_ foodItem: FoodItem) throws {
        modelContext.insert(foodItem)
        try modelContext.save()
    }
    
    /// Update an existing food item
    /// - Parameter foodItem: The food item to update
    func updateFoodItem(_ foodItem: FoodItem) throws {
        try modelContext.save()
    }
    
    /// Delete a food item
    /// - Parameter foodItem: The food item to delete
    func deleteFoodItem(_ foodItem: FoodItem) throws {
        modelContext.delete(foodItem)
        try modelContext.save()
    }
    
    /// Get a food item by ID
    /// - Parameter id: The ID of the food item
    /// - Returns: The food item if found, nil otherwise
    func getFoodItem(withID id: PersistentIdentifier) throws -> FoodItem? {
        let descriptor = FetchDescriptor<FoodItem>(predicate: #Predicate { $0.persistentModelID == id })
        let items = try modelContext.fetch(descriptor)
        return items.first
    }
    
    // MARK: - Food Queries
    
    /// Search for food items in the database
    /// - Parameter query: The search query
    /// - Returns: Array of matching food items
    func searchFoodItems(_ query: String) throws -> [FoodItem] {
        if query.isEmpty {
            return []
        }
        
        let lowercasedQuery = query.lowercased()
        
        // First, search custom food items in the database
        let customPredicate = #Predicate<FoodItem> { foodItem in
            foodItem.name.localizedStandardContains(lowercasedQuery)
        }
        
        let descriptor = FetchDescriptor<FoodItem>(predicate: customPredicate)
        let customResults = try modelContext.fetch(descriptor)
        
        // Then, search the built-in food database
        let builtInResults = foodDatabase.searchFoods(query: query)
        
        // Combine the results, with custom items first
        return customResults + builtInResults
    }
    
    /// Get recent food items
    /// - Parameter limit: Maximum number of items to return
    /// - Returns: Array of recent food items
    func getRecentFoodItems(limit: Int = 10) throws -> [FoodItem] {
        let sortDescriptor = SortDescriptor<FoodItem>(\.lastUsedDate, order: .reverse)
        var descriptor = FetchDescriptor<FoodItem>(sortBy: [sortDescriptor])
        descriptor.predicate = #Predicate<FoodItem> { $0.lastUsedDate != nil }
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }
    
    /// Get frequently used food items
    /// - Parameter limit: Maximum number of items to return
    /// - Returns: Array of frequently used food items
    func getFrequentlyUsedFoodItems(limit: Int = 10) throws -> [FoodItem] {
        let sortDescriptor = SortDescriptor<FoodItem>(\.useCount, order: .reverse)
        var descriptor = FetchDescriptor<FoodItem>(sortBy: [sortDescriptor])
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }
    
    /// Get favorite food items
    /// - Returns: Array of favorite food items
    func getFavoriteFoodItems() throws -> [FoodItem] {
        let predicate = #Predicate<FoodItem> { $0.isFavorite == true }
        let sortDescriptor = SortDescriptor<FoodItem>(\.name)
        let descriptor = FetchDescriptor<FoodItem>(predicate: predicate, sortBy: [sortDescriptor])
        return try modelContext.fetch(descriptor)
    }
    
    /// Record usage of a food item
    /// - Parameter foodItem: The food item to record usage for
    func recordFoodItemUsage(_ foodItem: FoodItem) throws {
        foodItem.recordUsage()
        try modelContext.save()
    }
    
    /// Toggle favorite status of a food item
    /// - Parameter foodItem: The food item to toggle favorite status for
    /// - Returns: Updated favorite status
    func toggleFavorite(for foodItem: FoodItem) throws -> Bool {
        foodItem.isFavorite.toggle()
        try modelContext.save()
        return foodItem.isFavorite
    }
    
    // MARK: - Food Database Operations
    
    /// Get common food items from the built-in database
    /// - Returns: Array of common food items
    func getCommonFoodItems() -> [FoodItem] {
        return foodDatabase.getCommonFoods()
    }
    
    /// Create a custom food item
    /// - Parameters:
    ///   - name: Name of the food
    ///   - servingSize: Serving size description
    ///   - nutritionData: Tuple containing nutritional values
    /// - Returns: The created food item
    func createCustomFoodItem(
        name: String,
        servingSize: String,
        nutritionData: (calories: Double, carbs: Double, protein: Double, fat: Double)
    ) -> FoodItem {
        return FoodItem(
            name: name,
            servingSize: servingSize,
            servingQuantity: 1.0,
            calories: nutritionData.calories,
            carbs: nutritionData.carbs,
            protein: nutritionData.protein,
            fat: nutritionData.fat,
            isCustom: true
        )
    }
}

/// Errors that can occur during food item operations
enum FoodRepositoryError: Error {
    case foodItemNotFound
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    
    var errorDescription: String {
        switch self {
        case .foodItemNotFound:
            return "Food item not found"
        case .saveFailed(let error):
            return "Failed to save food item: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch food items: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete food item: \(error.localizedDescription)"
        }
    }
}
