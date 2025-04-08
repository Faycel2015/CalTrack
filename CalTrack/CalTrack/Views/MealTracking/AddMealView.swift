//
//  AddMealView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: MealViewModel

    var isEditing: Bool = false
    @State private var selectedTab = 0
    @State private var showScanner = false

    // Tabs
    private enum MealCreationTab: Int, CaseIterable {
        case search = 0
        case recent = 1
        case favorites = 2
        case quickAdd = 3

        var title: String {
            switch self {
            case .search: return "Search"
            case .recent: return "Recent"
            case .favorites: return "Favorites"
            case .quickAdd: return "Quick Add"
            }
        }

        var icon: String {
            switch self {
            case .search: return "magnifyingglass"
            case .recent: return "clock"
            case .favorites: return "star"
            case .quickAdd: return "plus.circle"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Meal type selector
                HStack {
                    Text("Meal Type:")
                        .font(.headline)

                    Picker("Meal Type", selection: $viewModel.selectedMealType) {
                        ForEach(MealType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding()
                .background(Color(.systemBackground))

                // Tab selector
                HStack(spacing: 0) {
                    ForEach(MealCreationTab.allCases, id: \.rawValue) { tab in
                        tabButton(tab: tab)
                    }
                }
                .padding(.horizontal)
                .background(Color(.systemBackground))

                Divider()

                // Tab content
                TabView(selection: $selectedTab) {
                    searchTab
                        .tag(MealCreationTab.search.rawValue)

                    recentTab
                        .tag(MealCreationTab.recent.rawValue)

                    favoritesTab
                        .tag(MealCreationTab.favorites.rawValue)

                    quickAddTab
                        .tag(MealCreationTab.quickAdd.rawValue)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                Divider()

                // Selected food items
                selectedFoodItemsSection

                // Nutrition totals
                nutritionTotalsSection
            }
            .navigationBarTitle(isEditing ? "Edit Meal" : "Add Meal", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button(isEditing ? "Save" : "Add") {
                    viewModel.saveMeal()
                    dismiss()
                }
                .disabled(viewModel.selectedFoodItems.isEmpty)
            )
            .sheet(isPresented: $viewModel.isAddingFoodItem) {
                if let foodItem = viewModel.currentFoodItem {
                    FoodItemDetailView(
                        viewModel: viewModel,
                        foodItem: foodItem
                    )
                }
            }
        }
    }

    // MARK: - Tabs

    private var searchTab: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search foods", text: $viewModel.searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: viewModel.searchQuery) { _, _ in
                        // Use Task to call the async method
                        Task {
                            await viewModel.searchFoods()
                        }
                    }

                Button(action: {
                    viewModel.searchQuery = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .opacity(viewModel.searchQuery.isEmpty ? 0 : 1)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()

            // Camera and barcode scanner buttons
            HStack {
                scannerButton(icon: "camera", title: "Take Photo") {
                    // Show camera
                    showScanner = true
                }

                scannerButton(icon: "barcode.viewfinder", title: "Scan Barcode") {
                    // Show barcode scanner
                    showScanner = true
                }
            }
            .padding(.horizontal)

            // Search results or empty state
            if viewModel.searchQuery.isEmpty {
                searchEmptyState
            } else if viewModel.searchResults.isEmpty {
                noResultsView
            } else {
                searchResultsList
            }

            Spacer()
        }
    }

    private var recentTab: some View {
        Group {
            if viewModel.recentFoods.isEmpty {
                emptyStateView(
                    icon: "clock",
                    title: "No Recent Foods",
                    message: "Foods you log will appear here for quick access"
                )
            } else {
                foodItemListView(items: viewModel.recentFoods)
            }
        }
    }

    private var favoritesTab: some View {
        Group {
            if viewModel.favoriteFoods.isEmpty {
                emptyStateView(
                    icon: "star",
                    title: "No Favorite Foods",
                    message: "Star foods to save them as favorites for easy access"
                )
            } else {
                foodItemListView(items: viewModel.favoriteFoods)
            }
        }
    }

    private var quickAddTab: some View {
        VStack(spacing: 20) {
            Text("Quickly add nutrition without searching for a specific food")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top)

            // Quick add form
            VStack(spacing: 15) {
                quickAddField(title: "Calories", value: $viewModel.quickAddCalories, unit: "cal")

                quickAddField(title: "Carbs", value: $viewModel.quickAddCarbs, unit: "g")

                quickAddField(title: "Protein", value: $viewModel.quickAddProtein, unit: "g")

                quickAddField(title: "Fat", value: $viewModel.quickAddFat, unit: "g")
            }
            .padding()

            Button(action: {
                viewModel.quickAddFoodItem()
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add to Meal")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            isQuickAddValid
                                ? Color.accentColor
                                : Color(.systemGray4)
                        )
                )
                .foregroundColor(.white)
            }
            .disabled(!isQuickAddValid)
            .padding(.horizontal)

            Spacer()
        }
    }

    // MARK: - Sections

    private var selectedFoodItemsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Selected Foods")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.selectedFoodItems.count) items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 10)

            if viewModel.selectedFoodItems.isEmpty {
                Text("No foods added yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                List {
                    ForEach(viewModel.selectedFoodItems) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.subheadline)

                                Text(item.servingSize)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("\(Int(item.totalCalories)) cal")
                                    .font(.subheadline)

                                Text("\(String(format: "%.1f", item.servingQuantity)) serving")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                viewModel.startEditingFoodItem(item)
                            }) {
                                Label("Edit Portion", systemImage: "pencil")
                            }

                            Button(role: .destructive, action: {
                                if let index = viewModel.selectedFoodItems.firstIndex(where: { $0.id == item.id }) {
                                    viewModel.removeFoodItem(at: IndexSet(integer: index))
                                }
                            }) {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete { indices in
                        viewModel.removeFoodItem(at: indices)
                    }
                }
                .frame(height: 150)
                .listStyle(PlainListStyle())
            }
        }
    }

    private var nutritionTotalsSection: some View {
        VStack {
            HStack {
                nutritionTotalItem(title: "Calories", value: "\(Int(totalCalories))")

                nutritionTotalItem(title: "Carbs", value: "\(Int(totalCarbs))g")

                nutritionTotalItem(title: "Protein", value: "\(Int(totalProtein))g")

                nutritionTotalItem(title: "Fat", value: "\(Int(totalFat))g")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
        }
    }

    // MARK: - Helper Views

    private func tabButton(tab: MealCreationTab) -> some View {
        Button(action: {
            withAnimation {
                selectedTab = tab.rawValue
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18))

                Text(tab.title)
                    .font(.caption)
            }
            .foregroundColor(selectedTab == tab.rawValue ? .accentColor : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .background(
            selectedTab == tab.rawValue ?
                Rectangle()
                .fill(Color.accentColor)
                .frame(height: 3)
                .offset(y: 20) : nil
        )
    }

    private func scannerButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)

                Text(title)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
                    .background(Color(.systemGray6).opacity(0.5).cornerRadius(10))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var searchEmptyState: some View {
        emptyStateView(
            icon: "magnifyingglass",
            title: "Search for Foods",
            message: "Enter a food name, brand, or description to search"
        )
    }

    private var noResultsView: some View {
        emptyStateView(
            icon: "exclamationmark.circle",
            title: "No Results Found",
            message: "Try searching with different keywords"
        )
    }

    private var searchResultsList: some View {
        foodItemListView(items: viewModel.searchResults)
    }

    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 15) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    private func foodItemListView(items: [FoodItem]) -> some View {
        List {
            ForEach(items) { item in
                Button(action: {
                    viewModel.currentFoodItem = item
                    viewModel.isAddingFoodItem = true
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.subheadline)

                            Text(item.servingSize)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("\(Int(item.calories)) cal")
                                .font(.subheadline)

                            Text("C: \(Int(item.carbs))g • P: \(Int(item.protein))g • F: \(Int(item.fat))g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }

    private func quickAddField(title: String, value: Binding<String>, unit: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .frame(width: 80, alignment: .leading)

            TextField("0", text: value)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Text(unit)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 25, alignment: .leading)
        }
    }

    private func nutritionTotalItem(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties

    private var totalCalories: Double {
        viewModel.selectedFoodItems.reduce(0) { $0 + $1.totalCalories }
    }

    private var totalCarbs: Double {
        viewModel.selectedFoodItems.reduce(0) { $0 + $1.totalCarbs }
    }

    private var totalProtein: Double {
        viewModel.selectedFoodItems.reduce(0) { $0 + $1.totalProtein }
    }

    private var totalFat: Double {
        viewModel.selectedFoodItems.reduce(0) { $0 + $1.totalFat }
    }

    private var isQuickAddValid: Bool {
        guard
            let calories = Double(viewModel.quickAddCalories),
            let carbs = Double(viewModel.quickAddCarbs),
            let protein = Double(viewModel.quickAddProtein),
            let fat = Double(viewModel.quickAddFat)
        else { return false }

        return calories > 0 || carbs > 0 || protein > 0 || fat > 0
    }
}

#Preview {
    // Create a ModelContext for preview
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Meal.self, FoodItem.self, configurations: config)

    // Create a viewModel with the context
    let viewModel = MealViewModel(modelContext: container.mainContext)

    return AddMealView(viewModel: viewModel, isEditing: false)
}
