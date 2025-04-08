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

// MARK: - Example SwiftUI View
struct NutritionInsightsView: View {
    @State private var viewModel = NutritionInsightsViewModel()
    @State private var selectedTopic: NutritionTopic = .macronutrients
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Generating AI Insights...")
                } else if let error = viewModel.error {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                } else {
                    ScrollView {
                        // Nutrition Analysis Section
                        if let analysis = viewModel.nutritionAnalysis {
                            Section(header: Text("Nutrition Profile Analysis")) {
                                ForEach(analysis.analysisHighlights.indices, id: \.self) { index in
                                    Text(analysis.analysisHighlights[index])
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                        
                        // Recommendations Section
                        if let recommendations = viewModel.nutritionRecommendations {
                            Section(header: Text("Personalized Recommendations")) {
                                ForEach(recommendations.recommendationPoints.indices, id: \.self) { index in
                                    Text(recommendations.recommendationPoints[index])
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                        
                        // Nutrition Education Section
                        Picker("Education Topic", selection: $selectedTopic) {
                            ForEach(NutritionTopic.allCases, id: \.self) { topic in
                                Text(topic.rawValue).tag(topic)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Button("Get Education Content") {
                            Task {
                                await viewModel.generateNutritionEducation(topic: selectedTopic)
                            }
                        }
                        
                        if let education = viewModel.selectedEducationTopic {
                            Text(education.content)
                                .padding()
                        }
                    }
                }
            }
            .navigationTitle("AI Nutrition Insights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh Insights") {
                        Task {
                            await viewModel.fetchAllInsights()
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchAllInsights()
                }
            }
        }
    }
}
