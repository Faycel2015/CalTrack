//
//  Meal.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftData

@Model
class Meal {
    // Identifiers and metadata
    var name: String
    var date: Date
    var mealType: MealType
    var isFavorite: Bool
    
    // Nutritional information
    var calories: Double
    var carbs: Double  // in grams
    var protein: Double  // in grams
    var fat: Double  // in grams
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \FoodItem.meal)
    var foodItems: [FoodItem] = []
    
    // Additional optional info
    var notes: String?
    var imageData: Data?  // Optional image of the meal
    
    // Creation/modification timestamps
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String = "",
        date: Date = Date(),
        mealType: MealType = .other,
        isFavorite: Bool = false,
        calories: Double = 0.0,
        carbs: Double = 0.0,
        protein: Double = 0.0,
        fat: Double = 0.0,
        notes: String? = nil,
        imageData: Data? = nil
    ) {
        self.name = name
        self.date = date
        self.mealType = mealType
        self.isFavorite = isFavorite
        self.calories = calories
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.notes = notes
        self.imageData = imageData
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Update nutritional values based on food items
    func updateNutrition() {
        var totalCalories: Double = 0
        var totalCarbs: Double = 0
        var totalProtein: Double = 0
        var totalFat: Double = 0
        
        for item in foodItems {
            totalCalories += item.calories * item.servingQuantity
            totalCarbs += item.carbs * item.servingQuantity
            totalProtein += item.protein * item.servingQuantity
            totalFat += item.fat * item.servingQuantity
        }
        
        self.calories = totalCalories
        self.carbs = totalCarbs
        self.protein = totalProtein
        self.fat = totalFat
        self.updatedAt = Date()
    }
}

// Extension to handle meal grouping by day
extension Date {
    func startOfDay() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        return calendar.date(from: components) ?? self
    }
    
    var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}
