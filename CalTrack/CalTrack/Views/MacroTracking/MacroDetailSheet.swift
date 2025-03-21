//
//  MacroDetailSheet.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

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

#Preview {
    MacroDetailSheet()
}
