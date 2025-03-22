//
//  MacroSetupView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct MacroSetupView: View {
    @Binding var carbPercentage: Double
    @Binding var proteinPercentage: Double
    @Binding var fatPercentage: Double
    
    var onMacroChanged: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title and Description
            VStack(alignment: .leading, spacing: 10) {
                Text("Macro Distribution")
                    .font(.title2.bold())
                
                Text("Adjust your macronutrient percentages to match your goals")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Macro Distribution Pie Chart
            macroDistributionChart
            
            // Macro Sliders
            VStack(spacing: 20) {
                macroSliderRow(
                    title: "Carbs",
                    percentage: $carbPercentage,
                    color: .blue
                )
                
                macroSliderRow(
                    title: "Protein",
                    percentage: $proteinPercentage,
                    color: .green
                )
                
                macroSliderRow(
                    title: "Fat",
                    percentage: $fatPercentage,
                    color: .yellow
                )
            }
            
            // Preset Distribution Buttons
            presetDistributionSection
            
            // Total Percentage Warning
            totalPercentageWarning
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // Macro Distribution Pie Chart
    private var macroDistributionChart: some View {
        ZStack {
            Circle()
                .fill(Color.clear)
                .frame(width: 250, height: 250)
                .overlay(
                    Circle()
                        .trim(from: 0, to: CGFloat(carbPercentage / 100))
                        .stroke(Color.blue, lineWidth: 40)
                )
            
            Circle()
                .fill(Color.clear)
                .frame(width: 250, height: 250)
                .overlay(
                    Circle()
                        .trim(from: CGFloat(carbPercentage / 100),
                              to: CGFloat((carbPercentage + proteinPercentage) / 100))
                        .stroke(Color.green, lineWidth: 40)
                )
            
            Circle()
                .fill(Color.clear)
                .frame(width: 250, height: 250)
                .overlay(
                    Circle()
                        .trim(from: CGFloat((carbPercentage + proteinPercentage) / 100),
                              to: 1)
                        .stroke(Color.yellow, lineWidth: 40)
                )
            
            // Macro Percentage Labels
            VStack(spacing: 5) {
                Text("\(Int(carbPercentage))%")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text("\(Int(proteinPercentage))%")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Text("\(Int(fatPercentage))%")
                    .font(.headline)
                    .foregroundColor(.yellow)
            }
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
    
    // Macro Slider Row
    private func macroSliderRow(
        title: String,
        percentage: Binding<Double>,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(percentage.wrappedValue))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Slider(
                value: percentage,
                in: 5...70,
                step: 5
            ) { changed in
                if changed {
                    normalizePercentages()
                    onMacroChanged?()
                }
            }
            .accentColor(color)
        }
    }
    
    // Preset Distribution Section
    private var presetDistributionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recommended Distributions")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    presetButton(
                        title: "Weight Loss",
                        description: "40/30/30",
                        carbs: 40,
                        protein: 30,
                        fat: 30
                    )
                    
                    presetButton(
                        title: "Muscle Gain",
                        description: "30/40/30",
                        carbs: 30,
                        protein: 40,
                        fat: 30
                    )
                    
                    presetButton(
                        title: "Balanced",
                        description: "45/25/30",
                        carbs: 45,
                        protein: 25,
                        fat: 30
                    )
                }
            }
        }
    }
    
    // Preset Distribution Button
    private func presetButton(
        title: String,
        description: String,
        carbs: Double,
        protein: Double,
        fat: Double
    ) -> some View {
        Button(action: {
            carbPercentage = carbs
            proteinPercentage = protein
            fatPercentage = fat
            
            normalizePercentages()
            onMacroChanged?()
        }) {
            VStack(spacing: 5) {
                Text(title)
                    .font(.subheadline)
                
                Text(description)
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
    
    // Total Percentage Warning
    private var totalPercentageWarning: some View {
        HStack {
            Image(systemName: totalPercentage == 100 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(totalPercentage == 100 ? .green : .red)
            
            Text("Total: \(Int(totalPercentage))%")
                .font(.subheadline)
                .foregroundColor(totalPercentage == 100 ? .green : .red)
        }
        .padding(.top, 10)
    }
    
    // Normalize percentages to always total 100%
    private func normalizePercentages() {
        let total = carbPercentage + proteinPercentage + fatPercentage
        
        if total != 100 {
            let factor = 100 / total
            carbPercentage *= factor
            proteinPercentage *= factor
            fatPercentage *= factor
        }
    }
    
    // Computed total percentage
    private var totalPercentage: Double {
        return carbPercentage + proteinPercentage + fatPercentage
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var carbPercentage: Double = 40
        @State private var proteinPercentage: Double = 30
        @State private var fatPercentage: Double = 30
        
        var body: some View {
            MacroSetupView(
                carbPercentage: $carbPercentage,
                proteinPercentage: $proteinPercentage,
                fatPercentage: $fatPercentage
            )
            .padding()
        }
    }
    
    return PreviewWrapper()
}
