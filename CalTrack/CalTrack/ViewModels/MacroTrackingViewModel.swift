//
//  MacroTrackingViewModel.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData
import Combine

/// View model for the macro tracking screen
@MainActor // Add MainActor to the entire class
class MacroTrackingViewModel: ObservableObject {
    // MARK: - Services
    
    private let nutritionService: NutritionService
    private let userRepository: UserRepository
    
    // MARK: - Published Properties
    
    // UI State
    @Published var isLoading: Bool = false
    @Published var error: AppError? = nil
    
    // Data
    @Published var selectedDate: Date = Date()
    @Published var userProfile: UserProfile? = nil
    @Published var nutritionSummary: NutritionSummary? = nil
    @Published var weeklyNutritionSummary: WeeklyNutritionSummary? = nil
    
    // Detail sheet
    @Published var activeDetailSheet: MacroType?
    
    // Mock data for meals (would be replaced with actual meal data)
    @Published var mockMeals: [MockMeal] = []
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(nutritionService: NutritionService? = nil, userRepository: UserRepository? = nil) {
        // Get services from service locator or use the provided ones
        if let nutritionService = nutritionService {
            self.nutritionService = nutritionService
        } else {
            self.nutritionService = AppServices.shared.getNutritionService()
        }
        
        if let userRepository = userRepository {
            self.userRepository = userRepository
        } else {
            self.userRepository = AppServices.shared.getUserRepository()
        }
        
        // Load initial data
        loadUserProfile()
        loadMacroData()
        setupMockData()
    }
    
    // MARK: - Public Methods
    
    /// Load all macro tracking data
    func loadMacroData() {
        isLoading = true
        
        Task {
            do {
                // Load nutrition summary
                let summary = try await nutritionService.getNutritionSummary(for: selectedDate)
                
                // Load weekly summary
                let weeklySummary = try await nutritionService.getWeeklyNutritionSummary(endDate: selectedDate)
                
                // No need for MainActor.run since the class is already @MainActor
                self.nutritionSummary = summary
                self.weeklyNutritionSummary = weeklySummary
                self.isLoading = false
            } catch {
                // No need for MainActor.run since the class is already @MainActor
                self.error = AppError.dataError("Failed to load nutrition data: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
    }
    
    /// Change the selected date
    /// - Parameter date: New date
    func changeDate(to date: Date) {
        selectedDate = date
        loadMacroData()
    }
    
    /// Show macro detail sheet
    /// - Parameter macroType: The macro type to show details for
    func showMacroDetail(_ macroType: MacroType) {
        activeDetailSheet = macroType
    }
    
    /// Close macro detail sheet
    func closeMacroDetail() {
        activeDetailSheet = nil
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
    
    // MARK: - Helper Methods
    
    /// Get value for a macro type
    /// - Parameter macroType: The macro type
    /// - Returns: Current value for the macro
    func getMacroValue(_ macroType: MacroType) -> Double {
        guard let summary = nutritionSummary else { return 0 }
        
        switch macroType {
        case .calories: return summary.totalCalories
        case .carbs: return summary.totalCarbs
        case .protein: return summary.totalProtein
        case .fat: return summary.totalFat
        }
    }
    
    /// Get goal for a macro type
    /// - Parameter macroType: The macro type
    /// - Returns: Goal value for the macro
    func getMacroGoal(_ macroType: MacroType) -> Double {
        guard let profile = userProfile else {
            // Default values if no profile exists
            switch macroType {
            case .calories: return 2000
            case .carbs: return 250
            case .protein: return 120
            case .fat: return 65
            }
        }
        
        switch macroType {
        case .calories: return profile.dailyCalorieGoal
        case .carbs: return profile.carbGoalGrams
        case .protein: return profile.proteinGoalGrams
        case .fat: return profile.fatGoalGrams
        }
    }
    
    /// Get progress percentage for a macro type
    /// - Parameter macroType: The macro type
    /// - Returns: Progress as a percentage (0-1)
    func getMacroProgress(_ macroType: MacroType) -> Double {
        let value = getMacroValue(macroType)
        let goal = getMacroGoal(macroType)
        return min(1.0, value / max(1, goal))
    }
    
    /// Get maximum value from an array of values
    /// - Parameter values: Array of values
    /// - Returns: Maximum value or 1.0 if array is empty
    func getMaxValue(_ values: [Double]) -> Double {
        values.max() ?? 1.0
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
    
    /// Setup mock meal data
    private func setupMockData() {
        // This would be replaced with actual meal data from the repository
        mockMeals = [
            MockMeal(name: "Breakfast", type: .breakfast, calories: 450, carbs: 65, protein: 20, fat: 12),
            MockMeal(name: "Morning Snack", type: .snack, calories: 180, carbs: 15, protein: 12, fat: 8),
            MockMeal(name: "Lunch", type: .lunch, calories: 650, carbs: 80, protein: 35, fat: 20),
            MockMeal(name: "Afternoon Snack", type: .snack, calories: 150, carbs: 12, protein: 8, fat: 7),
            MockMeal(name: "Dinner", type: .dinner, calories: 720, carbs: 85, protein: 40, fat: 25)
        ]
    }
    
    /// Create sample data for weekly charts
    /// - Returns: Array of values
    func createSampleData() -> [Double] {
        // If we have weekly data, use that
        if let weeklySummary = weeklyNutritionSummary, let macroType = activeDetailSheet {
            var result: [Double] = []
            
            // Get the daily summaries ordered by date
            let sortedDays = weeklySummary.dailySummaries.sorted { $0.key < $1.key }
            
            for (_, summary) in sortedDays {
                switch macroType {
                case .calories: result.append(summary.totalCalories)
                case .carbs: result.append(summary.totalCarbs)
                case .protein: result.append(summary.totalProtein)
                case .fat: result.append(summary.totalFat)
                }
            }
            
            return result
        }
        
        // Otherwise create random data
        // Create randomized weekly data with the final day matching the current value
        var result: [Double] = []
        
        guard let macroType = activeDetailSheet else { return [] }
        
        let baseValue = getMacroGoal(macroType) * 0.9 // Base around 90% of goal
        
        for _ in 0..<6 {
            let randomVariation = Double.random(in: -0.2...0.3)
            let dayValue = max(0, baseValue * (1 + randomVariation))
            result.append(dayValue)
        }
        
        // Add today's actual value
        result.append(getMacroValue(macroType))
        
        return result
    }
}

// MARK: - Supporting Types

/// Macro nutrient types
enum MacroType: String, CaseIterable, Identifiable {
    case calories = "Calories"
    case carbs = "Carbs"
    case protein = "Protein"
    case fat = "Fat"
    
    var id: String { self.rawValue }
    
    /// Color for this macro type from AppColors
    var color: Color {
        switch self {
        case .calories: return AppColors.caloriesColor
        case .carbs: return AppColors.carbsColor
        case .protein: return AppColors.proteinColor
        case .fat: return AppColors.fatColor
        }
    }
    
    /// Unit for displaying this macro's value
    var unit: String {
        return self == .calories ? "cal" : "g"
    }
    
    /// System icon to represent this macro
    var systemIcon: String {
        switch self {
        case .calories: return "flame.fill"
        case .carbs: return "c.circle.fill"
        case .protein: return "p.circle.fill"
        case .fat: return "f.circle.fill"
        }
    }
    
    /// Educational description of this macro
    var description: String {
        switch self {
        case .calories:
            return "Calories are units of energy in food that your body uses for various functions. Managing calorie intake helps control weight."
        case .carbs:
            return "Carbohydrates are your body's main energy source. They break down into glucose, fueling your brain, muscles, and organs."
        case .protein:
            return "Protein is essential for building and repairing tissues, including muscles. It also supports immune function and hormone production."
        case .fat:
            return "Dietary fats are vital for hormone production, nutrient absorption, and cell membrane health. They also provide energy and insulation."
        }
    }
    
    /// Calories per gram for this macro
    var caloriesPerGram: Double {
        switch self {
        case .calories: return 1.0  // N/A for calories
        case .carbs: return 4.0
        case .protein: return 4.0
        case .fat: return 9.0
        }
    }
    
    /// Recommended daily intake range as percentage of total calories
    var recommendedRange: ClosedRange<Double> {
        switch self {
        case .calories: return 0.0...1.0  // N/A for calories
        case .carbs: return 0.45...0.65   // 45-65% of calories from carbs
        case .protein: return 0.10...0.35 // 10-35% of calories from protein
        case .fat: return 0.20...0.35     // 20-35% of calories from fat
        }
    }
}

/// Mock meal for UI development
struct MockMeal: Identifiable {
    let id = UUID()
    let name: String
    let type: MealType
    let calories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
}
