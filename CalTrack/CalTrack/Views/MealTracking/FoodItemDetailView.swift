//
//  FoodItemDetailView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

struct FoodItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MealViewModel
    let foodItem: FoodItem
    
    @State private var quantity: Double
    @State private var isFavorite: Bool
    
    init(viewModel: MealViewModel, foodItem: FoodItem) {
        self.viewModel = viewModel
        self.foodItem = foodItem
        _quantity = State(initialValue: foodItem.servingQuantity)
        _isFavorite = State(initialValue: foodItem.isFavorite)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Food details section
                VStack(spacing: 15) {
                    // Name and favorite
                    HStack {
                        Text(foodItem.name)
                            .font(.title3.bold())
                        
                        Spacer()
                        
                        Button(action: {
                            isFavorite.toggle()
                        }) {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(isFavorite ? .yellow : .gray)
                        }
                    }
                    
                    // Serving size
                    HStack {
                        Text("Serving Size:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(foodItem.servingSize)
                            .font(.subheadline)
                        
                        Spacer()
                    }
                    
                    // Divider
                    Divider()
                    
                    // Quantity adjuster
                    VStack(spacing: 10) {
                        Text("Serving Quantity")
                            .font(.headline)
                        
                        HStack {
                            // Decrease button
                            Button(action: {
                                if quantity > 0.25 {
                                    quantity -= 0.25
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                            
                            // Quantity display and slider
                            VStack {
                                Text("\(quantityFormatted)")
                                    .font(.title3.bold())
                                    .frame(width: 80)
                                
                                Slider(value: $quantity, in: 0.25...10, step: 0.25)
                                    .accentColor(.accentColor)
                            }
                            .padding(.horizontal)
                            
                            // Increase button
                            Button(action: {
                                if quantity < 10 {
                                    quantity += 0.25
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        
                        // Common quantity buttons
                        HStack(spacing: 10) {
                            ForEach([0.5, 1.0, 2.0, 3.0], id: \.self) { value in
                                Button(action: {
                                    quantity = value
                                }) {
                                    Text("\(value, specifier: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f")")
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(quantity == value ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                                        )
                                        .foregroundColor(quantity == value ? .accentColor : .primary)
                                }
                            }
                        }
                    }
                    
                    Divider()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Nutrition info with current quantity
                VStack(spacing: 15) {
                    Text("Nutrition Info")
                        .font(.headline)
                    
                    // Calories and macros
                    HStack(spacing: 20) {
                        nutritionCircle(
                            value: Int(foodItem.calories * quantity),
                            title: "Calories",
                            color: .orange
                        )
                        
                        nutritionCircle(
                            value: Int(foodItem.carbs * quantity),
                            title: "Carbs",
                            unit: "g",
                            color: .blue
                        )
                        
                        nutritionCircle(
                            value: Int(foodItem.protein * quantity),
                            title: "Protein",
                            unit: "g",
                            color: .green
                        )
                        
                        nutritionCircle(
                            value: Int(foodItem.fat * quantity),
                            title: "Fat",
                            unit: "g",
                            color: .yellow
                        )
                    }
                    
                    Divider()
                    
                    // Additional nutrition details (if available)
                    if hasAdditionalNutrition {
                        VStack(spacing: 10) {
                            if let sugar = foodItem.sugar {
                                nutritionRow(title: "Sugar", value: sugar * quantity, unit: "g")
                            }
                            
                            if let fiber = foodItem.fiber {
                                nutritionRow(title: "Fiber", value: fiber * quantity, unit: "g")
                            }
                            
                            if let sodium = foodItem.sodium {
                                nutritionRow(title: "Sodium", value: sodium * quantity, unit: "mg")
                            }
                            
                            if let cholesterol = foodItem.cholesterol {
                                nutritionRow(title: "Cholesterol", value: cholesterol * quantity, unit: "mg")
                            }
                            
                            if let saturatedFat = foodItem.saturatedFat {
                                nutritionRow(title: "Saturated Fat", value: saturatedFat * quantity, unit: "g")
                            }
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
                
                Spacer()
                
                // Add button
                Button(action: {
                    // Create a copy with updated quantity
                    let updatedItem = FoodItem(
                        name: foodItem.name,
                        servingSize: foodItem.servingSize,
                        servingQuantity: quantity,
                        calories: foodItem.calories,
                        carbs: foodItem.carbs,
                        protein: foodItem.protein,
                        fat: foodItem.fat,
                        sugar: foodItem.sugar,
                        fiber: foodItem.fiber,
                        sodium: foodItem.sodium,
                        cholesterol: foodItem.cholesterol,
                        saturatedFat: foodItem.saturatedFat,
                        transFat: foodItem.transFat,
                        isCustom: foodItem.isCustom,
                        barcode: foodItem.barcode,
                        foodDatabaseId: foodItem.foodDatabaseId,
                        isFavorite: isFavorite
                    )
                    
                    // Check if we're editing an existing item
                    if let index = viewModel.selectedFoodItems.firstIndex(where: { $0.id == foodItem.id }) {
                        viewModel.selectedFoodItems.remove(at: index)
                    }
                    
                    viewModel.selectedFoodItems.append(updatedItem)
                    dismiss()
                }) {
                    Text("Add to Meal")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitle("Food Details", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
    
    // MARK: - Helper Views
    
    private func nutritionCircle(value: Int, title: String, unit: String = "", color: Color) -> some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 70, height: 70)
                
                VStack(spacing: 0) {
                    Text("\(value)")
                        .font(.headline)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func nutritionRow(title: String, value: Double, unit: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(Int(value)) \(unit)")
                .font(.subheadline)
        }
    }
    
    // MARK: - Computed Properties
    
    private var quantityFormatted: String {
        let isWholeNumber = quantity.truncatingRemainder(dividingBy: 1) == 0
        return isWholeNumber ? String(format: "%.0f", quantity) : String(format: "%.2f", quantity)
    }
    
    private var hasAdditionalNutrition: Bool {
        return foodItem.sugar != nil ||
            foodItem.fiber != nil ||
            foodItem.sodium != nil ||
            foodItem.cholesterol != nil ||
            foodItem.saturatedFat != nil
    }
}

#Preview {
    FoodItemDetailView()
}
