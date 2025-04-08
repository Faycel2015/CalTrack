//
//  FoodSearchView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct FoodSearchView: View {
    // MARK: - Properties
    @StateObject private var viewModel = FoodSearchViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // Completion handler for selected food item
    var onFoodItemSelected: ((FoodItem) -> Void)?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Segmented Control for Search Type
                searchTypeSegment
                
                // Search Results or Content
                searchResultsContent
            }
            .navigationTitle("Find Food")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search foods, brands, categories", text: $viewModel.searchQuery)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: viewModel.searchQuery) { oldValue, newValue in
                    viewModel.searchFoods()
                }
            
            if !viewModel.searchQuery.isEmpty {
                Button(action: {
                    viewModel.searchQuery = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
    }
    
    // MARK: - Search Type Segment
    private var searchTypeSegment: some View {
        Picker("Search Type", selection: $viewModel.searchType) {
            ForEach(FoodSearchViewModel.SearchType.allCases) { type in
                Text(type.title).tag(type)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
    
    // MARK: - Search Results Content
    private var searchResultsContent: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else if !viewModel.searchQuery.isEmpty && viewModel.searchResults.isEmpty {
                noResultsView
            } else {
                searchResultsList
            }
        }
    }
    
    // MARK: - No Results View
    private var noResultsView: some View {
        VStack(spacing: 15) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No results found")
                .font(.headline)
            
            Text("Try different keywords or check your spelling")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Search Results List
    private var searchResultsList: some View {
        List {
            // Suggested Food Categories
            if viewModel.searchQuery.isEmpty {
                suggestedCategoriesSection
            }
            
            // Search Results
            ForEach(viewModel.searchResults) { foodItem in
                Button(action: {
                    onFoodItemSelected?(foodItem)
                    dismiss()
                }) {
                    foodItemRow(foodItem)
                }
            }
            
            // Additional Search Options
            if !viewModel.searchQuery.isEmpty {
                additionalSearchOptionsSection
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Food Item Row
    private func foodItemRow(_ item: FoodItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                Text(item.servingSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(item.calories)) cal")
                    .font(.subheadline)
                
                Text("C: \(Int(item.carbs))g • P: \(Int(item.protein))g • F: \(Int(item.fat))g")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Suggested Categories Section
    private var suggestedCategoriesSection: some View {
        Section(header: Text("Suggested Categories").font(.headline)) {
            ForEach(FoodDatabase.FoodCategory.allCases) { category in
                HStack {
                    Image(systemName: category.systemImage)
                        .foregroundColor(.accentColor)
                    
                    Text(category.rawValue)
                        .font(.subheadline)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Additional Search Options Section
    private var additionalSearchOptionsSection: some View {
        Section(header: Text("More Options").font(.headline)) {
            Button(action: {
                // Open barcode scanner
            }) {
                HStack {
                    Image(systemName: "barcode.viewfinder")
                    Text("Scan Barcode")
                }
            }
            
            Button(action: {
                // Open manual food entry
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Create Custom Food")
                }
            }
        }
    }
}

// MARK: - View Model
@MainActor // Add MainActor to properly isolate UI updates
class FoodSearchViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [FoodItem] = []
    @Published var isLoading: Bool = false
    @Published var searchType: SearchType = .all
    
    enum SearchType: String, CaseIterable, Identifiable {
        case all = "All"
        case recent = "Recent"
        case favorite = "Favorite"
        
        var id: String { rawValue }
        var title: String { rawValue }
    }
    
    func searchFoods() {
        Task {
            await performSearch()
        }
    }
    
    private func performSearch() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        // Add a small delay to prevent too many searches while typing
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        switch searchType {
        case .all:
            // Use await since FoodDatabase is an actor
            searchResults = await FoodDatabase.shared.searchFoods(query: searchQuery)
        case .recent:
            // TODO: Implement recent food search
            searchResults = []
        case .favorite:
            // TODO: Implement favorite food search
            searchResults = []
        }
        
        isLoading = false
    }
}

#Preview {
    FoodSearchView()
}
