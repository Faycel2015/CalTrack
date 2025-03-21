//
//  MealViewModel.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftData
import Combine
import SwiftUI

@Observable
class MealViewModel {
    // MARK: - Properties
    
    private var modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    // Date selection
    var selectedDate: Date = Date()
    
    // Meal creation/editing
    var isCreatingMeal: Bool = false
    var isEditingMeal: Bool = false
    var currentMeal: Meal?
    var selectedMealType: MealType = .breakfast
    var mealName: String = ""
    
    // Food selection
    var searchQuery: String = ""
    var searchResults: [FoodItem] = []
    var selectedFoodItems: [FoodItem] = []
    var isAddingFoodItem: Bool = false
    var currentFoodItem: FoodItem?
    var servingQuantity: String = "1.0"
    
    // Quick add
    var quickAddCalories: String = ""
    var quickAddCarbs: String = ""
    var quickAddProtein: String = ""
    var quickAddFat: String = ""
    
    // Recent and favorite foods
    var recentFoods: [FoodItem] = []
    var favoriteFoods: [FoodItem] = []
    
    // MARK: - Initializer
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadRecentAndFavoriteFoods()
    }
    
    // MARK: - Meal Operations
    
    func loadMealsForDate(_ date: Date) -> [Meal] {
        let startOfDay = date.startOfDay()
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<Meal> { meal in
            meal.date >= startOfDay && meal.date < endOfDay
        }
        
        let descriptor = FetchDescriptor<Meal>(predicate: predicate)
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error loading meals: \(error)")
            return []
        }
    }
    
    func getMealsByType(_ meals: [Meal]) -> [MealType: [Meal]] {
        var result: [MealType: [Meal]] = [:]
        
        for type in MealType.allCases {
            result[type] = meals.filter { $0.mealType == type }
        }
        
        return result
    }
    
    func getTotalNutrition(for meals: [Meal]) -> (calories: Double, carbs: Double, protein: Double, fat: Double) {
        var totalCalories: Double = 0
        var totalCarbs: Double = 0
        var totalProtein: Double = 0
        var totalFat: Double = 0
        
        meals.forEach { meal in
            totalCalories += meal.calories
            totalCarbs += meal.carbs
            totalProtein += meal.protein
            totalFat += meal.fat
        }
        
        return (totalCalories, totalCarbs, totalProtein, totalFat)
    }
    
    func startCreatingMeal(type: MealType) {
        selectedMealType = type
        mealName = type.rawValue
        isCreatingMeal = true
        selectedFoodItems = []
    }
    
    func startEditingMeal(_ meal: Meal) {
        currentMeal = meal
        selectedMealType = meal.mealType
        mealName = meal.name
        isEditingMeal = true
        
        // Load food items from the meal
        selectedFoodItems = meal.foodItems
    }
    
    func saveMeal() {
        if isEditingMeal, let existingMeal = currentMeal {
            // Update existing meal
            existingMeal.name = mealName
            existingMeal.mealType = selectedMealType
            existingMeal.date = selectedDate
            existingMeal.updatedAt = Date()
            
            // Clear and re-add food items
            existingMeal.foodItems = []
            for item in selectedFoodItems {
                item.meal = existingMeal
                item.recordUsage()
            }
            
            existingMeal.updateNutrition()
        } else {
            // Create new meal
            let newMeal = Meal(
                name: mealName,
                date: selectedDate,
                mealType: selectedMealType
            )
            
            // Add the meal to context
            modelContext.insert(newMeal)
            
            // Add food items to the meal
            for item in selectedFoodItems {
                item.meal = newMeal
                item.recordUsage()
            }
            
            newMeal.updateNutrition()
        }
        
        // Save changes
        do {
            try modelContext.save()
            resetMealForm()
            loadRecentAndFavoriteFoods()
        } catch {
            print("Error saving meal: \(error)")
        }
    }
    
    func deleteMeal(_ meal: Meal) {
        modelContext.delete(meal)
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting meal: \(error)")
        }
    }
    
    func toggleFavoriteMeal(_ meal: Meal) {
        meal.isFavorite.toggle()
        meal.updatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("Error updating meal favorite status: \(error)")
        }
    }
    
    // MARK: - Food Item Operations
    
    func searchFoods() {
        if searchQuery.isEmpty {
            searchResults = []
            return
        }
        
        // First search local database
        searchResults = FoodDatabase.shared.searchFoods(query: searchQuery)
        
        // TODO: Add API search for more foods if needed
    }
    
    func startAddingFoodItem() {
        currentFoodItem = FoodItem()
        isAddingFoodItem = true
    }
    
    func startEditingFoodItem(_ item: FoodItem) {
        currentFoodItem = item
        servingQuantity = String(item.servingQuantity)
        isAddingFoodItem = true
    }
    
    func addFoodItemToMeal(_ item: FoodItem) {
        // Create a copy of the food item
        let newItem = FoodItem(
            name: item.name,
            servingSize: item.servingSize,
            servingQuantity: Double(servingQuantity) ?? 1.0,
            calories: item.calories,
            carbs: item.carbs,
            protein: item.protein,
            fat: item.fat,
            sugar: item.sugar,
            fiber: item.fiber,
            sodium: item.sodium,
            cholesterol: item.cholesterol,
            saturatedFat: item.saturatedFat,
            transFat: item.transFat,
            isCustom: item.isCustom,
            barcode: item.barcode,
            foodDatabaseId: item.foodDatabaseId
        )
        
        selectedFoodItems.append(newItem)
        resetFoodItemForm()
    }
    
    func quickAddFoodItem() {
        guard
            let calories = Double(quickAddCalories),
            let carbs = Double(quickAddCarbs),
            let protein = Double(quickAddProtein),
            let fat = Double(quickAddFat)
        else { return }
        
        let newItem = FoodItem(
            name: "Quick Add",
            servingSize: "1 serving",
            servingQuantity: 1.0,
            calories: calories,
            carbs: carbs,
            protein: protein,
            fat: fat,
            isCustom: true
        )
        
        selectedFoodItems.append(newItem)
        resetQuickAddForm()
    }
    
    func removeFoodItem(at indices: IndexSet) {
        selectedFoodItems.remove(atOffsets: indices)
    }
    
    func saveFoodItem() {
        guard let item = currentFoodItem else { return }
        
        if let quantity = Double(servingQuantity) {
            item.servingQuantity = quantity
        }
        
        if !selectedFoodItems.contains(where: { $0.id == item.id }) {
            selectedFoodItems.append(item)
        }
        
        resetFoodItemForm()
    }
    
    func toggleFavoriteFoodItem(_ item: FoodItem) {
        item.isFavorite.toggle()
        
        do {
            try modelContext.save()
            loadRecentAndFavoriteFoods()
        } catch {
            print("Error updating food item favorite status: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadRecentAndFavoriteFoods() {
        // Load favorite foods
        let favoritePredicate = #Predicate<FoodItem> { item in
            item.isFavorite == true
        }
        
        let favoriteDescriptor = FetchDescriptor<FoodItem>(
            predicate: favoritePredicate,
            sortBy: [SortDescriptor(\.lastUsedDate, order: .reverse)]
        )
        favoriteDescriptor.fetchLimit = 10
        
        // Load recent foods
        let recentDescriptor = FetchDescriptor<FoodItem>(
            sortBy: [SortDescriptor(\.lastUsedDate, order: .reverse)]
        )
        recentDescriptor.fetchLimit = 10
        
        do {
            favoriteFoods = try modelContext.fetch(favoriteDescriptor)
            recentFoods = try modelContext.fetch(recentDescriptor)
                .filter { $0.lastUsedDate != nil }
        } catch {
            print("Error loading recent/favorite foods: \(error)")
        }
    }
    
    private func resetMealForm() {
        isCreatingMeal = false
        isEditingMeal = false
        currentMeal = nil
        selectedMealType = .breakfast
        mealName = ""
        selectedFoodItems = []
    }
    
    private func resetFoodItemForm() {
        isAddingFoodItem = false
        currentFoodItem = nil
        servingQuantity = "1.0"
    }
    
    private func resetQuickAddForm() {
        quickAddCalories = ""
        quickAddCarbs = ""
        quickAddProtein = ""
        quickAddFat = ""
    }
}
