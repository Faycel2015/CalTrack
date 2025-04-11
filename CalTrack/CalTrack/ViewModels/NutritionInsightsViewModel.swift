//
//  NutritionInsightsViewModel.swift
//  CalTrack
//
//  Created by FayTek on 4/8/25.
//

import Foundation
import SwiftUI

/// View Model for Nutrition Insights powered by Gemini AI
@Observable
@MainActor // Add MainActor to the entire class
class NutritionInsightsViewModel {
    // MARK: - Properties
    
    // Gemini Nutrition Assistant
    private let nutritionAssistant: GeminiNutritionAssistant
    
    // State properties
    var isLoading: Bool = false
    var error: Error?
    
    // Insight results
    var nutritionAnalysis: NutritionAnalysisResult?
    var nutritionRecommendations: NutritionRecommendation?
    var selectedEducationTopic: NutritionEducationContent?
    var mealOptimizationSuggestion: MealOptimizationSuggestion?
    
    // Computed properties for easy access
    var analysisHighlights: [String] {
        nutritionAnalysis?.analysisHighlights ?? []
    }
    
    var recommendationPoints: [String] {
        nutritionRecommendations?.recommendationPoints ?? []
    }
    
    // MARK: - Initializer
    init(
        geminiService: GeminiService? = nil,
        nutritionService: NutritionService? = nil,
        userProfileService: UserProfileService? = nil
    ) {
        // Initialize dependencies from AppServices or use provided services
        let geminiService = geminiService ?? AppServices.shared.getGeminiService()
        let nutritionService = nutritionService ?? AppServices.shared.getNutritionService()
        let userProfileService = userProfileService ?? AppServices.shared.getUserProfileService()
        
        // Create Gemini Nutrition Assistant
        nutritionAssistant = GeminiNutritionAssistant(
            geminiService: geminiService,
            nutritionService: nutritionService,
            userProfileService: userProfileService
        )
    }
    
    // MARK: - AI-Powered Nutrition Insights Methods
    
    /// Fetch comprehensive nutrition profile analysis
    func fetchNutritionAnalysis() async {
        isLoading = true
        error = nil
        
        do {
            nutritionAnalysis = try await nutritionAssistant.analyzeNutritionProfile()
        } catch {
            self.error = error
            print("Error fetching nutrition analysis: \(error)")
        }
        
        isLoading = false
    }
    
    /// Generate personalized nutrition recommendations
    func generateNutritionRecommendations() async {
        isLoading = true
        error = nil
        
        do {
            nutritionRecommendations = try await nutritionAssistant.generateNutritionRecommendations()
        } catch {
            self.error = error
            print("Error generating nutrition recommendations: \(error)")
        }
        
        isLoading = false
    }
    
    /// Optimize a specific meal's nutrition
    func optimizeMealNutrition(meal: Meal) async {
        isLoading = true
        error = nil
        
        do {
            mealOptimizationSuggestion = try await nutritionAssistant.optimizeMealNutrition(meal: meal)
        } catch {
            self.error = error
            print("Error optimizing meal nutrition: \(error)")
        }
        
        isLoading = false
    }
    
    /// Generate nutrition education content for a specific topic
    func generateNutritionEducation(topic: NutritionTopic) async {
        isLoading = true
        error = nil
        
        do {
            selectedEducationTopic = try await nutritionAssistant.generateNutritionEducationContent(topic: topic)
        } catch {
            self.error = error
            print("Error generating nutrition education content: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Convenience Methods
    
    /// Fetch all insights in sequence
    func fetchAllInsights() async {
        await fetchNutritionAnalysis()
        await generateNutritionRecommendations()
    }
    
    /// Reset all insights
    func resetInsights() {
        nutritionAnalysis = nil
        nutritionRecommendations = nil
        selectedEducationTopic = nil
        mealOptimizationSuggestion = nil
        error = nil
    }
}
