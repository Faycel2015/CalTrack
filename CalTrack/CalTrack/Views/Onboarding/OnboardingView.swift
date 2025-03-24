//
//  OnboardingView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: UserProfileViewModel
    @State private var currentStep = 0
    @State private var showResults = false
    
    var onComplete: (() -> Void)?
    
    init(modelContext: ModelContext, onComplete: (() -> Void)? = nil) {
        let vm = UserProfileViewModel(modelContext: modelContext)
        _viewModel = State(initialValue: vm)
        self.onComplete = onComplete
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Progress header
                HStack {
                    Text("CalTrack Setup")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(currentStep + 1)/4")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                            .frame(height: 10)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * CGFloat(currentStep + 1) / 4, height: 10)
                            .animation(.easeInOut, value: currentStep)
                    }
                }
                .frame(height: 10)
                .padding(.horizontal)
                
                // Main Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Content changes based on current step
                        switch currentStep {
                        case 0:
                            PersonalInfoView(
                                name: $viewModel.name,
                                age: $viewModel.age,
                                gender: $viewModel.gender
                            )
                        case 1:
                            BodyMeasurementsView(
                                heightCm: $viewModel.heightCm,
                                weightKg: $viewModel.weightKg,
                                heightIsValid: viewModel.heightIsValid,
                                weightIsValid: viewModel.weightIsValid
                            )
                        case 2:
                            activityGoalsView
                        case 3:
                            macroSettingsView
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
                }
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 && !showResults {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    
                    Spacer()
                    
                    if showResults {
                        Button(action: {
                            dismiss()
                            onComplete?()
                        }) {
                            Text("Start Tracking")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    } else {
                        Button(action: {
                            withAnimation {
                                if currentStep < 3 {
                                    currentStep += 1
                                } else {
                                    viewModel.saveProfile()
                                    showResults = true
                                }
                            }
                        }) {
                            Text(currentStep < 3 ? "Next" : "Calculate")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .padding()
                                .background(
                                    currentStep == 0 && !isStep1Valid ||
                                    currentStep == 1 && !isStep2Valid ?
                                        Color.gray : Color.accentColor
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(
                            (currentStep == 0 && !isStep1Valid) ||
                            (currentStep == 1 && !isStep2Valid)
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showResults) {
            resultsView
        }
    }
    
    // MARK: - Step Views
    
    // Step 3: Activity & Goals
    private var activityGoalsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Activity & Goals")
                .font(.title2.bold())
                .padding(.bottom, 5)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Activity Level")
                    .font(.headline)
                
                ForEach(ActivityLevel.allCases) { level in
                    Button(action: {
                        viewModel.activityLevel = level
                    }) {
                        HStack {
                            Text(level.rawValue)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if viewModel.activityLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.activityLevel == level ?
                                      Color.accentColor.opacity(0.1) : Color(.systemGray6))
                        )
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Weight Goal")
                    .font(.headline)
                
                ForEach(WeightGoal.allCases) { goal in
                    Button(action: {
                        viewModel.weightGoal = goal
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.rawValue)
                                    .foregroundColor(.primary)
                                    .font(.subheadline.bold())
                                
                                if goal == .lose {
                                    Text("500 calorie deficit per day")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if goal == .gain {
                                    Text("500 calorie surplus per day")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Maintain current weight")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if viewModel.weightGoal == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.weightGoal == goal ?
                                      Color.accentColor.opacity(0.1) : Color(.systemGray6))
                        )
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // Step 4: Macro Settings
    private var macroSettingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Macro Distribution")
                .font(.title2.bold())
                .padding(.bottom, 5)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Adjust your macronutrient percentages")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Macro distribution pie chart preview
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 200, height: 200)
                        .overlay(
                            Circle()
                                .trim(from: 0, to: CGFloat(viewModel.carbPercentage / 100))
                                .stroke(Color.blue, lineWidth: 40)
                        )
                    
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 200, height: 200)
                        .overlay(
                            Circle()
                                .trim(from: CGFloat(viewModel.carbPercentage / 100),
                                      to: CGFloat((viewModel.carbPercentage + viewModel.proteinPercentage) / 100))
                                .stroke(Color.green, lineWidth: 40)
                        )
                    
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 200, height: 200)
                        .overlay(
                            Circle()
                                .trim(from: CGFloat((viewModel.carbPercentage + viewModel.proteinPercentage) / 100),
                                      to: 1)
                                .stroke(Color.yellow, lineWidth: 40)
                        )
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                
                // Macro sliders
                VStack(spacing: 15) {
                    macroSliderRow(
                        title: "Carbs",
                        percentage: viewModel.carbPercentage,
                        color: .blue,
                        onChange: { newValue in
                            viewModel.updateMacroPercentages(
                                carbs: newValue,
                                protein: viewModel.proteinPercentage,
                                fat: viewModel.fatPercentage
                            )
                        }
                    )
                    
                    macroSliderRow(
                        title: "Protein",
                        percentage: viewModel.proteinPercentage,
                        color: .green,
                        onChange: { newValue in
                            viewModel.updateMacroPercentages(
                                carbs: viewModel.carbPercentage,
                                protein: newValue,
                                fat: viewModel.fatPercentage
                            )
                        }
                    )
                    
                    macroSliderRow(
                        title: "Fat",
                        percentage: viewModel.fatPercentage,
                        color: .yellow,
                        onChange: { newValue in
                            viewModel.updateMacroPercentages(
                                carbs: viewModel.carbPercentage,
                                protein: viewModel.proteinPercentage,
                                fat: newValue
                            )
                        }
                    )
                }
                
                Text("Recommended: 40% carbs, 30% protein, 30% fat")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
        }
        .cardStyle()
    }
    
    // Results View (shown after setup)
    private var resultsView: some View {
        VStack(spacing: 20) {
            // Header
            VStack {
                Text("Your Results")
                    .font(.largeTitle.bold())
                
                Text("Based on your information")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Metrics Cards
            ScrollView {
                VStack(spacing: 20) {
                    // BMR Card
                    metricCard(
                        title: "Basal Metabolic Rate",
                        value: viewModel.bmrDisplay,
                        description: "Calories your body needs at complete rest",
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    // TDEE Card
                    metricCard(
                        title: "Total Daily Energy Expenditure",
                        value: viewModel.tdeeDisplay,
                        description: "Calories your body needs with your activity level",
                        icon: "figure.walk",
                        color: .blue
                    )
                    
                    // Daily Calorie Goal Card
                    metricCard(
                        title: "Daily Calorie Goal",
                        value: viewModel.dailyCalorieGoalDisplay,
                        description: "Target calories adjusted for your weight goal",
                        icon: "target",
                        color: .green
                    )
                    
                    // Macros Card
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "chart.pie.fill")
                                .font(.title2)
                                .foregroundColor(.purple)
                            
                            Text("Macro Nutrients")
                                .font(.headline)
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        HStack(spacing: 15) {
                            macroCircle(
                                title: "Carbs",
                                value: viewModel.carbGoalDisplay,
                                percentage: "\(Int(viewModel.carbPercentage))%",
                                color: .blue
                            )
                            
                            macroCircle(
                                title: "Protein",
                                value: viewModel.proteinGoalDisplay,
                                percentage: "\(Int(viewModel.proteinPercentage))%",
                                color: .green
                            )
                            
                            macroCircle(
                                title: "Fat",
                                value: viewModel.fatGoalDisplay,
                                percentage: "\(Int(viewModel.fatPercentage))%",
                                color: .yellow
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                }
                .padding()
            }
            
            // Action Button
            Button(action: {
                dismiss()
                onComplete?()
            }) {
                Text("Start Tracking")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helper Views
    
    // Macro slider row
    private func macroSliderRow(title: String, percentage: Double, color: Color, onChange: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(percentage))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Slider(value: Binding(
                    get: { percentage },
                    set: { onChange($0) }
                ), in: 5...70, step: 5)
                .accentColor(color)
            }
        }
    }
    
    // Metric Card
    private func metricCard(title: String, value: String, description: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            HStack(alignment: .top) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                
                Text("calories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // Macro Circle
    private func macroCircle(title: String, value: String, percentage: String, color: Color) -> some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 10)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .trim(from: 0, to: Double(percentage.dropLast()) ?? 0 / 100)
                    .stroke(color, lineWidth: 10)
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text(percentage)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Validation Helpers
    
    private var isStep1Valid: Bool {
        return !viewModel.name.isEmpty &&
               (Int(viewModel.age) ?? 0) >= 15 &&
               (Int(viewModel.age) ?? 0) <= 100
    }
    
    private var isStep2Valid: Bool {
        return (Double(viewModel.heightCm) ?? 0) > 0 &&
               (Double(viewModel.weightKg) ?? 0) > 0
    }
}

// MARK: - Card Style ViewModifier

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
    }
}

// Card Style extension for View
extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
}

#Preview {
    OnboardingView(modelContext: try! ModelContainer(for: UserProfile.self).mainContext)
}
