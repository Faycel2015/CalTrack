//
//  MacroDistributionView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct MacroDistributionView: View {
    // Macro data
    let totalCalories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
    
    // Optional goal data
    let carbGoal: Double?
    let proteinGoal: Double?
    let fatGoal: Double?
    
    // Optional actions
    let onDetailTap: (() -> Void)?
    
    // Computed properties
    private var carbCalories: Double { carbs * 4 }
    private var proteinCalories: Double { protein * 4 }
    private var fatCalories: Double { fat * 9 }
    
    private var caloricBreakdown: [Double] {
        let totalMacroCalories = carbCalories + proteinCalories + fatCalories
        
        guard totalMacroCalories > 0 else {
            return [0.4, 0.3, 0.3] // Default 40/30/30 split
        }
        
        return [
            carbCalories / totalMacroCalories,
            proteinCalories / totalMacroCalories,
            fatCalories / totalMacroCalories
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Section Header
            HStack {
                Text("Macro Distribution")
                    .font(.headline)
                
                Spacer()
                
                Text("% of Total Calories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Distribution Visualization
            VStack(spacing: 10) {
                // Stacked Distribution Bar
                distributionBar
                
                // Legend with Percentages
                distributionLegend
                
                // Comparison with Goals
                if let carbGoal = carbGoal,
                   let proteinGoal = proteinGoal,
                   let fatGoal = fatGoal {
                    macroGoalComparison(
                        carbGoal: carbGoal,
                        proteinGoal: proteinGoal,
                        fatGoal: fatGoal
                    )
                }
                
                // Detail Action
                if let onDetailTap = onDetailTap {
                    detailActionButton(action: onDetailTap)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // Distribution Bar Visualization
    private var distributionBar: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Carbs
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * CGFloat(caloricBreakdown[0]))
                
                // Protein
                Rectangle()
                    .fill(Color.green)
                    .frame(width: geometry.size.width * CGFloat(caloricBreakdown[1]))
                
                // Fat
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: geometry.size.width * CGFloat(caloricBreakdown[2]))
            }
            .cornerRadius(8)
            .frame(height: 30)
        }
        .frame(height: 30)
    }
    
    // Distribution Legend
    private var distributionLegend: some View {
        HStack {
            legendItem(
                color: .blue,
                label: "Carbs",
                percentage: caloricBreakdown[0],
                grams: carbs
            )
            
            Spacer()
            
            legendItem(
                color: .green,
                label: "Protein",
                percentage: caloricBreakdown[1],
                grams: protein
            )
            
            Spacer()
            
            legendItem(
                color: .yellow,
                label: "Fat",
                percentage: caloricBreakdown[2],
                grams: fat
            )
        }
    }
    
    // Macro Goal Comparison
    private func macroGoalComparison(
        carbGoal: Double,
        proteinGoal: Double,
        fatGoal: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Macro Goal Comparison")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                goalComparisonItem(
                    title: "Carbs",
                    current: carbs,
                    goal: carbGoal,
                    color: .blue
                )
                
                Spacer()
                
                goalComparisonItem(
                    title: "Protein",
                    current: protein,
                    goal: proteinGoal,
                    color: .green
                )
                
                Spacer()
                
                goalComparisonItem(
                    title: "Fat",
                    current: fat,
                    goal: fatGoal,
                    color: .yellow
                )
            }
        }
        .padding(.top, 10)
    }
    
    // Detail Action Button
    private func detailActionButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text("View Detailed Breakdown")
                    .font(.subheadline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    // Helper Views
    private func legendItem(
        color: Color,
        label: String,
        percentage: Double,
        grams: Double
    ) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                
                Text(label)
                    .font(.caption)
            }
            
            Text("\(Int(percentage * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("\(Int(grams))g")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func goalComparisonItem(
        title: String,
        current: Double,
        goal: Double,
        color: Color
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(Int(current))g")
                .font(.subheadline)
                .foregroundColor(current >= goal ? .green : color)
            
            Text("Goal: \(Int(goal))g")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // Convenience initializer for sample data
    static func sample() -> MacroDistributionView {
        MacroDistributionView(
            totalCalories: 1650,
            carbs: 175,
            protein: 95,
            fat: 58,
            carbGoal: 250,
            proteinGoal: 120,
            fatGoal: 65,
            onDetailTap: {}
        )
    }
}

#Preview {
    MacroDistributionView.sample()
        .padding()
        .background(Color(.systemGray6))
}
