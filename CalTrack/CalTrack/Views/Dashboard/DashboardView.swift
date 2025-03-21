//
//  DashboardView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

// Dashboard View - Shows today's summary
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    
    // States
        @State private var showMacroTracking = false
        @State private var showAddMeal = false
        @State private var mockCalorieIntake: Double = 1650
        @State private var selectedDate: Date = Date()
    
    var body: some View {
        NavigationView {
            if let profile = userProfiles.first {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header with greeting
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Hello, \(profile.name)")
                                    .font(.title2.bold())
                                
                                Text("Here's your daily summary")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Today's date
                            Text(Date().formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )
                        }
                        .padding(.horizontal)
                        
                        // Calories remaining card
                        VStack {
                            HStack {
                                Text("Calories Remaining")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: {
                                    // Action to log food
                                }) {
                                    Label("Add Food", systemImage: "plus.circle.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            
                            HStack(alignment: .firstTextBaseline) {
                                Text("\(Int(profile.dailyCalorieGoal))")
                                    .font(.system(size: 36, weight: .bold))
                                
                                Text("cal")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, -4)
                                
                                Spacer()
                            }
                            
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemGray6))
                                        .frame(height: 20)
                                    
                                    // Mock data - would be calculated from actual food entries
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.accentColor)
                                        .frame(width: geometry.size.width * 0.3, height: 20)
                                }
                            }
                            .frame(height: 20)
                            
                            // Calorie breakdown
                            HStack {
                                calorieBreakdownItem(
                                    title: "Goal",
                                    value: "\(Int(profile.dailyCalorieGoal))",
                                    color: .green
                                )
                                
                                Divider()
                                    .frame(height: 40)
                                
                                // Mock data - would be calculated from actual food entries
                                calorieBreakdownItem(
                                    title: "Food",
                                    value: "637",
                                    color: .blue
                                )
                                
                                Divider()
                                    .frame(height: 40)
                                
                                // Mock data
                                calorieBreakdownItem(
                                    title: "Remaining",
                                    value: "\(Int(profile.dailyCalorieGoal) - 637)",
                                    color: .orange
                                )
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
                        
                        // Macros progress
                        VStack {
                            HStack {
                                Text("Macros")
                                    .font(.headline)
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 15) {
                                // Mock data - would be calculated from actual food entries
                                macroProgressCircle(
                                    title: "Carbs",
                                    consumed: 83,
                                    goal: Int(profile.carbGoalGrams),
                                    color: .blue
                                )
                                
                                macroProgressCircle(
                                    title: "Protein",
                                    consumed: 45,
                                    goal: Int(profile.proteinGoalGrams),
                                    color: .green
                                )
                                
                                macroProgressCircle(
                                    title: "Fat",
                                    consumed: 22,
                                    goal: Int(profile.fatGoalGrams),
                                    color: .yellow
                                )
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
                        
                        // Recent meals
                        VStack {
                            HStack {
                                Text("Recent Meals")
                                    .font(.headline)
                                
                                Spacer()
                                
                                NavigationLink(destination: Text("All Meals")) {
                                    Text("See All")
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            
                            // Mock data - would be replaced with actual meal entries
                            ForEach(["Breakfast", "Lunch"], id: \.self) { meal in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(meal)
                                            .font(.headline)
                                        
                                        Text(meal == "Breakfast" ? "8:30 AM" : "12:45 PM")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text(meal == "Breakfast" ? "385 cal" : "552 cal")
                                            .font(.headline)
                                        
                                        Text(meal == "Breakfast" ? "C: 45g • P: 22g • F: 12g" : "C: 68g • P: 32g • F: 18g")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6).opacity(0.5))
                                .cornerRadius(10)
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
                    .padding(.vertical)
                }
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarItems(
                    trailing: Button(action: {
                        // Calendar or date picker action
                    }) {
                        Image(systemName: "calendar")
                            .font(.headline)
                    }
                )
            } else {
                VStack {
                    Text("No Profile Found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Button("Create Profile") {
                        showOnboarding = true
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView(modelContext: modelContext)
                }
            }
        }
    }
    
    // Helper view for calorie breakdown
    private func calorieBreakdownItem(title: String, value: String, color: Color) -> some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    // Helper view for macro progress circles
    private func macroProgressCircle(title: String, consumed: Int, goal: Int, color: Color) -> some View {
        let progress = min(Double(consumed) / Double(max(1, goal)), 1.0)
        
        return VStack {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 10)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, lineWidth: 10)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("\(consumed)g")
                        .font(.system(size: 16, weight: .bold))
                    
                    Text("/ \(goal)g")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}


#Preview {
    DashboardView()
}
