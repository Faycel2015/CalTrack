//
//  AddMealViewModel.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftData
import Combine

/// View model for adding or editing meals
class AddMealViewModel: ObservableObject {
    // MARK: - Services
    
    private let mealService: MealService
    private let foodRepository: FoodRepository
    
    // MARK: - Published Properties
    
    // UI State
    @Published var isLoading: Bool = false
    @Published var error: AppError? = nil
    @Published var selectedTab: Int = 0
    @Published var showScanner: Bool = false
    
    // Meal data
    @Published var mealName: String = ""
    @Published var selectedDate: Date = Date()
    @Published var selectedMealType: MealType = .breakfast
    @Published var selectedFoodItems: [FoodItem] = []
    @Published var isFavoriteMeal: Bool = false
    
    // Food search
    @Published var searchQuery: String = ""
    @Published var searchResults: [FoodItem] = []
    
    // Quick add
    @Published var quickAddCalories: String = ""
    @Published var quickAddCarbs: String = ""
    @Published var quickAddProtein: String = ""
    @Published var quickAddFat: String = ""
    
    // Recent and favorite foods
    @Published var recentFoods: [FoodItem] = []
    @Published var favoriteFoods: [FoodItem] = []
    
    // Food item details
    @Published var isAddingFoodItem: Bool = false
    @Published var currentFoodItem: FoodItem?
    @Published var servingQuantity: String = "1.0"
    
    // Editing state
    private var isEditing: Bool = false
    private var existingMeal: Meal?
    
    // Completion handler
    var onComplete: ((Meal) -> Void)?
    
    // MARK: - Computed Properties
    
    var canSaveMeal: Bool {
        return !mealName.isEmpty && !selectedFoodItems.isEmpty
    }
    
    var totalNutrition: (calories: Double, carbs: Double, protein: Double, fat: Double) {
        let calories = selectedFoodItems.reduce(0) { $0 + $1.totalCalories }
        let carbs = selectedFoodItems.reduce(0) { $0 + $1.totalCarbs }
        let protein = selectedFoodItems.reduce(0) { $0 + $1.totalProtein }
        let fat = selectedFoodItems.reduce(0) { $0 + $1.totalFat }
        
        return (calories, carbs, protein, fat)
    }
    
    var isQuickAddValid: Bool {
        guard let calories = Double(quickAddCalories),
              let carbs = Double(quickAddCarbs),
              let protein = Double(quickAddProtein),
              let fat = Double(quickAddFat)
        else { return false }
        
        return calories > 0 || carbs > 0 || protein > 0 || fat > 0
    }
    
    // MARK: - Initializer
    
    init(existingMeal: Meal? = nil) {
        // Get services from service locator
        self.mealService = AppServices.shared.getMealService()
        self.foodRepository = AppServices.shared.getFoodRepository()
        
        // Setup editing state if editing an existing meal
        self.isEditing = existingMeal != nil
        self.existingMeal = existingMeal
        
        // If editing, populate data from existing meal
        if let meal = existingMeal {
            self.mealName = meal.name
            self.selectedDate = meal.date
            self.selectedMealType = meal.mealType
            self.selectedFoodItems = meal.foodItems
            self.isFavoriteMeal = meal.isFavorite
        } else {
            // For new meals, suggest meal type based on time of day
            self.selectedMealType = MealType.suggestedTypeForCurrentTime()
            self.mealName = selectedMealType.rawValue
        }
        
        // Load recent and favorite foods
        loadRecentAndFavoriteFoods()
    }
    
    // MARK: - Public Methods
    
    /// Save the meal
    func saveMeal() {
        isLoading = true
        
        do {
            let meal: Meal
            
            if isEditing, let existingMeal = existingMeal {
                // Update existing meal
                _ = try mealService.updateMeal(
                    meal: existingMeal,
                    name: mealName,
                    date: selectedDate,
                    mealType: selectedMealType,
                    foodItems: selectedFoodItems
                )
                
                // Toggle favorite status if needed
                if existingMeal.isFavorite != isFavoriteMeal {
                    _ = try mealService.toggleFavoriteMeal(existingMeal)
                }
                
                meal = existingMeal
            } else {
                // Create new meal
                meal = try mealService.createMeal(
                    name: mealName,
                    date: selectedDate,
                    mealType: selectedMealType,
                    foodItems: selectedFoodItems
                )
                
                // Set favorite status if needed
                if isFavoriteMeal {
                    _ = try mealService.toggleFavoriteMeal(meal)
                }
            }
            
            // Notify completion handler
            onComplete?(meal)
        } catch {
            self.error = AppError.dataError("Failed to save meal: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Search for food items
    func searchFoods() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        // Perform search
        Task {
            do {
                let results = try foodRepository.searchFoodItems(searchQuery)
                
                await MainActor.run {
                    self.searchResults = results
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = AppError.dataError("Failed to search foods: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Start adding a new food item
    func startAddingFoodItem() {
        currentFoodItem = FoodItem()
        servingQuantity = "1.0"
        isAddingFoodItem = true
    }
    
    /// Start editing an existing food item
    /// - Parameter item: The food item to edit
    func startEditingFoodItem(_ item: FoodItem) {
        currentFoodItem = item
        servingQuantity = String(item.servingQuantity)
        isAddingFoodItem = true
    }
    
    /// Add a food item to the meal
    /// - Parameter item: The food item to add
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
        
        // Add to selected items
        selectedFoodItems.append(newItem)
        
        // Reset form
        resetFoodItemForm()
    }
    
    /// Add a quick food item
    func quickAddFoodItem() {
        guard let calories = Double(quickAddCalories),
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
        
        // Add to selected items
        selectedFoodItems.append(newItem)
        
        // Reset quick add form
        resetQuickAddForm()
    }
    
    /// Save food item changes
    func saveFoodItemChanges() {
        guard let item = currentFoodItem else { return }
        
        if let quantity = Double(servingQuantity) {
            item.servingQuantity = quantity
        }
        
        // If not already in selected items, add it
        if !selectedFoodItems.contains(where: { $0.id == item.id }) {
            selectedFoodItems.append(item)
        } else {
            // Already in list, just update the reference
            if let index = selectedFoodItems.firstIndex(where: { $0.id == item.id }) {
                selectedFoodItems[index] = item
            }
        }
        
        resetFoodItemForm()
    }
    
    /// Remove food items
    /// - Parameter indices: Indices of items to remove
    func removeFoodItems(at indices: IndexSet) {
        selectedFoodItems.remove(atOffsets: indices)
    }
    
    /// Toggle favorite status for a food item
    /// - Parameter item: The food item
    func toggleFavoriteFoodItem(_ item: FoodItem) {
        Task {
            do {
                let isFavorite = try foodRepository.toggleFavorite(for: item)
                
                // If the item is in our selected items, update it there too
                if let index = selectedFoodItems.firstIndex(where: { $0.id == item.id }) {
                    selectedFoodItems[index].isFavorite = isFavorite
                }
                
                // Reload favorites
                loadRecentAndFavoriteFoods()
            } catch {
                self.error = AppError.dataError("Failed to update favorite status: \(error.localizedDescription)")
            }
        }
    }
    
    /// Update meal type
    /// - Parameter type: The new meal type
    func updateMealType(_ type: MealType) {
        selectedMealType = type
        
        // If meal name matches the previous meal type, update it
        if mealName == selectedMealType.rawValue && !isEditing {
            mealName = type.rawValue
        }
    }
    
    /// Process barcode scan result
    /// - Parameter barcode: The scanned barcode
    func processBarcodeScan(_ barcode: String) {
        isLoading = true
        
        Task {
            do {
                // Get barcode service directly (without optional chaining)
                let barcodeService = AppServices.shared.getBarcodeService()
                
                let foodItem = try await barcodeService.lookupProductByBarcode(barcode)
                
                await MainActor.run {
                    self.currentFoodItem = foodItem
                    self.servingQuantity = "1.0"
                    self.isAddingFoodItem = true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = AppError.dataError("Failed to lookup product: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Load recent and favorite foods
    private func loadRecentAndFavoriteFoods() {
        Task {
            do {
                // Load recent foods
                let recent = try foodRepository.getRecentFoodItems(limit: 10)
                
                // Load favorite foods
                let favorites = try foodRepository.getFavoriteFoodItems()
                
                await MainActor.run {
                    self.recentFoods = recent
                    self.favoriteFoods = favorites
                }
            } catch {
                await MainActor.run {
                    self.error = AppError.dataError("Failed to load recent/favorite foods: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Reset food item form
    private func resetFoodItemForm() {
        isAddingFoodItem = false
        currentFoodItem = nil
        servingQuantity = "1.0"
    }
    
    /// Reset quick add form
    private func resetQuickAddForm() {
        quickAddCalories = ""
        quickAddCarbs = ""
        quickAddProtein = ""
        quickAddFat = ""
    }
}

// Extension for tabs in the Add Meal view
extension AddMealViewModel {
    // MARK: - Tab Definitions
    
    enum MealCreationTab: Int, CaseIterable {
        case search = 0
        case recent = 1
        case favorites = 2
        case quickAdd = 3
        
        var title: String {
            switch self {
            case .search: return "Search"
            case .recent: return "Recent"
            case .favorites: return "Favorites"
            case .quickAdd: return "Quick Add"
            }
        }
        
        var icon: String {
            switch self {
            case .search: return "magnifyingglass"
            case .recent: return "clock"
            case .favorites: return "star"
            case .quickAdd: return "plus.circle"
            }
        }
    }
}
