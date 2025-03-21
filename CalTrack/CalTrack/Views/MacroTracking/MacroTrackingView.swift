//
//  MacroTrackingView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

struct MacroTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    
    // Selected date for tracking
    @State private var selectedDate: Date = Date()
    
    // Active detail sheet
    @State private var activeDetailSheet: MacroType?
    
    // Macro types
    enum MacroType: String, CaseIterable, Identifiable {
        case calories = "Calories"
        case carbs = "Carbs"
        case protein = "Protein"
        case fat = "Fat"
        
        var id: String { self.rawValue }
        
        var color: Color {
            switch self {
            case .calories: return .orange
            case .carbs: return .blue
            case .protein: return .green
            case .fat: return .yellow
            }
        }
        
        var unit: String {
            return self == .calories ? "cal" : "g"
        }
        
        var systemIcon: String {
            switch self {
            case .calories: return "flame.fill"
            case .carbs: return "c.circle.fill"
            case .protein: return "p.circle.fill"
            case .fat: return "f.circle.fill"
            }
        }
        
        var description: String {
            switch self {
            case .calories:
                return "Calories are units of energy in food that your body uses for various functions. Managing calorie intake helps control weight."
            case .carbs:
                return "Carbohydrates are your body's main energy source. They break down into glucose, fueling your brain, muscles, and organs."
            case .protein:
                return "Protein is essential for building and repairing tissues, including muscles. It also supports immune function and hormone production."
            case .fat:
                return "Dietary fats are vital for hormone production, nutrient absorption, and cell membrane health. They also provide energy and insulation."
            }
        }
    }
    
    // Mock data for meals (would be replaced with actual meal data)
    @State private var mockMeals: [MockMeal] = [
        MockMeal(name: "Breakfast", type: .breakfast, calories: 450, carbs: 65, protein: 20, fat: 12),
        MockMeal(name: "Morning Snack", type: .snack, calories: 180, carbs: 15, protein: 12, fat: 8),
        MockMeal(name: "Lunch", type: .lunch, calories: 650, carbs: 80, protein: 35, fat: 20),
        MockMeal(name: "Afternoon Snack", type: .snack, calories: 150, carbs: 12, protein: 8, fat: 7),
        MockMeal(name: "Dinner", type: .dinner, calories: 720, carbs: 85, protein: 40, fat: 25)
    ]
    
    // Computed data
    var userProfile: UserProfile? {
        return userProfiles.first
    }
    
    var totalCalories: Double {
        return mockMeals.reduce(0) { $0 + $1.calories }
    }
    
    var totalCarbs: Double {
        return mockMeals.reduce(0) { $0 + $1.carbs }
    }
    
    var totalProtein: Double {
        return mockMeals.reduce(0) { $0 + $1.protein }
    }
    
    var totalFat: Double {
        return mockMeals.reduce(0) { $0 + $1.fat }
    }
    
    var caloricBreakdown: [Double] {
        // Calculate percentage breakdown [carbs, protein, fat]
        let carbCalories = totalCarbs * 4 // 4 calories per gram of carbs
        let proteinCalories = totalProtein * 4 // 4 calories per gram of protein
        let fatCalories = totalFat * 9 // 9 calories per gram of fat
        
        let totalFromMacros = carbCalories + proteinCalories + fatCalories
        
        if totalFromMacros <= 0 {
            return [0.4, 0.3, 0.3] // Default 40/30/30 split
        }
        
        return [
            carbCalories / totalFromMacros,
            proteinCalories / totalFromMacros,
            fatCalories / totalFromMacros
        ]
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Date selector header
                    dateSelectionHeader
                    
                    // Main macro indicators
                    macroCirclesSection
                    
                    // Macro distribution
                    macroDistributionSection
                    
                    // Meal breakdown
                    mealBreakdownSection
                    
                    // Weekly trends
                    weeklyTrendsSection
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Nutrition")
            .sheet(item: $activeDetailSheet) { macroType in
                MacroDetailSheet(
                    macroType: macroType,
                    value: getMacroValue(macroType),
                    goal: getMacroGoal(macroType),
                    meals: mockMeals
                )
            }
        }
    }
    
    // MARK: - View Components
    
    // Date selection header
    private var dateSelectionHeader: some View {
        HStack(spacing: 20) {
            // Previous day button
            Button(action: {
                withAnimation {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.headline)
            }
            
            // Date display
            VStack(spacing: 2) {
                Text(dateFormatter.string(from: selectedDate))
                    .font(.headline)
                
                Text(isToday ? "Today" : dayFormatter.string(from: selectedDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            
            // Next day button
            Button(action: {
                withAnimation {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.headline)
            }
        }
        .padding(.vertical, 10)
    }
    
    // Main macro indicators section
    private var macroCirclesSection: some View {
        VStack(spacing: 15) {
            // Main calorie indicator
            Button {
                activeDetailSheet = .calories
            } label: {
                VStack {
                    MacroCircularIndicator.calories(
                        value: totalCalories,
                        goal: userProfile?.dailyCalorieGoal ?? 2000,
                        size: 150
                    )
                    
                    Text("Tap for details")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 5)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Macro nutrients row
            HStack(spacing: 15) {
                // Carbs
                Button {
                    activeDetailSheet = .carbs
                } label: {
                    MacroCircularIndicator.carbs(
                        value: totalCarbs,
                        goal: userProfile?.carbGoalGrams ?? 250,
                        size: 100
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Protein
                Button {
                    activeDetailSheet = .protein
                } label: {
                    MacroCircularIndicator.protein(
                        value: totalProtein,
                        goal: userProfile?.proteinGoalGrams ?? 120,
                        size: 100
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Fat
                Button {
                    activeDetailSheet = .fat
                } label: {
                    MacroCircularIndicator.fat(
                        value: totalFat,
                        goal: userProfile?.fatGoalGrams ?? 65,
                        size: 100
                    )
                }
                .buttonStyle(PlainButtonStyle())
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
    
    // Macro distribution section
    private var macroDistributionSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Macro Distribution")
                    .font(.headline)
                
                Spacer()
                
                Text("% of Calories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Distribution visualization
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 30)
                    .cornerRadius(15)
                
                // Stacked segments
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: CGFloat(caloricBreakdown[0]) * UIScreen.main.bounds.width * 0.85)
                    
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: CGFloat(caloricBreakdown[1]) * UIScreen.main.bounds.width * 0.85)
                    
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(width: CGFloat(caloricBreakdown[2]) * UIScreen.main.bounds.width * 0.85)
                }
                .frame(height: 30)
                .cornerRadius(15)
            }
            
            // Legend
            HStack(spacing: 12) {
                legendItem(color: .blue, label: "Carbs", value: "\(Int(caloricBreakdown[0] * 100))%")
                legendItem(color: .green, label: "Protein", value: "\(Int(caloricBreakdown[1] * 100))%")
                legendItem(color: .yellow, label: "Fat", value: "\(Int(caloricBreakdown[2] * 100))%")
            }
            
            // Target versus actual
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Ratio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(userProfile?.carbPercentage ?? 0.4 * 100))% / \(Int(userProfile?.proteinPercentage ?? 0.3 * 100))% / \(Int(userProfile?.fatPercentage ?? 0.3 * 100))%")
                        .font(.subheadline.bold())
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Ratio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(caloricBreakdown[0] * 100))% / \(Int(caloricBreakdown[1] * 100))% / \(Int(caloricBreakdown[2] * 100))%")
                        .font(.subheadline.bold())
                }
            }
            .padding(.top, 5)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    // Meal breakdown section
    private var mealBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Meal Breakdown")
                .font(.headline)
            
            ForEach(mockMeals) { meal in
                VStack(spacing: 12) {
                    // Meal header
                    HStack {
                        Image(systemName: meal.type.systemImage)
                            .foregroundColor(Color.accentColor)
                        
                        Text(meal.name)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(Int(meal.calories)) cal")
                            .font(.subheadline.bold())
                    }
                    
                    // Macro bars
                    VStack(spacing: 8) {
                        macroProgressBar(
                            label: "Carbs",
                            value: meal.carbs,
                            total: totalCarbs,
                            color: .blue
                        )
                        
                        macroProgressBar(
                            label: "Protein",
                            value: meal.protein,
                            total: totalProtein,
                            color: .green
                        )
                        
                        macroProgressBar(
                            label: "Fat",
                            value: meal.fat,
                            total: totalFat,
                            color: .yellow
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                if meal.id != mockMeals.last?.id {
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
    }
    
    // Weekly trends section
    private var weeklyTrendsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Weekly Trends")
                .font(.headline)
            
            // Generate some sample data for the charts
            let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            let calorieValues = [1850, 2100, 1950, 2000, 1800, 2250, Int(totalCalories)]
            let carbValues = [220, 250, 240, 230, 210, 260, Int(totalCarbs)]
            let proteinValues = [110, 100, 115, 105, 95, 125, Int(totalProtein)]
            let fatValues = [60, 70, 65, 68, 58, 75, Int(totalFat)]
            
            // Use the first trend chart as an example
            VStack(spacing: 10) {
                HStack {
                    Text("Calories")
                        .font(.subheadline.bold())
                    
                    Spacer()
                    
                    Text("Weekly Average: \(calorieValues.reduce(0, +) / calorieValues.count) cal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<7) { index in
                        VStack(spacing: 4) {
                            // Bar
                            Rectangle()
                                .fill(
                                    index == 6 ? Color.accentColor : Color.accentColor.opacity(0.5)
                                )
                                .frame(
                                    height: CGFloat(calorieValues[index]) / 10
                                )
                                .cornerRadius(4)
                            
                            // Day label
                            Text(days[index])
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 120)
            }
            
            // Add a note about weekly trends
            Text("Tap on any macro indicator to see detailed weekly analysis")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 5)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Helper Views
    
    private func legendItem(color: Color, label: String, value: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.caption)
            
            Text(value)
                .font(.caption.bold())
        }
    }
    
    private func macroProgressBar(label: String, value: Double, total: Double, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .frame(width: 50, alignment: .leading)
            
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 10)
                    .cornerRadius(5)
                
                // Progress
                Rectangle()
                    .fill(color)
                    .frame(width: total > 0 ? CGFloat(value / total) * (UIScreen.main.bounds.width - 140) : 0, height: 10)
                    .cornerRadius(5)
            }
            
            Text("\(Int(value))g")
                .font(.caption)
                .frame(width: 35, alignment: .trailing)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getMacroValue(_ type: MacroType) -> Double {
        switch type {
        case .calories: return totalCalories
        case .carbs: return totalCarbs
        case .protein: return totalProtein
        case .fat: return totalFat
        }
    }
    
    private func getMacroGoal(_ type: MacroType) -> Double {
        guard let profile = userProfile else {
            // Default values if no profile exists
            switch type {
            case .calories: return 2000
            case .carbs: return 250
            case .protein: return 120
            case .fat: return 65
            }
        }
        
        switch type {
        case .calories: return profile.dailyCalorieGoal
        case .carbs: return profile.carbGoalGrams
        case .protein: return profile.proteinGoalGrams
        case .fat: return profile.fatGoalGrams
        }
    }
    
    // MARK: - Formatters
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
}

// MARK: - Mock Data Models for Preview

struct MockMeal: Identifiable {
    let id = UUID()
    let name: String
    let type: MealType
    let calories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
}

// MARK: - Macro Detail Sheet

struct MacroDetailSheet: View {
    let macroType: MacroTrackingView.MacroType
    let value: Double
    let goal: Double
    let meals: [MockMeal]
    
    @Environment(\.dismiss) private var dismiss
    
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
                                
                                Text("Weekly Average: \(Int(values.reduce(0, +) / Double(values.count))) \(macroType.unit)")
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
                                                height: CGFloat(values[index] / getMaxValue(values) * 100)
                                            )
                                            .cornerRadius(4)
                                        
                                        // Day label
                                        Text(days[index])
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        
                                        // Value label
                                        Text("\(Int(values[index]))")
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
                                
                                Text("\(Int(values.reduce(0, +))) \(macroType.unit)")
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
                                    .frame(width: min(CGFloat(values.reduce(0, +) / (goal * 7)), 1.0) * UIScreen.main.bounds.width * 0.85, height: 12)
                                    .cornerRadius(6)
                            }
                            
                            Text("\(Int(values.reduce(0, +) / (goal * 7) * 100))% of weekly goal")
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
    
    private func createSampleData() -> [Double] {
        // Create randomized weekly data with the final day matching the current value
        var result: [Double] = []
        let baseValue = goal * 0.9 // Base around 90% of goal
        
        for i in 0..<6 {
            let randomVariation = Double.random(in: -0.2...0.3)
            let dayValue = max(0, baseValue * (1 + randomVariation))
            result.append(dayValue)
        }
        
        // Add today's actual value
        result.append(value)
        
        return result
    }
    
    private func getMaxValue(_ values: [Double]) -> Double {
        values.max() ?? 1.0
    }
}

// MARK: - Preview Provider

struct MacroTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        MacroTrackingView()
    }
}()
                                
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
                        
                        // Create sample weekly data
                        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                        let values = createSampleData()
                        
                        VStack(spacing: 10) {
                            HStack {
                                Text("Daily Intake")
                                    .font(.subheadline.bold())
                                
                                Spacer()
                                

#Preview {
    MacroTrackingView()
}
