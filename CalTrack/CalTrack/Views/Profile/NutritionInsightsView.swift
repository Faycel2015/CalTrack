//
//  NutritionInsightsView.swift
//  CalTrack
//
//  Created by FayTek on 4/11/25.
//

import SwiftUI
import SwiftData

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

#Preview {
    NutritionInsightsView()
}
