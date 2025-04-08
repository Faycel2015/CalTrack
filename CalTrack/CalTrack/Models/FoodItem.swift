//
//  FoodItem.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftData

@Model
final class FoodItem: @unchecked Sendable {  // Use @unchecked Sendable instead of just Sendable
    // Basic information
    var name: String
    var servingSize: String  // e.g., "1 cup", "100g"
    var servingQuantity: Double  // number of servings
    
    // Nutritional information (per serving)
    var calories: Double
    var carbs: Double  // in grams
    var protein: Double  // in grams
    var fat: Double  // in grams
    
    // Additional nutritional details (optional)
    var sugar: Double?
    var fiber: Double?
    var sodium: Double?
    var cholesterol: Double?
    var saturatedFat: Double?
    var transFat: Double?
    
    // Source information
    var isCustom: Bool
    var barcode: String?
    var foodDatabaseId: String?  // ID from external database if applicable
    
    // Relationship to parent meal
    var meal: Meal?
    
    // User-specific data
    var isFavorite: Bool
    var lastUsedDate: Date?
    var useCount: Int
    
    // Creation timestamp
    var createdAt: Date
    
    init(
        name: String = "",
        servingSize: String = "",
        servingQuantity: Double = 1.0,
        calories: Double = 0.0,
        carbs: Double = 0.0,
        protein: Double = 0.0,
        fat: Double = 0.0,
        sugar: Double? = nil,
        fiber: Double? = nil,
        sodium: Double? = nil,
        cholesterol: Double? = nil,
        saturatedFat: Double? = nil,
        transFat: Double? = nil,
        isCustom: Bool = true,
        barcode: String? = nil,
        foodDatabaseId: String? = nil,
        isFavorite: Bool = false,
        useCount: Int = 0
    ) {
        self.name = name
        self.servingSize = servingSize
        self.servingQuantity = servingQuantity
        self.calories = calories
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.sugar = sugar
        self.fiber = fiber
        self.sodium = sodium
        self.cholesterol = cholesterol
        self.saturatedFat = saturatedFat
        self.transFat = transFat
        self.isCustom = isCustom
        self.barcode = barcode
        self.foodDatabaseId = foodDatabaseId
        self.isFavorite = isFavorite
        self.useCount = useCount
        self.lastUsedDate = isCustom ? Date() : nil
        self.createdAt = Date()
    }
    
    // Calculate total nutrition for current quantity
    var totalCalories: Double {
        return calories * servingQuantity
    }
    
    var totalCarbs: Double {
        return carbs * servingQuantity
    }
    
    var totalProtein: Double {
        return protein * servingQuantity
    }
    
    var totalFat: Double {
        return fat * servingQuantity
    }
    
    // Track usage - should be marked as isolated or nonisolated
    // since we're making the class Sendable
    nonisolated func recordUsage() {
        // We're manually ensuring thread safety or accepting the risk
        // This is why we're using @unchecked Sendable
        useCount += 1
        lastUsedDate = Date()
    }
}

// Food database (for built-in & common foods)
actor FoodDatabase {  // Already an actor, which is thread-safe
    static let shared = FoodDatabase()
    
    private init() {}
    
    // Common food categories
    enum FoodCategory: String, CaseIterable, Identifiable {
        case fruits = "Fruits"
        case vegetables = "Vegetables"
        case grains = "Grains & Bread"
        case protein = "Protein Foods"
        case dairy = "Dairy"
        case snacks = "Snacks"
        case beverages = "Beverages"
        case prepared = "Prepared Meals"
        case condiments = "Condiments"
        
        var id: String { self.rawValue }
        
        var systemImage: String {
            switch self {
            case .fruits: return "apple.logo"
            case .vegetables: return "leaf"
            case .grains: return "square.grid.2x2"
            case .protein: return "seal"
            case .dairy: return "cup.and.saucer"
            case .snacks: return "bag"
            case .beverages: return "mug"
            case .prepared: return "takeoutbag.and.cup.and.straw"
            case .condiments: return "drop"
            }
        }
    }
    
    // Sample common foods
    func getCommonFoods() -> [FoodItem] {
        return [
            FoodItem(name: "Apple", servingSize: "1 medium (182g)", servingQuantity: 1, calories: 95, carbs: 25, protein: 0.5, fat: 0.3, sugar: 19, fiber: 4, isCustom: false, foodDatabaseId: "fruit_apple"),
            FoodItem(name: "Banana", servingSize: "1 medium (118g)", servingQuantity: 1, calories: 105, carbs: 27, protein: 1.3, fat: 0.4, sugar: 14, fiber: 3, isCustom: false, foodDatabaseId: "fruit_banana"),
            FoodItem(name: "Chicken Breast", servingSize: "100g", servingQuantity: 1, calories: 165, carbs: 0, protein: 31, fat: 3.6, sodium: 74, isCustom: false, foodDatabaseId: "protein_chicken_breast"),
            FoodItem(name: "White Rice", servingSize: "1 cup cooked (158g)", servingQuantity: 1, calories: 205, carbs: 45, protein: 4.3, fat: 0.4, fiber: 0.6, isCustom: false, foodDatabaseId: "grain_white_rice"),
            FoodItem(name: "Whole Milk", servingSize: "1 cup (244g)", servingQuantity: 1, calories: 149, carbs: 12, protein: 8, fat: 8, sugar: 12, isCustom: false, foodDatabaseId: "dairy_whole_milk")
        ]
    }
    
    // Search common foods
    func searchFoods(query: String) -> [FoodItem] {
        if query.isEmpty { return [] }
        
        let lowercasedQuery = query.lowercased()
        return getCommonFoods().filter { $0.name.lowercased().contains(lowercasedQuery) }
    }
}

// Add image name support
extension FoodItem {
    var imageName: String? {
        let validNames = ["Apple", "Banana", "Chicken Breast", "White Rice", "Whole Milk"]
        return validNames.contains(name) ? name : nil
    }
}
