//
//  MealListView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

struct MealListView: View {
    // MARK: - Properties
    @StateObject private var viewModel: MealListViewModel
    @State private var selectedMeal: Meal?
    @State private var showEditMeal = false
    @State private var showDatePicker = false
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: MealListViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Date Selection Header
                dateSelectionHeader
                
                // Meal List or Empty State
                if viewModel.meals.isEmpty {
                    emptyMealsView
                } else {
                    mealListContent
                }
            }
            .navigationTitle("Meals")
            .navigationBarItems(
                trailing: HStack(spacing: 16) {
                    Button(action: { showDatePicker = true }) {
                        Image(systemName: "calendar")
                    }
                    
                    Button(action: { viewModel.showAddMeal = true }) {
                        Image(systemName: "plus")
                    }
                }
            )
            .sheet(isPresented: $showDatePicker) {
                datePicker
            }
            .sheet(isPresented: $viewModel.showAddMeal) {
                AddMealView(viewModel: viewModel.mealViewModel)
            }
            .sheet(isPresented: $showEditMeal) {
                if selectedMeal != nil {
                    AddMealView(viewModel: viewModel.mealViewModel, isEditing: true)
                }
            }
        }
    }
    
    // MARK: - Date Selection Header
    private var dateSelectionHeader: some View {
        HStack(spacing: 20) {
            Button(action: { viewModel.moveToPreviousDay() }) {
                Image(systemName: "chevron.left")
                    .font(.headline)
            }
            
            Button(action: { showDatePicker.toggle() }) {
                VStack(spacing: 2) {
                    Text(dateFormatter.string(from: viewModel.selectedDate))
                        .font(.headline)
                    
                    Text(viewModel.isToday ? "Today" : dayFormatter.string(from: viewModel.selectedDate))
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
            
            Button(action: { viewModel.moveToNextDay() }) {
                Image(systemName: "chevron.right")
                    .font(.headline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Date Picker
    private var datePicker: some View {
        DatePicker(
            "Select Date",
            selection: $viewModel.selectedDate,
            displayedComponents: .date
        )
        .datePickerStyle(GraphicalDatePickerStyle())
        .padding()
        .onChange(of: viewModel.selectedDate) { oldValue, newValue in
            viewModel.loadMealsForSelectedDate()
        }
    }
    
    // MARK: - Empty Meals View
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
            
            // Quick Add Meal Buttons
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
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
            
            Spacer()
        }
    }
    
    // MARK: - Meal List Content
    private var mealListContent: some View {
        List {
            // Nutrition Summary Section
            nutritionSummarySection
            
            // Meals by Type
            ForEach(MealType.allCases) { mealType in
                mealSection(for: mealType)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Nutrition Summary Section
    private var nutritionSummarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text("Daily Nutrition")
                    .font(.headline)
                
                NutritionProgressCard.simple(
                    calories: viewModel.totalCalories,
                    calorieGoal: viewModel.calorieGoal,
                    showDetails: true,
                    cardTitle: "Total Calories"
                )
            }
        }
    }
    
    // MARK: - Meal Section
    private func mealSection(for mealType: MealType) -> some View {
        let mealsForType = viewModel.meals.filter { $0.mealType == mealType }
        
        return mealsForType.isEmpty ? AnyView(EmptyView()) : AnyView(
            Section(header: mealSectionHeader(for: mealType)) {
                ForEach(mealsForType) { meal in
                    mealRow(meal)
                }
            }
        )
    }
    
    // MARK: - Meal Section Header
    private func mealSectionHeader(for mealType: MealType) -> some View {
        HStack {
            Image(systemName: mealType.systemImage)
                .foregroundColor(.accentColor)
            
            Text(mealType.rawValue)
                .font(.headline)
            
            Spacer()
            
            Button(action: {
                viewModel.startCreatingMeal(type: mealType)
            }) {
                Image(systemName: "plus")
            }
        }
    }
    
    // MARK: - Meal Row
    private func mealRow(_ meal: Meal) -> some View {
        Button(action: {
            selectedMeal = meal
            showEditMeal = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.name)
                        .font(.headline)
                    
                    Text("\(meal.foodItems.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(meal.calories)) cal")
                        .font(.subheadline)
                    
                    HStack(spacing: 4) {
                        Text("C: \(Int(meal.carbs))g")
                        Text("P: \(Int(meal.protein))g")
                        Text("F: \(Int(meal.fat))g")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .contextMenu {
            Button(action: {
                selectedMeal = meal
                showEditMeal = true
            }) {
                Label("Edit Meal", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: {
                viewModel.deleteMeal(meal)
            }) {
                Label("Delete Meal", systemImage: "trash")
            }
            
            Button(action: {
                viewModel.toggleFavoriteMeal(meal)
            }) {
                Label(
                    meal.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: meal.isFavorite ? "star.slash.fill" : "star.fill"
                )
            }
        }
    }
}

// MARK: - View Model
class MealListViewModel: ObservableObject {
    // MARK: - Properties
    private let modelContext: ModelContext
    let mealViewModel: MealViewModel
    
    @Published var selectedDate: Date = Date()
    @Published var meals: [Meal] = []
    @Published var showAddMeal: Bool = false
    
    // MARK: - Computed Properties
    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    var totalCalories: Double {
        meals.reduce(0) { $0 + $1.calories }
    }
    
    var calorieGoal: Double {
        // TODO: Fetch from user profile
        return 2000
    }
    
    // MARK: - Initializer
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.mealViewModel = MealViewModel(modelContext: modelContext)
        
        loadMealsForSelectedDate()
    }
    
    // MARK: - Date Navigation Methods
    func moveToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        loadMealsForSelectedDate()
    }
    
    func moveToNextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        loadMealsForSelectedDate()
    }
    
    // MARK: - Meal Loading
    func loadMealsForSelectedDate() {
        let startOfDay = selectedDate.startOfDay()
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<Meal> { meal in
            meal.date >= startOfDay && meal.date < endOfDay
        }
        
        let descriptor = FetchDescriptor<Meal>(predicate: predicate)
        
        do {
            meals = try modelContext.fetch(descriptor)
        } catch {
            print("Error loading meals: \(error)")
            meals = []
        }
    }
    
    // MARK: - Meal Actions
    func startCreatingMeal(type: MealType) {
        mealViewModel.startCreatingMeal(type: type)
        showAddMeal = true
    }
    
    func deleteMeal(_ meal: Meal) {
        modelContext.delete(meal)
        
        do {
            try modelContext.save()
            loadMealsForSelectedDate()
        } catch {
            print("Error deleting meal: \(error)")
        }
    }
    
    func toggleFavoriteMeal(_ meal: Meal) {
        meal.isFavorite.toggle()
        
        do {
            try modelContext.save()
            loadMealsForSelectedDate()
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }
}

// MARK: - Formatters
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    return formatter
}()

private let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter
}()

#Preview {
    MealListView(modelContext: try! ModelContainer(for: Meal.self).mainContext)
}
