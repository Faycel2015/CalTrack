//
//  QuickAddView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct QuickAddView: View {
    // MARK: - Properties
    @StateObject private var viewModel = QuickAddViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // Completion handler for added food item
    var onFoodItemAdded: ((FoodItem) -> Void)?
    
    var body: some View {
        NavigationView {
            Form {
                // Meal Type Section
                Section(header: Text("Meal Type")) {
                    Picker("Select Meal Type", selection: $viewModel.selectedMealType) {
                        ForEach(MealType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Nutrition Input Section
                Section(header: Text("Nutrition Details")) {
                    nutritionInputField(
                        title: "Calories",
                        value: $viewModel.calories,
                        unit: "cal"
                    )
                    
                    nutritionInputField(
                        title: "Carbohydrates",
                        value: $viewModel.carbs,
                        unit: "g"
                    )
                    
                    nutritionInputField(
                        title: "Protein",
                        value: $viewModel.protein,
                        unit: "g"
                    )
                    
                    nutritionInputField(
                        title: "Fat",
                        value: $viewModel.fat,
                        unit: "g"
                    )
                }
                
                // Optional Details Section
                Section(header: Text("Optional Details")) {
                    TextField("Food Name (Optional)", text: $viewModel.foodName)
                    
                    TextField("Serving Size (Optional)", text: $viewModel.servingSize)
                }
                
                // Quick Preset Buttons
                Section(header: Text("Quick Presets")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            presetButton(title: "Snack", calories: 200)
                            presetButton(title: "Light Meal", calories: 400)
                            presetButton(title: "Regular Meal", calories: 600)
                            presetButton(title: "Large Meal", calories: 800)
                        }
                    }
                }
            }
            .navigationTitle("Quick Add")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Add") {
                    if let foodItem = viewModel.createFoodItem() {
                        onFoodItemAdded?(foodItem)
                        dismiss()
                    }
                }
                .disabled(!viewModel.isValid)
            )
        }
    }
    
    // MARK: - Nutrition Input Field
    private func nutritionInputField(
        title: String,
        value: Binding<String>,
        unit: String
    ) -> some View {
        HStack {
            Text(title)
            
            Spacer()
            
            TextField("0", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
            
            Text(unit)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Preset Button
    private func presetButton(title: String, calories: Int) -> some View {
        Button(action: {
            viewModel.setPreset(calories: calories)
        }) {
            VStack {
                Text(title)
                    .font(.headline)
                
                Text("\(calories) cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

// MARK: - View Model
class QuickAddViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedMealType: MealType = .other
    @Published var calories: String = ""
    @Published var carbs: String = ""
    @Published var protein: String = ""
    @Published var fat: String = ""
    @Published var foodName: String = ""
    @Published var servingSize: String = ""
    
    // MARK: - Computed Properties
    var isValid: Bool {
        guard let cal = Double(calories), cal > 0 else { return false }
        return true
    }
    
    // MARK: - Methods
    func setPreset(calories: Int) {
        self.calories = String(calories)
        
        // Estimate macros based on preset
        switch calories {
        case ..<300:
            carbs = String(format: "%.1f", Double(calories) * 0.5 / 4)
            protein = String(format: "%.1f", Double(calories) * 0.3 / 4)
            fat = String(format: "%.1f", Double(calories) * 0.2 / 9)
            servingSize = "1 serving"
        case 300..<500:
            carbs = String(format: "%.1f", Double(calories) * 0.4 / 4)
            protein = String(format: "%.1f", Double(calories) * 0.3 / 4)
            fat = String(format: "%.1f", Double(calories) * 0.3 / 9)
            servingSize = "1 serving"
        default:
            carbs = String(format: "%.1f", Double(calories) * 0.45 / 4)
            protein = String(format: "%.1f", Double(calories) * 0.25 / 4)
            fat = String(format: "%.1f", Double(calories) * 0.3 / 9)
            servingSize = "1 serving"
        }
    }
    
    func createFoodItem() -> FoodItem? {
        guard let calories = Double(calories) else { return nil }
        
        let carbs = Double(carbs) ?? 0
        let protein = Double(protein) ?? 0
        let fat = Double(fat) ?? 0
        
        let name = foodName.isEmpty ? "Quick Add" : foodName
        let serving = servingSize.isEmpty ? "1 serving" : servingSize
        
        return FoodItem(
            name: name,
            servingSize: serving,
            servingQuantity: 1.0,
            calories: calories,
            carbs: carbs,
            protein: protein,
            fat: fat,
            isCustom: true
        )
    }
}

#Preview {
    QuickAddView()
}
