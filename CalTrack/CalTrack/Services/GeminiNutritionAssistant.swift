//
//  GeminiNutritionAssistant.swift
//  CalTrack
//
//  Created by FayTek on 4/8/25.
//

import Foundation
import SwiftUI

/// Service for accessing and managing user profile data
class UserProfileService {
    private let userRepository: UserRepository
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    /// Get the current user profile
    func getCurrentUserProfile() throws -> UserProfile? {
        return try userRepository.getCurrentUserProfile()
    }
    
    /// Update user profile
    func updateUserProfile(_ profile: UserProfile) throws {
        try userRepository.saveUserProfile(profile)
    }
}

/// Advanced AI-powered nutrition analysis and recommendation service
@Observable
class GeminiNutritionAssistant {
    // MARK: - Dependencies
    private let geminiService: GeminiService
    private let nutritionService: NutritionService
    private let userProfileService: UserProfileService
    
    // MARK: - Caching and State
    private var recommendationCache: [String: NutritionRecommendation] = [:]
    private(set) var lastAnalysisResult: NutritionAnalysisResult?
    
    // MARK: - Initializer
    init(
        geminiService: GeminiService,
        nutritionService: NutritionService,
        userProfileService: UserProfileService
    ) {
        self.geminiService = geminiService
        self.nutritionService = nutritionService
        self.userProfileService = userProfileService
    }
    
    // MARK: - Advanced Nutrition Analysis Methods
    
    /// Comprehensive nutrition profile analysis
    func analyzeNutritionProfile() async throws -> NutritionAnalysisResult {
        // Retrieve user profile and recent nutrition data
        guard let profile = try userProfileService.getCurrentUserProfile() else {
            throw NutritionAssistantError.userProfileNotFound
        }
        
        let weeklyNutrition = try await nutritionService.getWeeklyNutritionSummary()
        
        // Prepare detailed prompt for AI analysis
        let prompt = """
        Perform a comprehensive nutrition profile analysis based on the following data:
        
        User Profile:
        - Age: \(profile.age)
        - Gender: \(profile.gender)
        - Height: \(profile.height) cm
        - Current Weight: \(profile.weight) kg
        - Activity Level: \(profile.activityLevel)
        - Weight Goal: \(profile.weightGoal)
        
        Weekly Nutrition Summary:
        - Average Daily Calories: \(weeklyNutrition.avgCalories)
        - Average Daily Carbs: \(weeklyNutrition.avgCarbs)g
        - Average Daily Protein: \(weeklyNutrition.avgProtein)g
        - Average Daily Fat: \(weeklyNutrition.avgFat)g
        
        Nutritional Goals:
        - Daily Calorie Goal: \(profile.dailyCalorieGoal)
        - Carb Goal: \(profile.carbGoalGrams)g
        - Protein Goal: \(profile.proteinGoalGrams)g
        - Fat Goal: \(profile.fatGoalGrams)g
        
        Provide a detailed analysis including:
        1. Nutritional profile assessment
        2. Alignment with health goals
        3. Potential nutritional gaps
        4. Personalized recommendations for optimization
        5. Scientific insights into current nutrition patterns
        """
        
        // Send to Gemini for analysis
        let analysisText = try await geminiService.sendPromptToGemini(prompt)
        
        // Create analysis result
        let analysisResult = NutritionAnalysisResult(
            rawAnalysis: analysisText,
            weeklyNutrition: weeklyNutrition,
            userProfile: profile
        )
        
        // Cache and store result
        lastAnalysisResult = analysisResult
        return analysisResult
    }
    
    /// Generate personalized nutrition recommendations
    func generateNutritionRecommendations() async throws -> NutritionRecommendation {
        // Check cache first
        let cacheKey = "nutrition_recommendation_\(Date().timeIntervalSince1970 / (24 * 3600))"
        if let cachedRecommendation = recommendationCache[cacheKey] {
            return cachedRecommendation
        }
        
        // Get latest nutrition analysis or perform one
        let analysisResult = try await analyzeNutritionProfile()
        
        // Prepare recommendation prompt
        let prompt = """
        Based on the previous nutrition profile analysis, provide:
        
        Detailed Nutrition Recommendations:
        1. Macronutrient optimization strategies
        2. Specific food recommendations
        3. Supplement suggestions (if applicable)
        4. Lifestyle and dietary adjustment tips
        5. Potential health risk mitigation
        
        Considerations:
        - Current nutritional profile
        - Weight management goals
        - Activity level
        - Individual health markers
        
        Provide actionable, scientifically-backed recommendations.
        """
        
        // Get AI-generated recommendations
        let recommendationText = try await geminiService.sendPromptToGemini(prompt)
        
        // Create recommendation object
        let recommendation = NutritionRecommendation(
            rawRecommendation: recommendationText,
            analysisResult: analysisResult
        )
        
        // Cache recommendation
        recommendationCache[cacheKey] = recommendation
        
        return recommendation
    }
    
    /// Advanced meal optimization suggestions
    func optimizeMealNutrition(meal: Meal) async throws -> MealOptimizationSuggestion {
        // Prepare detailed meal analysis prompt
        let prompt = """
        Analyze and provide optimization suggestions for this meal:
        
        Meal Details:
        - Name: \(meal.name)
        - Type: \(meal.mealType.rawValue)
        
        Current Nutritional Breakdown:
        - Calories: \(meal.calories)
        - Carbohydrates: \(meal.carbs)g
        - Protein: \(meal.protein)g
        - Fat: \(meal.fat)g
        
        Provide:
        1. Nutritional balance assessment
        2. Specific ingredient substitution recommendations
        3. Macronutrient optimization strategies
        4. Potential nutritional enhancements
        5. Health impact analysis
        """
        
        // Send to Gemini for analysis
        let optimizationText = try await geminiService.sendPromptToGemini(prompt)
        
        // Create optimization suggestion
        return MealOptimizationSuggestion(
            originalMeal: meal,
            rawOptimizationSuggestions: optimizationText
        )
    }
    
    /// Nutrition education content generation
    func generateNutritionEducationContent(topic: NutritionTopic) async throws -> NutritionEducationContent {
        // Prepare educational content prompt
        let prompt = """
        Generate comprehensive, scientifically accurate educational content about:
        
        Topic: \(topic.rawValue)
        
        Content Requirements:
        1. Evidence-based information
        2. Clear, accessible language
        3. Practical applications
        4. Potential health implications
        5. Latest scientific research insights
        
        Target Audience: Health-conscious individuals
        """
        
        // Generate content via Gemini
        let educationText = try await geminiService.sendPromptToGemini(prompt)
        
        // Create education content object
        return NutritionEducationContent(
            topic: topic,
            content: educationText
        )
    }
}

// MARK: - Supporting Structures

/// Nutrition Analysis Result
struct NutritionAnalysisResult {
    let rawAnalysis: String
    let weeklyNutrition: WeeklyNutritionSummary
    let userProfile: UserProfile
    
    // Computed properties for easy access
    var analysisHighlights: [String] {
        // Parse raw analysis into key highlights
        return rawAnalysis.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .prefix(5)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}

/// Personalized Nutrition Recommendations
struct NutritionRecommendation {
    let rawRecommendation: String
    let analysisResult: NutritionAnalysisResult
    
    // Computed properties for easy access
    var recommendationPoints: [String] {
        return rawRecommendation.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .prefix(10)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}

/// Meal Optimization Suggestion
struct MealOptimizationSuggestion {
    let originalMeal: Meal
    let rawOptimizationSuggestions: String
    
    var optimizationPoints: [String] {
        return rawOptimizationSuggestions.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .prefix(5)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}

/// Nutrition Education Content
struct NutritionEducationContent {
    let topic: NutritionTopic
    let content: String
}

/// Nutrition Topics for Education
enum NutritionTopic: String, CaseIterable {
    case macronutrients = "Macronutrients and Their Role in Nutrition"
    case micronutrients = "Essential Micronutrients and Health"
    case weightManagement = "Sustainable Weight Management Strategies"
    case athleteNutrition = "Nutrition for Athletic Performance"
    case metabolicHealth = "Metabolic Health and Nutrition"
    case preventiveDiet = "Diet and Disease Prevention"
    case hormonalBalance = "Nutrition's Impact on Hormonal Balance"
    case digestiveHealth = "Gut Health and Nutrition"
}

/// Errors specific to Nutrition Assistant
enum NutritionAssistantError: Error {
    case userProfileNotFound
    case analysisGenerationFailed
    case recommendationGenerationFailed
    
    var localizedDescription: String {
        switch self {
        case .userProfileNotFound:
            return "Unable to retrieve user profile. Please complete your profile."
        case .analysisGenerationFailed:
            return "Failed to generate nutrition analysis. Please try again."
        case .recommendationGenerationFailed:
            return "Unable to generate nutrition recommendations. Please try again."
        }
    }
}
