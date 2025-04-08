//
//  DashboardViewModel.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftData
import Combine

/// View model for the dashboard screen
@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Services
    
    private let nutritionService: NutritionService
    private let mealService: MealService
    private let userRepository: UserRepository
    
    // MARK: - Published Properties
    
    // UI State
    @Published var isLoading: Bool = false
    @Published var error: AppError? = nil
    
    // Data
    @Published var selectedDate: Date = Date()
    @Published var nutritionSummary: NutritionSummary? = nil
    @Published var userProfile: UserProfile? = nil
    @Published var recentMeals: [Meal] = []
    @Published var weeklyCalorieData: [DailyCalorieData] = []
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init() {
        // Get services from service locator
        self.nutritionService = AppServices.shared.getNutritionService()
        self.mealService = AppServices.shared.getMealService()
        self.userRepository = AppServices.shared.getUserRepository()
        
        // Load initial data
        loadUserProfile()
        loadDashboardData()
    }
    
    // MARK: - Public Methods
    
    /// Load all dashboard data
    func loadDashboardData() {
        isLoading = true
        
        Task {
            do {
                // Load nutrition summary
                let summary = try await nutritionService.getNutritionSummary(for: selectedDate)
                
                // Load recent meals - since this is synchronous, no await needed
                let meals = try mealService.getRecentMeals(limit: 5)
                
                // Load weekly data
                let weeklyData = try await loadWeeklyCalorieData()
                
                // We're already in a MainActor context
                self.nutritionSummary = summary
                self.recentMeals = meals
                self.weeklyCalorieData = weeklyData
                self.isLoading = false
            } catch {
                self.error = AppError.dataError("Failed to load dashboard data: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
    }
    
    /// Change the selected date
    /// - Parameter date: New date
    func changeDate(to date: Date) {
        selectedDate = date
        loadDashboardData()
    }
    
    /// Get previous day's date
    func goToPreviousDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
            changeDate(to: newDate)
        }
    }
    
    /// Get next day's date
    func goToNextDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
            // Don't allow going beyond today
            if newDate <= Date() {
                changeDate(to: newDate)
            }
        }
    }
    
    /// Check if the selected date is today
    var isSelectedDateToday: Bool {
        return Calendar.current.isDateInToday(selectedDate)
    }
    
    /// Add a new meal
    func showAddMeal() {
        // This would typically set up a coordinator for navigation
        // or use a delegate to communicate with the view
    }
    
    // MARK: - Computed Properties
    
    /// Get remaining calories for the day
    var remainingCalories: Double {
        guard let summary = nutritionSummary, let profile = userProfile else { return 0 }
        return max(0, profile.dailyCalorieGoal - summary.totalCalories)
    }
    
    /// Get calorie progress percentage
    var calorieProgress: Double {
        guard let summary = nutritionSummary, let profile = userProfile else { return 0 }
        return min(1.0, summary.totalCalories / max(1, profile.dailyCalorieGoal))
    }
    
    /// Get remaining carbs
    var remainingCarbs: Double {
        guard let summary = nutritionSummary, let profile = userProfile else { return 0 }
        return max(0, profile.carbGoalGrams - summary.totalCarbs)
    }
    
    /// Get remaining protein
    var remainingProtein: Double {
        guard let summary = nutritionSummary, let profile = userProfile else { return 0 }
        return max(0, profile.proteinGoalGrams - summary.totalProtein)
    }
    
    /// Get remaining fat
    var remainingFat: Double {
        guard let summary = nutritionSummary, let profile = userProfile else { return 0 }
        return max(0, profile.fatGoalGrams - summary.totalFat)
    }
    
    /// Get macro distribution
    var macroDistribution: (carbs: Double, protein: Double, fat: Double) {
        guard let summary = nutritionSummary else { return (0.4, 0.3, 0.3) }
        return (
            summary.carbDistribution,
            summary.proteinDistribution,
            summary.fatDistribution
        )
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
    
    /// Load weekly calorie data
    private func loadWeeklyCalorieData() async throws -> [DailyCalorieData] {
        var result: [DailyCalorieData] = []
        
        // Get data for the last 7 days
        for dayOffset in 0...6 {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
            
            if date <= Date() {
                let summary = try await nutritionService.getNutritionSummary(for: date)
                
                result.append(
                    DailyCalorieData(
                        date: date,
                        calories: summary.totalCalories,
                        goal: summary.goalCalories
                    )
                )
            }
        }
        
        // Sort by date
        return result.sorted { $0.date < $1.date }
    }
}

// MARK: - Supporting Data Models

/// Daily calorie data for charts
struct DailyCalorieData: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let calories: Double
    let goal: Double
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    var percentage: Double {
        return min(1.0, calories / max(1, goal))
    }
}
