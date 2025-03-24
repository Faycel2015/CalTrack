//
//  MealTrackingView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

struct MealTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    
    @State var viewModel: MealViewModel
    @State private var showDatePicker = false
    
    // Date formatting
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    init(modelContext: ModelContext) {
        let vm = MealViewModel(modelContext: modelContext)
        _viewModel = State(initialValue: vm)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Date selection header
                dateSelectionHeader
                
                // Main content
                if loadedMeals.isEmpty {
                    emptyMealsView
                } else {
                    mealListView
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(
                leading: Text("Meals")
                    .font(.title.bold()),
                trailing: HStack(spacing: 16) {
                    Button(action: {
                        // Calendar or date picker action
                        showDatePicker.toggle()
                    }) {
                        Image(systemName: "calendar")
                            .font(.headline)
                    }
                    
                    Button(action: {
                        // Quick add meal
                        viewModel.startCreatingMeal(type: .other)
                    }) {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
            )
            .sheet(isPresented: $viewModel.isCreatingMeal) {
                AddMealView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isEditingMeal) {
                AddMealView(viewModel: viewModel, isEditing: true)
            }
            .sheet(isPresented: $showDatePicker) {
                datePickerView
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var userProfile: UserProfile? {
        return userProfiles.first
    }
    
    private var loadedMeals: [Meal] {
        return viewModel.loadMealsForDate(viewModel.selectedDate)
    }
    
    private var totalNutrition: (calories: Double, carbs: Double, protein: Double, fat: Double) {
        return viewModel.getTotalNutrition(for: loadedMeals)
    }
    
    private var remainingCalories: Double {
        guard let profile = userProfile else { return 0 }
        return max(0, profile.dailyCalorieGoal - totalNutrition.calories)
    }
    
    private var calorieProgress: Double {
        guard let profile = userProfile, profile.dailyCalorieGoal > 0 else { return 0 }
        return min(1, totalNutrition.calories / profile.dailyCalorieGoal)
    }
    
    private var carbsProgress: Double {
        guard let profile = userProfile, profile.carbGoalGrams > 0 else { return 0 }
        return min(1, totalNutrition.carbs / profile.carbGoalGrams)
    }
    
    private var proteinProgress: Double {
        guard let profile = userProfile, profile.proteinGoalGrams > 0 else { return 0 }
        return min(1, totalNutrition.protein / profile.proteinGoalGrams)
    }
    
    private var fatProgress: Double {
        guard let profile = userProfile, profile.fatGoalGrams > 0 else { return 0 }
        return min(1, totalNutrition.fat / profile.fatGoalGrams)
    }
    
    private var sortedMealsByType: [MealType: [Meal]] {
        return viewModel.getMealsByType(loadedMeals)
    }
    
    private var isToday: Bool {
        return viewModel.selectedDate.isToday
    }
    
    // MARK: - View Components
    
    private var dateSelectionHeader: some View {
        HStack(spacing: 20) {
            // Previous day button
            Button(action: {
                withAnimation {
                    viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: viewModel.selectedDate) ?? viewModel.selectedDate
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.headline)
            }
            
            // Date display button
            Button(action: {
                showDatePicker.toggle()
            }) {
                VStack(spacing: 2) {
                    Text(dateFormatter.string(from: viewModel.selectedDate))
                        .font(.headline)
                    
                    Text(isToday ? "Today" : dayFormatter.string(from: viewModel.selectedDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            }
            
            // Next day button
            Button(action: {
                withAnimation {
                    viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: viewModel.selectedDate) ?? viewModel.selectedDate
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.headline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var datePickerView: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $viewModel.selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
            }
            .navigationBarTitle("Choose Date", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    showDatePicker = false
                }
            )
        }
    }
    
    private var emptyMealsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No meals logged for this day")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Tap the + button to add your first meal")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Quick add buttons
            VStack(spacing: 10) {
                ForEach(MealType.allCases) { mealType in
                    Button(action: {
                        viewModel.startCreatingMeal(type: mealType)
                    }) {
                        HStack {
                            Image(systemName: mealType.systemImage)
                                .font(.headline)
                            
                            Text("Add \(mealType.rawValue)")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
            
            Spacer()
        }
    }
    
    private var mealListView: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Summary card
                nutritionSummaryCard
                
                // Meal list by type
                ForEach(MealType.allCases) { mealType in
                    if let meals = sortedMealsByType[mealType], !meals.isEmpty {
                        mealSectionView(title: mealType.rawValue, icon: mealType.systemImage, meals: meals)
                    } else {
                        emptyMealSectionView(mealType: mealType)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private func mealSectionView(title: String, icon: String, meals: [Meal]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    viewModel.startCreatingMeal(type: MealType(rawValue: title) ?? .other)
                }) {
                    Image(systemName: "plus.circle")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)
            
            // Meals list
            ForEach(meals) { meal in
                Button(action: {
                    viewModel.startEditingMeal(meal)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(meal.name)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Text("\(meal.foodItems.count) items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 3) {
                            Text("\(Int(meal.calories)) cal")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Text("C: \(Int(meal.carbs))g P: \(Int(meal.protein))g F: \(Int(meal.fat))g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
        }
    }
    
    private func emptyMealSectionView(mealType: MealType) -> some View {
        Button(action: {
            viewModel.startCreatingMeal(type: mealType)
        }) {
            HStack {
                Label(mealType.rawValue, systemImage: mealType.systemImage)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Add \(mealType.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                
                Image(systemName: "plus.circle")
                    .foregroundColor(.accentColor)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var nutritionSummaryCard: some View {
        VStack(spacing: 15) {
            // Calories left heading
            VStack(spacing: 5) {
                Text("Calories Remaining")
                    .font(.headline)
                
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(remainingCalories))")
                        .font(.system(size: 36, weight: .bold))
                    
                    Text("cal")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.leading, -4)
                }
            }
            
            // Calories progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                        .frame(height: 20)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGreen))
                        .frame(width: geometry.size.width * CGFloat(calorieProgress), height: 20)
                }
            }
            .frame(height: 20)
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

#Preview {
    // Create a ModelContext for preview
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Meal.self, FoodItem.self, UserProfile.self, configurations: config)
    
    return MealTrackingView(modelContext: container.mainContext)
}
