//
//  FoodDetailViewModel.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftData
import Combine

/// View model for food item detail screen
@MainActor // Add MainActor to the entire class
class FoodDetailViewModel: ObservableObject {
    // MARK: - Services
    
    private let foodRepository: FoodRepository
    
    // MARK: - Published Properties
    
    // UI State
    @Published var isLoading: Bool = false
    @Published var error: AppError? = nil
    
    // Food item
    private var originalFoodItem: FoodItem
    @Published var foodItem: FoodItem
    
    // Serving
    @Published var servingQuantity: Double
    @Published var editableServingSize: String
    
    // Nutritional values
    @Published var isFavorite: Bool
    
    // Additional input for editable items
    @Published var editableCalories: String
    @Published var editableCarbs: String
    @Published var editableProtein: String
    @Published var editableFat: String
    @Published var editableSugar: String
    @Published var editableFiber: String
    @Published var editableSodium: String
    @Published var editableCholesterol: String
    
    // Edit state
    @Published var isEditing: Bool = false
    
    // Completion handlers
    var onSave: ((FoodItem) -> Void)?
    var onCancel: (() -> Void)?
    
    // MARK: - Computed Properties
    
    var isCustomFoodItem: Bool {
        return foodItem.isCustom
    }
    
    var hasSourceInformation: Bool {
        return foodItem.barcode != nil || foodItem.foodDatabaseId != nil
    }
    
    var hasChanges: Bool {
        if !isCustomFoodItem {
            // For non-custom items, only check serving quantity
            return servingQuantity != originalFoodItem.servingQuantity
        }
        
        // For custom items, check all editable fields
        return servingQuantity != originalFoodItem.servingQuantity ||
               editableServingSize != originalFoodItem.servingSize ||
               Double(editableCalories) != originalFoodItem.calories ||
               Double(editableCarbs) != originalFoodItem.carbs ||
               Double(editableProtein) != originalFoodItem.protein ||
               Double(editableFat) != originalFoodItem.fat
    }
    
    var isValid: Bool {
        // Basic validation
        return !editableServingSize.isEmpty &&
               Double(editableCalories) != nil &&
               Double(editableCarbs) != nil &&
               Double(editableProtein) != nil &&
               Double(editableFat) != nil
    }
    
    // Calculated nutrition based on serving quantity
    var totalCalories: Double {
        return foodItem.calories * servingQuantity
    }
    
    var totalCarbs: Double {
        return foodItem.carbs * servingQuantity
    }
    
    var totalProtein: Double {
        return foodItem.protein * servingQuantity
    }
    
    var totalFat: Double {
        return foodItem.fat * servingQuantity
    }
    
    var totalSugar: Double? {
        if let sugar = foodItem.sugar {
            return sugar * servingQuantity
        }
        return nil
    }
    
    var totalFiber: Double? {
        if let fiber = foodItem.fiber {
            return fiber * servingQuantity
        }
        return nil
    }
    
    var totalSodium: Double? {
        if let sodium = foodItem.sodium {
            return sodium * servingQuantity
        }
        return nil
    }
    
    var totalCholesterol: Double? {
        if let cholesterol = foodItem.cholesterol {
            return cholesterol * servingQuantity
        }
        return nil
    }
    
    // MARK: - Initializer
    
    init(foodItem: FoodItem, foodRepository: FoodRepository? = nil) {
        // Get services from service locator or use the provided one
        if let foodRepository = foodRepository {
            self.foodRepository = foodRepository
        } else {
            self.foodRepository = AppServices.shared.getFoodRepository()
        }
        
        // Store original food item for comparison
        self.originalFoodItem = foodItem
        
        // Create a copy for editing
        self.foodItem = FoodItem(
            name: foodItem.name,
            servingSize: foodItem.servingSize,
            servingQuantity: foodItem.servingQuantity,
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
        
        // Initialize state properties
        self.servingQuantity = foodItem.servingQuantity
        self.editableServingSize = foodItem.servingSize
        self.isFavorite = foodItem.isFavorite
        
        // Initialize editable nutritional values
        self.editableCalories = String(format: "%.1f", foodItem.calories)
        self.editableCarbs = String(format: "%.1f", foodItem.carbs)
        self.editableProtein = String(format: "%.1f", foodItem.protein)
        self.editableFat = String(format: "%.1f", foodItem.fat)
        
        if let sugar = foodItem.sugar {
            self.editableSugar = String(format: "%.1f", sugar)
        } else {
            self.editableSugar = ""
        }
        
        if let fiber = foodItem.fiber {
            self.editableFiber = String(format: "%.1f", fiber)
        } else {
            self.editableFiber = ""
        }
        
        if let sodium = foodItem.sodium {
            self.editableSodium = String(format: "%.1f", sodium)
        } else {
            self.editableSodium = ""
        }
        
        if let cholesterol = foodItem.cholesterol {
            self.editableCholesterol = String(format: "%.1f", cholesterol)
        } else {
            self.editableCholesterol = ""
        }
    }
    
    // MARK: - Public Methods
    
    /// Update serving quantity
    /// - Parameter quantity: New serving quantity
    func updateServingQuantity(_ quantity: Double) {
        servingQuantity = max(0.1, quantity)
    }
    
    /// Increment serving quantity
    func incrementServingQuantity() {
        servingQuantity += 0.25
    }
    
    /// Decrement serving quantity
    func decrementServingQuantity() {
        if servingQuantity > 0.25 {
            servingQuantity -= 0.25
        }
    }
    
    /// Toggle edit mode
    func toggleEditMode() {
        isEditing.toggle()
    }
    
    /// Toggle favorite status
    func toggleFavorite() {
        isFavorite.toggle()
    }
    
    /// Save changes to the food item
    func saveChanges() {
        isLoading = true
        
        // Update basic info
        foodItem.servingQuantity = servingQuantity
        
        // For custom items, update all fields
        if isCustomFoodItem && isEditing {
            foodItem.servingSize = editableServingSize
            
            if let calories = Double(editableCalories) {
                foodItem.calories = calories
            }
            
            if let carbs = Double(editableCarbs) {
                foodItem.carbs = carbs
            }
            
            if let protein = Double(editableProtein) {
                foodItem.protein = protein
            }
            
            if let fat = Double(editableFat) {
                foodItem.fat = fat
            }
            
            // Optional fields
            foodItem.sugar = Double(editableSugar)
            foodItem.fiber = Double(editableFiber)
            foodItem.sodium = Double(editableSodium)
            foodItem.cholesterol = Double(editableCholesterol)
        }
        
        // Update favorite status if changed
        if foodItem.isFavorite != isFavorite {
            updateFavoriteStatus()
        }
        
        // For custom items, save changes to database
        if isCustomFoodItem && isEditing {
            saveFoodItem()
        } else {
            // For non-custom items, just notify completion
            isLoading = false
            onSave?(foodItem)
        }
    }
    
    /// Cancel changes and revert to original state
    func cancelChanges() {
        onCancel?()
    }
    
    /// Create a new food entry based on the current food item
    func createNewFoodEntry() {
        // Create a copy with custom flag
        let newItem = FoodItem(
            name: foodItem.name,
            servingSize: foodItem.servingSize,
            servingQuantity: servingQuantity,
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
            isCustom: true // Mark as custom
        )
        
        onSave?(newItem)
    }
    
    // MARK: - Private Methods
    
    /// Save food item to database
    private func saveFoodItem() {
        Task {
            do {
                try foodRepository.updateFoodItem(foodItem)
                
                // No need for MainActor.run since the class is already @MainActor
                isLoading = false
                onSave?(foodItem)
            } catch {
                // No need for MainActor.run since the class is already @MainActor
                self.error = AppError.dataError("Failed to save food item: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
    }

    /// Update favorite status in repository
    private func updateFavoriteStatus() {
        Task {
            do {
                let newStatus = try foodRepository.toggleFavorite(for: foodItem)
                
                // No need for MainActor.run since the class is already @MainActor
                self.foodItem.isFavorite = newStatus
                self.isFavorite = newStatus
            } catch {
                // No need for MainActor.run since the class is already @MainActor
                self.error = AppError.dataError("Failed to update favorite status: \(error.localizedDescription)")
            }
        }
    }
    
    /// Format serving quantity for display
    func formattedServingQuantity() -> String {
        let isWholeNumber = servingQuantity.truncatingRemainder(dividingBy: 1) == 0
        return isWholeNumber ? String(format: "%.0f", servingQuantity) : String(format: "%.2f", servingQuantity)
    }
    
    /// Get commonly used serving quantities
    func commonServingQuantities() -> [Double] {
        return [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0]
    }
    
    /// Get calories per macro
    func caloriesPerMacro() -> (carbs: Double, protein: Double, fat: Double) {
        let carbCalories = totalCarbs * 4  // 4 calories per gram
        let proteinCalories = totalProtein * 4  // 4 calories per gram
        let fatCalories = totalFat * 9  // 9 calories per gram
        
        return (carbCalories, proteinCalories, fatCalories)
    }
    
    /// Get macro distribution as percentages
    func macroDistribution() -> (carbs: Double, protein: Double, fat: Double) {
        let caloriesFrom = caloriesPerMacro()
        let totalFromMacros = caloriesFrom.carbs + caloriesFrom.protein + caloriesFrom.fat
        
        if totalFromMacros <= 0 {
            return (0.4, 0.3, 0.3) // Default distribution if no data
        }
        
        let carbPercentage = caloriesFrom.carbs / totalFromMacros
        let proteinPercentage = caloriesFrom.protein / totalFromMacros
        let fatPercentage = caloriesFrom.fat / totalFromMacros
        
        return (carbPercentage, proteinPercentage, fatPercentage)
    }
}
