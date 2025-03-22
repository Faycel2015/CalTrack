//
//  GoalsSelectionView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct GoalsSelectionView: View {
    @Binding var activityLevel: ActivityLevel
    @Binding var weightGoal: WeightGoal
    
    var onSelectionChanged: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            // Activity Level Section
            VStack(alignment: .leading, spacing: 15) {
                Text("Activity Level")
                    .font(.headline)
                
                ForEach(ActivityLevel.allCases) { level in
                    activityLevelButton(level: level)
                }
            }
            
            Divider()
            
            // Weight Goal Section
            VStack(alignment: .leading, spacing: 15) {
                Text("Weight Goal")
                    .font(.headline)
                
                ForEach(WeightGoal.allCases) { goal in
                    weightGoalButton(goal: goal)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .animation(.default, value: activityLevel)
        .animation(.default, value: weightGoal)
    }
    
    // Activity Level Button
    private func activityLevelButton(level: ActivityLevel) -> some View {
        Button(action: {
            activityLevel = level
            onSelectionChanged?()
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(level.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(activityLevelDescription(for: level))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: activityLevel == level ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(activityLevel == level ? .accentColor : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(activityLevel == level ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            )
        }
    }
    
    // Weight Goal Button
    private func weightGoalButton(goal: WeightGoal) -> some View {
        Button(action: {
            weightGoal = goal
            onSelectionChanged?()
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(goal.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(weightGoalDescription(for: goal))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: weightGoal == goal ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(weightGoal == goal ? .accentColor : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(weightGoal == goal ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            )
        }
    }
    
    // Description for Activity Levels
    private func activityLevelDescription(for level: ActivityLevel) -> String {
        switch level {
        case .sedentary:
            return "Little to no exercise, desk job"
        case .light:
            return "Light exercise 1-3 days per week"
        case .moderate:
            return "Moderate exercise 3-5 days per week"
        case .active:
            return "Hard exercise 6-7 days per week"
        case .veryActive:
            return "Very hard exercise & physical job"
        }
    }
    
    // Description for Weight Goals
    private func weightGoalDescription(for goal: WeightGoal) -> String {
        switch goal {
        case .lose:
            return "Create a 500 calorie daily deficit"
        case .maintain:
            return "Keep your current weight stable"
        case .gain:
            return "Create a 500 calorie daily surplus"
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var activityLevel = ActivityLevel.moderate
        @State private var weightGoal = WeightGoal.maintain
        
        var body: some View {
            GoalsSelectionView(
                activityLevel: $activityLevel,
                weightGoal: $weightGoal
            )
            .padding()
        }
    }
    
    return PreviewWrapper()
}
