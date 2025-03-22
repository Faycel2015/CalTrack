//
//  MealSummaryCard.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct MealSummaryCard: View {
    // Meal details
    let title: String
    let time: String
    let calories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
    
    // Optional actions
    let onEditTapped: (() -> Void)?
    let onDeleteTapped: (() -> Void)?
    
    // Visual customization
    var color: Color = .green
    
    var body: some View {
        HStack(spacing: 15) {
            // Meal type icon
            mealTypeIcon
            
            // Meal details
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.headline)
                        
                        Text(time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Calories
                    VStack(alignment: .trailing) {
                        Text("\(Int(calories))")
                            .font(.headline)
                            .foregroundColor(color)
                        
                        Text("calories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Macronutrients
                HStack {
                    macroNutrientView(title: "Carbs", value: "\(Int(carbs))g", color: .blue)
                    Spacer()
                    macroNutrientView(title: "Protein", value: "\(Int(protein))g", color: .green)
                    Spacer()
                    macroNutrientView(title: "Fat", value: "\(Int(fat))g", color: .yellow)
                }
            }
            .padding(.vertical, 5)
            
            // Optional actions
            if onEditTapped != nil || onDeleteTapped != nil {
                VStack(spacing: 10) {
                    if let onEditTapped = onEditTapped {
                        Button(action: onEditTapped) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let onDeleteTapped = onDeleteTapped {
                        Button(action: onDeleteTapped) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
    }
    
    private var mealTypeIcon: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 50, height: 50)
            
            Image(systemName: mealTypeIconName)
                .foregroundColor(color)
                .font(.title3)
        }
    }
    
    private var mealTypeIconName: String {
        switch title.lowercased() {
        case "breakfast": return "sunrise"
        case "lunch": return "sun.max"
        case "dinner": return "moon"
        case "snack": return "bag"
        default: return "fork.knife"
        }
    }
    
    private func macroNutrientView(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // Convenience initializers
    static func sample() -> MealSummaryCard {
        MealSummaryCard(
            title: "Breakfast",
            time: "8:30 AM",
            calories: 450,
            carbs: 55,
            protein: 25,
            fat: 15,
            onEditTapped: nil,
            onDeleteTapped: nil,
            color: .blue
        )
    }
}

#Preview {
    VStack(spacing: 15) {
        MealSummaryCard.sample()
        
        MealSummaryCard(
            title: "Lunch",
            time: "12:45 PM",
            calories: 650,
            carbs: 80,
            protein: 35,
            fat: 20,
            onEditTapped: {},
            onDeleteTapped: {},
            color: .green
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
