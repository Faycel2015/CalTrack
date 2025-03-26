//
//  ProfileView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) var modelContext // Removed private modifier
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationView {
            if viewModel.isLoading {
                ProgressView("Loading profile...")
            } else if viewModel.hasUserProfile {
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile header
                        profileHeader
                        
                        // Body metrics summary
                        metricsCard
                        
                        // Weight tracking
                        weightTrackingCard
                        
                        // Nutrition goals
                        nutritionGoalsCard
                        
                        // App settings
                        settingsCard
                        
                        // Data management
                        dataManagementCard
                    }
                    .padding(.bottom, 30)
                }
                .navigationTitle("Profile")
                .navigationBarItems(trailing:
                    Button(action: {
                        viewModel.startEditingProfile()
                    }) {
                        Text("Edit")
                    }
                )
                .refreshable {
                    viewModel.loadUserProfile()
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 70))
                        .foregroundColor(.secondary)
                    
                    Text("No Profile Found")
                        .font(.title2)
                        .foregroundColor(.primary)
                    
                    Text("Please create a profile to track your nutrition goals")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        viewModel.startEditingProfile()
                    }) {
                        Text("Create Profile")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .padding()
                .navigationTitle("Profile")
            }
        }
        .sheet(isPresented: $viewModel.showOnboarding) {
            OnboardingView(
                modelContext: modelContext, // This now works since modelContext is not private
                onComplete: {
                    viewModel.loadUserProfile()
                }
            )
        }
        .sheet(isPresented: $viewModel.showAddWeightEntry) {
            weightEntrySheet
        }
        .sheet(isPresented: $viewModel.showSettings) {
            settingsSheet
        }
        .alert(item: $viewModel.error) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 15) {
            // Profile image
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Text(viewModel.userProfile?.name.prefix(1).uppercased() ?? "?")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.accentColor)
            }
            
            // Name
            Text(viewModel.userProfile?.name ?? "")
                .font(.title2.bold())
            
            // Age and gender
            if let profile = viewModel.userProfile {
                Text("\(profile.age) years • \(profile.gender.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Metrics Card
    
    private var metricsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Body Metrics")
                .font(.headline)
            
            HStack(spacing: 20) {
                // Height
                metricItem(
                    icon: "ruler",
                    value: viewModel.formattedHeight,
                    label: "Height"
                )
                
                Divider()
                    .frame(height: 40)
                
                // Weight
                metricItem(
                    icon: "scalemass",
                    value: viewModel.formattedWeight,
                    label: "Weight"
                )
                
                Divider()
                    .frame(height: 40)
                
                // BMI
                metricItem(
                    icon: "figure",
                    value: viewModel.formattedBMI,
                    label: "BMI"
                )
            }
            
            // Fixed conditional binding issue
            if !viewModel.bmiCategory.isEmpty && viewModel.bmiCategory != "Unknown" {
                Text("BMI Category: \(viewModel.bmiCategory)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
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
    
    // MARK: - Weight Tracking Card
    
    private var weightTrackingCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Weight Tracking")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    viewModel.showAddWeightEntry = true
                }) {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            
            if !viewModel.weightHistory.isEmpty {
                VStack(spacing: 15) {
                    // Recent change summary
                    if viewModel.weightChange.value > 0 {
                        HStack {
                            Image(systemName: viewModel.weightChange.isGain ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundColor(viewModel.weightChange.isGain ? .red : .green)
                            
                            Text("\(String(format: "%.1f", viewModel.weightChange.value)) kg \(viewModel.weightChange.isGain ? "gained" : "lost") since last entry")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Weight history chart (placeholder)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                            .frame(height: 150)
                        
                        Text("Weight History Chart")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Recent entries
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Recent Entries")
                            .font(.subheadline.bold())
                        
                        Divider()
                        
                        ForEach(viewModel.weightHistory.prefix(3)) { entry in
                            HStack {
                                Text(entry.formattedDate)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(String(format: "%.1f", entry.weight)) kg")
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            } else {
                emptyStateView(
                    icon: "scalemass",
                    title: "No Weight Entries",
                    message: "Track your progress by adding weight entries"
                )
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
    
    // MARK: - Nutrition Goals Card
    
    private var nutritionGoalsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Nutrition Goals")
                .font(.headline)
            
            if let profile = viewModel.userProfile {
                VStack(spacing: 15) {
                    // Activity level and weight goal
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Activity Level")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(profile.activityLevel.rawValue)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Weight Goal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(profile.weightGoal.rawValue)
                                .font(.subheadline)
                        }
                    }
                    
                    Divider()
                    
                    // Calorie goals
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Daily Calories")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(Int(profile.dailyCalorieGoal)) cal")
                                .font(.subheadline.bold())
                        }
                        
                        calorieBreakdownView(
                            bmr: profile.bmr,
                            activityBonus: profile.tdee - profile.bmr,
                            goalAdjustment: profile.dailyCalorieGoal - profile.tdee
                        )
                    }
                    
                    Divider()
                    
                    // Macro distribution
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Macro Distribution")
                            .font(.subheadline)
                        
                        HStack(spacing: 15) {
                            macroDistributionItem(
                                title: "Carbs",
                                percentage: Int(profile.carbPercentage * 100),
                                grams: Int(profile.carbGoalGrams),
                                color: .blue
                            )
                            
                            macroDistributionItem(
                                title: "Protein",
                                percentage: Int(profile.proteinPercentage * 100),
                                grams: Int(profile.proteinGoalGrams),
                                color: .green
                            )
                            
                            macroDistributionItem(
                                title: "Fat",
                                percentage: Int(profile.fatPercentage * 100),
                                grams: Int(profile.fatGoalGrams),
                                color: .yellow
                            )
                        }
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
    }
    
    // MARK: - Settings Card
    
    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("App Settings")
                .font(.headline)
            
            Button(action: {
                viewModel.showSettings = true
            }) {
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.accentColor)
                    
                    Text("Settings & Preferences")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
            }
            
            Button(action: {
                // Open help
            }) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.accentColor)
                    
                    Text("Help & Support")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
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
    
    // MARK: - Data Management Card
    
    private var dataManagementCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Data Management")
                .font(.headline)
            
            Button(action: {
                // Export data
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.accentColor)
                    
                    Text("Export Nutrition Data")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
            }
            
            Button(action: {
                // Confirm before clearing data
                viewModel.clearAllData()
            }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                    
                    Text("Clear All Data")
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
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
    
    // MARK: - Weight Entry Sheet
    
    private var weightEntrySheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Track your progress by adding your current weight")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack {
                    TextField("Enter weight", text: $viewModel.newWeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("kg")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Button(action: {
                    viewModel.updateWeight()
                }) {
                    Text("Save Weight")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(viewModel.newWeight.isEmpty)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Add Weight Entry")
            .navigationBarItems(trailing: Button("Cancel") {
                viewModel.showAddWeightEntry = false
            })
        }
    }
    
    // MARK: - Settings Sheet
    
    private var settingsSheet: some View {
        NavigationView {
            List {
                // Theme section
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $appState.colorScheme) {
                        Text("System Default").tag(nil as ColorScheme?)
                        Text("Light").tag(ColorScheme.light as ColorScheme?)
                        Text("Dark").tag(ColorScheme.dark as ColorScheme?)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Features section
                Section(header: Text("Features")) {
                    ForEach(AppFeature.allCases) { feature in
                        HStack {
                            Image(systemName: feature.icon)
                                .foregroundColor(.accentColor)
                                .frame(width: 25)
                            
                            VStack(alignment: .leading) {
                                Text(feature.rawValue)
                                    .font(.subheadline)
                                
                                Text(feature.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { viewModel.isFeatureEnabled(feature) },
                                set: { _ in viewModel.toggleFeature(feature) }
                            ))
                        }
                    }
                }
                
                // App info section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("101")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                viewModel.showSettings = false
            })
        }
    }
    
    // MARK: - Helper Views
    
    private func metricItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func calorieBreakdownView(bmr: Double, activityBonus: Double, goalAdjustment: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("BMR (Base Metabolic Rate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(bmr)) cal")
                    .font(.caption)
            }
            
            HStack {
                Text("Activity Bonus")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("+ \(Int(activityBonus)) cal")
                    .font(.caption)
            }
            
            HStack {
                Text("\(goalAdjustment >= 0 ? "Calorie Surplus" : "Calorie Deficit")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(goalAdjustment >= 0 ? "+" : "")\(Int(goalAdjustment)) cal")
                    .font(.caption)
                    .foregroundColor(goalAdjustment >= 0 ? .green : .red)
            }
        }
    }
    
    private func macroDistributionItem(title: String, percentage: Int, grams: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(percentage)%")
                .font(.headline)
                .foregroundColor(color)
            
            Text("\(grams)g")
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
