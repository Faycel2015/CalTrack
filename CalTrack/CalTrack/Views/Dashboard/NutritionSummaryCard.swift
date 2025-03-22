//
//  NutritionSummaryCard.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct NutritionSummaryCard: View {
    // Nutrition Data
    let date: Date
    let totalCalories: Double
    let calorieGoal: Double
    
    // Macronutrients
    let carbs: Double
    let protein: Double
    let fat: Double
    
    // Goals
    let carbGoal: Double
    let proteinGoal: Double
    let fatGoal: Double
    
    // Optional actions
    let onDetailsTapped: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            headerSection
            
            // Calorie Overview
            calorieProgressSection
            
            // Macronutrient Breakdown
            macronutrientBreakdownSection
            
            // Action Button
            if let onDetailsTapped = onDetailsTapped {
                actionButton(action: onDetailsTapped)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Nutrition Summary")
                    .font(.headline)
                
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var calorieProgressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Calorie Intake")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color.orange.opacity(0.2), lineWidth: 10)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: min(totalCalories / calorieGoal, 1.0))
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.orange, .red]),
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("\(Int(totalCalories))")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("cal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Calorie Details
                VStack(alignment: .leading, spacing: 5) {
                    progressDetailRow(
                        title: "Goal",
                        value: "\(Int(calorieGoal)) cal",
                        color: .orange
                    )
                    
                    progressDetailRow(
                        title: "Remaining",
                        value: "\(Int(max(0, calorieGoal - totalCalories))) cal",
                        color: .green
                    )
                }
                .padding(.leading)
            }
        }
    }
    
    private var macronutrientBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Macronutrient Breakdown")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                macronutrientView(
                    title: "Carbs",
                    value: "\(Int(carbs))g",
                    goal: "\(Int(carbGoal))g",
                    color: .blue
                )
                
                macronutrientView(
                    title: "Protein",
                    value: "\(Int(protein))g",
                    goal: "\(Int(proteinGoal))g",
                    color: .green
                )
                
                macronutrientView(
                    title: "Fat",
                    value: "\(Int(fat))g",
                    goal: "\(Int(fatGoal))g",
                    color: .yellow
                )
            }
        }
    }
    
    private func progressDetailRow(title: String, value: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .foregroundColor(color)
        }
    }
    
    private func macronutrientView(title: String, value: String, goal: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.subheadline)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Goal: \(goal)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func actionButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text("View Full Details")
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
    
    // Convenience initializer for preview and testing
    static func sample() -> NutritionSummaryCard {
        NutritionSummaryCard(
            date: Date(),
            totalCalories: 1650,
            calorieGoal: 2000,
            carbs: 175,
            protein: 95,
            fat: 58,
            carbGoal: 250,
            proteinGoal: 120,
            fatGoal: 65,
            onDetailsTapped: {}
        )
    }
}

#Preview {
    NutritionSummaryCard.sample()
        .padding()
        .background(Color(.systemGray6))
}
