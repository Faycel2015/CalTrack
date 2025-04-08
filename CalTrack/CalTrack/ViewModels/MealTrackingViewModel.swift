//
//  MealTrackingViewModel.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftData
import Combine

/// View model for the meal tracking screen
@MainActor
class MealTrackingViewModel: ObservableObject {
    // MARK: - Services
    
    private let mealService: MealService
    private let nutritionService: NutritionService
    private let userRepository: UserRepository
    
    // MARK: - Published Properties
    
    // UI State
    @Published var isLoading: Bool = false
    @Published var error: AppError? = nil
    
    // Data
    @Published var selectedDate: Date = Date()
    @Published var meals: [Meal] = []
    @Published var mealsByType: [MealType: [Meal]] = [:]
    @Published var userProfile: UserProfile? = nil
    @Published var nutritionSummary: NutritionSummary? = nil
    
    // View State
    @Published var isCreatingMeal: Bool = false
    @Published var isEditingMeal: Bool = false
    @Published var selectedMeal: Meal? = nil
    @Published var selectedMealType: MealType = .breakfast
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init() {
        // Get services from service locator
        self.mealService = AppServices.shared.getMealService()
        self.nutritionService = AppServices.shared.getNutritionService()
        self.userRepository = AppServices.shared.getUserRepository()
        
        // Load initial data
        loadUserProfile()
        loadMeals()
    }
    
    // MARK: - Public Methods
    
    /// Load meals for the selected date
    func loadMeals() {
        isLoading = true
        
        Task {
            do {
                // Load meals - synchronous operation
                let mealsForDate = try mealService.getMealsForDate(selectedDate)
                
                // Create the mealsByType dictionary
                var mealsByTypeDict: [MealType: [Meal]] = [:]
                for type in MealType.allCases {
                    mealsByTypeDict[type] = mealsForDate.filter { $0.mealType == type }
                }
                
                // Load nutrition summary - this is async
                let summary = try await nutritionService.getNutritionSummary(for: selectedDate)
                
                // Since we're already on the MainActor, no need for await MainActor.run
                self.meals = mealsForDate
                self.mealsByType = mealsByTypeDict
                self.nutritionSummary = summary
                self.isLoading = false
            } catch {
                // Since we're already on the MainActor, no need for await MainActor.run
                self.error = AppError.dataError("Failed to load meals: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
    }
    
    /// Change the selected date
    /// - Parameter date: New date to select
    func changeDate(to date: Date) {
        selectedDate = date
        loadMeals()
    }
    
    /// Start creating a new meal
    /// - Parameter type: Type of meal to create
    func startCreatingMeal(type: MealType) {
        selectedMealType = type
        isCreatingMeal = true
    }
    
    /// Start editing an existing meal
    /// - Parameter meal: The meal to edit
    func startEditingMeal(_ meal: Meal) {
        selectedMeal = meal
        selectedMealType = meal.mealType
        isEditingMeal = true
    }
    
    /// Delete a meal
    /// - Parameter meal: The meal to delete
    func deleteMeal(_ meal: Meal) {
        Task {
            do {
                // Service method is synchronous, no await needed
                try mealService.deleteMeal(meal)
                
                // Reload meals after deletion
                loadMeals()
            } catch {
                self.error = AppError.dataError("Failed to delete meal: \(error.localizedDescription)")
            }
        }
    }
    
    /// Toggle favorite status for a meal
    /// - Parameter meal: The meal to toggle favorite status for
    func toggleFavoriteMeal(_ meal: Meal) {
        Task {
            do {
                // Service method is synchronous, no await needed
                let isFavorite = try mealService.toggleFavoriteMeal(meal)
                
                // Update the meal in our local list
                // Since SwiftData objects are references, this may already be updated
                // But we'll keep this code for safety
                if let index = meals.firstIndex(where: { $0 === meal }) {
                    meals[index].isFavorite = isFavorite
                }
            } catch {
                self.error = AppError.dataError("Failed to update favorite status: \(error.localizedDescription)")
            }
        }
    }
    
    /// Go to previous day
    func goToPreviousDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
            changeDate(to: newDate)
        }
    }
    
    /// Go to next day
    func goToNextDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
            // Don't allow going beyond today
            if newDate <= Date() {
                changeDate(to: newDate)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Check if the selected date is today
    var isSelectedDateToday: Bool {
        return Calendar.current.isDateInToday(selectedDate)
    }
    
    /// Get total calories for the day
    var totalCalories: Double {
        return nutritionSummary?.totalCalories ?? 0
    }
    
    /// Get total carbs for the day
    var totalCarbs: Double {
        return nutritionSummary?.totalCarbs ?? 0
    }
    
    /// Get total protein for the day
    var totalProtein: Double {
        return nutritionSummary?.totalProtein ?? 0
    }
    
    /// Get total fat for the day
    var totalFat: Double {
        return nutritionSummary?.totalFat ?? 0
    }
    
    /// Get remaining calories for the day
    var remainingCalories: Double {
        return nutritionSummary?.remainingCalories ?? 0
    }
    
    /// Get calorie progress percentage
    var calorieProgress: Double {
        return nutritionSummary?.caloriePercentage ?? 0
    }
    
    /// Get carbs progress percentage
    var carbsProgress: Double {
        return nutritionSummary?.carbPercentage ?? 0
    }
    
    /// Get protein progress percentage
    var proteinProgress: Double {
        return nutritionSummary?.proteinPercentage ?? 0
    }
    
    /// Get fat progress percentage
    var fatProgress: Double {
        return nutritionSummary?.fatPercentage ?? 0
    }
    
    // MARK: - Private Methods
    
    /// Load the user profile
    private func loadUserProfile() {
        do {
            userProfile = try userRepository.getCurrentUserProfile()
        } catch {
            self.error = AppError.dataError("Failed to load user profile: \(error.localizedDescription)")
        }
    }
}
