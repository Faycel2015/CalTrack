//
//  NutritionProgressCard.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct NutritionProgressCard: View {
    // Nutrition values
    var calories: Double
    var calorieGoal: Double
    
    var carbs: Double
    var carbGoal: Double
    
    var protein: Double
    var proteinGoal: Double
    
    var fat: Double
    var fatGoal: Double
    
    // UI customization
    var showDetails: Bool = true
    var cardTitle: String = "Today's Nutrition"
    var cardSubtitle: String? = nil
    var showRemainingLabel: Bool = true
    var showAddButton: Bool = false
    var onAddTapped: (() -> Void)? = nil
    var onCardTapped: (() -> Void)? = nil
    
    // Animation
    @State private var showAnimation: Bool = false
    
    var body: some View {
        Button(action: {
            onCardTapped?()
        }) {
            VStack(spacing: 15) {
                // Card header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cardTitle)
                            .font(.headline)
                        
                        if let subtitle = cardSubtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if showAddButton, let onAddTapped = onAddTapped {
                        Button(action: onAddTapped) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                
                // Calories circular indicator
                VStack(spacing: 5) {
                    ZStack {
                        // Background ring
                        Circle()
                            .stroke(
                                Color(.systemGray5),
                                lineWidth: 15
                            )
                            .frame(width: 140, height: 140)
                        
                        // Progress ring
                        Circle()
                            .trim(from: 0, to: showAnimation ? min(1, calories / calorieGoal) : 0)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [.orange, .orange.opacity(0.8)]),
                                    center: .center,
                                    startAngle: .degrees(-90),
                                    endAngle: .degrees(270)
                                ),
                                style: StrokeStyle(lineWidth: 15, lineCap: .round)
                            )
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 1.0), value: showAnimation)
                        
                        // Inner content
                        VStack(spacing: 0) {
                            Text("\(Int(calories))")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            
                            Text("cal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if showRemainingLabel {
                                Text("\(Int(max(0, calorieGoal - calories))) remaining")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                    }
                    
                    if showDetails {
                        Text("\(Int(calories)) of \(Int(calorieGoal)) calories")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Macro nutrients progress
                if showDetails {
                    HStack(spacing: 25) {
                        // Carbs
                        macroProgressView(
                            title: "Carbs",
                            consumed: carbs,
                            goal: carbGoal,
                            color: .blue
                        )
                        
                        // Protein
                        macroProgressView(
                            title: "Protein",
                            consumed: protein,
                            goal: proteinGoal,
                            color: .green
                        )
                        
                        // Fat
                        macroProgressView(
                            title: "Fat",
                            consumed: fat,
                            goal: fatGoal,
                            color: .yellow
                        )
                    }
                    .padding(.top, 5)
                }
                
                // Macro distribution visualization
                if showDetails {
                    macroDistributionBar()
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
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Trigger animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showAnimation = true
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func macroProgressView(title: String, consumed: Double, goal: Double, color: Color) -> some View {
        let progress = min(1.0, consumed / max(1, goal))
        
        return VStack(spacing: 5) {
            // Progress bar
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 8)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: showAnimation ? 60 * progress : 0, height: 8)
                    .animation(.easeOut(duration: 1.0), value: showAnimation)
            }
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Values
            Text("\(Int(consumed))g")
                .font(.footnote.bold())
        }
    }
    
    private func macroDistributionBar() -> some View {
        let totalCaloriesFromMacros = (carbs * 4) + (protein * 4) + (fat * 9)
        
        // Calculate percentage breakdown
        let carbPercentage = totalCaloriesFromMacros > 0 ? (carbs * 4) / totalCaloriesFromMacros : 0.4
        let proteinPercentage = totalCaloriesFromMacros > 0 ? (protein * 4) / totalCaloriesFromMacros : 0.3
        let fatPercentage = totalCaloriesFromMacros > 0 ? (fat * 9) / totalCaloriesFromMacros : 0.3
        
        return VStack(spacing: 4) {
            // Distribution bar
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(carbPercentage))
                    
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * CGFloat(proteinPercentage))
                    
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(width: geometry.size.width * CGFloat(fatPercentage))
                }
                .cornerRadius(3)
                .frame(height: 6)
            }
            .frame(height: 6)
            
            // Legend
            HStack {
                Text("C: \(Int(carbPercentage * 100))%")
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("P: \(Int(proteinPercentage * 100))%")
                    .foregroundColor(.green)
                
                Spacer()
                
                Text("F: \(Int(fatPercentage * 100))%")
                    .foregroundColor(.yellow)
            }
            .font(.caption2)
        }
        .padding(.top, 5)
    }
}

// MARK: - Convenience Initializers

extension NutritionProgressCard {
    // Simplified initializer with just the essential values
    static func simple(
        calories: Double,
        calorieGoal: Double,
        showDetails: Bool = false,
        cardTitle: String = "Calories",
        onCardTapped: (() -> Void)? = nil
    ) -> NutritionProgressCard {
        NutritionProgressCard(
            calories: calories,
            calorieGoal: calorieGoal,
            carbs: 0,
            carbGoal: 0,
            protein: 0,
            proteinGoal: 0,
            fat: 0,
            fatGoal: 0,
            showDetails: showDetails,
            cardTitle: cardTitle,
            showRemainingLabel: true,
            onCardTapped: onCardTapped
        )
    }
    
    // Initializer for dashboard widget
    static func forDashboard(
        calories: Double,
        calorieGoal: Double,
        carbs: Double,
        carbGoal: Double,
        protein: Double,
        proteinGoal: Double,
        fat: Double,
        fatGoal: Double,
        onAddTapped: @escaping () -> Void,
        onCardTapped: @escaping () -> Void
    ) -> NutritionProgressCard {
        NutritionProgressCard(
            calories: calories,
            calorieGoal: calorieGoal,
            carbs: carbs,
            carbGoal: carbGoal,
            protein: protein,
            proteinGoal: proteinGoal,
            fat: fat,
            fatGoal: fatGoal,
            showDetails: true,
            cardTitle: "Today's Nutrition",
            cardSubtitle: "Tap to view detailed analysis",
            showAddButton: true,
            onAddTapped: onAddTapped,
            onCardTapped: onCardTapped
        )
    }
}

// MARK: - Preview Provider

struct NutritionProgressCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Full detailed card
            NutritionProgressCard(
                calories: 1650,
                calorieGoal: 2200,
                carbs: 175,
                carbGoal: 275,
                protein: 95,
                proteinGoal: 120,
                fat: 58,
                fatGoal: 73
            )
            
            // Simple version
            NutritionProgressCard.simple(
                calories: 1650,
                calorieGoal: 2200,
                cardTitle: "Calories Today"
            )
            
            // Dashboard version
            NutritionProgressCard.forDashboard(
                calories: 1650,
                calorieGoal: 2200,
                carbs: 175,
                carbGoal: 275,
                protein: 95,
                proteinGoal: 120,
                fat: 58,
                fatGoal: 73,
                onAddTapped: {},
                onCardTapped: {}
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .previewLayout(.sizeThatFits)
    }
}

#Preview {
    NutritionProgressCard()
}
