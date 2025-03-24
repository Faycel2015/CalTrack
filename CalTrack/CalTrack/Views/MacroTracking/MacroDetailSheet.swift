//
//  MacroDetailSheet.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

// MARK: - Macro Detail Sheet

struct MacroDetailSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    let macroType: MacroTrackingView.MacroType
    let value: Double
    let goal: Double
    let meals: [MockMeal]
    
    // Generated weekly data
    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private var weeklyValues: [Double]
    
    init(
        macroType: MacroTrackingView.MacroType = .carbs,
        value: Double = 100,
        goal: Double = 250,
        meals: [MockMeal] = []
    ) {
        self.macroType = macroType
        self.value = value
        self.goal = goal
        self.meals = meals
        
        // Initialize weekly values with sample data
        self.weeklyValues = Self.createSampleData(goal: goal, currentValue: value)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header with indicator
                    VStack(spacing: 10) {
                        // Circular indicator
                        MacroCircularIndicator(
                            value: value,
                            goal: goal,
                            title: macroType.rawValue,
                            unit: macroType.unit,
                            color: macroType.color,
                            size: 160
                        )
                        
                        // Description
                        Text(macroType.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .padding(.top, 5)
                    }
                    .padding(.vertical)
                    
                    // Sources breakdown
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Sources")
                            .font(.headline)
                        
                        ForEach(meals.sorted(by: { getMacroValue(from: $0) > getMacroValue(from: $1) })) { meal in
                            HStack {
                                Text(meal.name)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(Int(getMacroValue(from: meal))) \(macroType.unit)")
                                    .font(.subheadline.bold())
                                
                                Text("(\(Int(getMacroValue(from: meal) / value * 100))%)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            
                            if meal.id != meals.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    
                    // Weekly trends
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Weekly Trends")
                            .font(.headline)
                        
                        VStack(spacing: 10) {
                            HStack {
                                Text("Daily Intake")
                                    .font(.subheadline.bold())
                                
                                Spacer()
                                
                                Text("Weekly Average: \(Int(weeklyValues.reduce(0, +) / Double(weeklyValues.count))) \(macroType.unit)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(alignment: .bottom, spacing: 8) {
                                ForEach(0..<7) { index in
                                    VStack(spacing: 4) {
                                        // Bar
                                        Rectangle()
                                            .fill(
                                                index == 6 ? macroType.color : macroType.color.opacity(0.5)
                                            )
                                            .frame(
                                                height: CGFloat(weeklyValues[index] / getMaxValue(weeklyValues) * 100)
                                            )
                                            .cornerRadius(4)
                                        
                                        // Day label
                                        Text(days[index])
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        
                                        // Value label
                                        Text("\(Int(weeklyValues[index]))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(height: 120)
                        }
                        
                        // Progress towards weekly goals
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weekly Goal Progress")
                                .font(.subheadline.bold())
                            
                            HStack {
                                Text("Weekly Goal")
                                
                                Spacer()
                                
                                Text("\(Int(goal * 7)) \(macroType.unit)")
                                    .font(.subheadline.bold())
                            }
                            .font(.subheadline)
                            
                            HStack {
                                Text("Current Total")
                                
                                Spacer()
                                
                                Text("\(Int(weeklyValues.reduce(0, +))) \(macroType.unit)")
                                    .font(.subheadline.bold())
                            }
                            .font(.subheadline)
                            
                            // Progress bar
                            ZStack(alignment: .leading) {
                                // Background
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 12)
                                    .cornerRadius(6)
                                
                                // Progress
                                Rectangle()
                                    .fill(macroType.color)
                                    .frame(width: min(CGFloat(weeklyValues.reduce(0, +) / (goal * 7)), 1.0) * UIScreen.main.bounds.width * 0.85, height: 12)
                                    .cornerRadius(6)
                            }
                            
                            Text("\(Int(weeklyValues.reduce(0, +) / (goal * 7) * 100))% of weekly goal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    
                    // Nutrition info
                    if macroType != .calories {
                        nutritionInfoSection
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("\(macroType.rawValue) Details")
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
    
    // Nutrition info section
    private var nutritionInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Nutrition Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                switch macroType {
                case .carbs:
                    nutritionInfoRow(title: "Energy Value", value: "4 calories per gram")
                    nutritionInfoRow(title: "Recommended Intake", value: "45-65% of total calories")
                    nutritionInfoRow(title: "Main Function", value: "Primary energy source for the body and brain")
                    nutritionInfoRow(title: "Common Sources", value: "Grains, fruits, vegetables, legumes")
                    
                case .protein:
                    nutritionInfoRow(title: "Energy Value", value: "4 calories per gram")
                    nutritionInfoRow(title: "Recommended Intake", value: "10-35% of total calories")
                    nutritionInfoRow(title: "Main Function", value: "Tissue building, enzyme production, immune function")
                    nutritionInfoRow(title: "Common Sources", value: "Meat, fish, eggs, dairy, legumes, nuts")
                    
                case .fat:
                    nutritionInfoRow(title: "Energy Value", value: "9 calories per gram")
                    nutritionInfoRow(title: "Recommended Intake", value: "20-35% of total calories")
                    nutritionInfoRow(title: "Main Function", value: "Energy storage, hormone production, nutrient absorption")
                    nutritionInfoRow(title: "Common Sources", value: "Oils, butter, nuts, seeds, fatty meats, fish")
                    
                default:
                    EmptyView()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    // Helper function for displaying nutrition information
    private func nutritionInfoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
        }
    }
    
    // Helper methods
    private func getMacroValue(from meal: MockMeal) -> Double {
        switch macroType {
        case .calories: return meal.calories
        case .carbs: return meal.carbs
        case .protein: return meal.protein
        case .fat: return meal.fat
        }
    }
    
    // Add missing helper method
    private func getMaxValue(_ values: [Double]) -> Double {
        return values.max() ?? 0
    }
    
    private static func createSampleData(goal: Double, currentValue: Double) -> [Double] {
        // Create randomized weekly data with the final day matching the current value
        var result: [Double] = []
        let baseValue = goal * 0.9 // Base around 90% of goal
        
        for _ in 0..<6 {
            let randomVariation = Double.random(in: -0.2...0.3)
            let dayValue = max(0, baseValue * (1 + randomVariation))
            result.append(dayValue)
        }
        
        // Add today's actual value
        result.append(currentValue)
        
        return result
    }
}

#Preview {
    MacroDetailSheet()
}
