//
//  WaterLogView.swift
//  CalTrack
//
//  Created by FayTek on 4/9/25.
//

import SwiftUI
import SwiftData

struct WaterLogView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = WaterLogViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Daily progress card
                    dailyProgressCard
                    
                    // Quick add buttons
                    quickAddSection
                    
                    // Custom amount slider
                    customAmountSection
                    
                    // Today's entries
                    todayEntriesSection
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Water Tracking")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    viewModel.logWater()
                }
                .disabled(viewModel.waterAmount <= 0)
            )
            .onAppear {
                viewModel.loadWaterSummary()
            }
            .alert(isPresented: $viewModel.showingConfirmation) {
                Alert(
                    title: Text("Water Added"),
                    message: Text("Successfully logged \(Int(viewModel.waterAmount)) \(viewModel.selectedUnit.rawValue) of water."),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                    }
                )
            }
            .alert(item: $viewModel.error) { error in
                Alert(
                    title: Text("Error"),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Sections
    
    private var dailyProgressCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(viewModel.dailyTotal)) / \(Int(viewModel.dailyGoal)) ml")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.accentBlue.opacity(0.2))
                        .frame(height: 20)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.accentBlue)
                        .frame(width: min(CGFloat(viewModel.dailyTotal) / CGFloat(viewModel.dailyGoal) * geometry.size.width, geometry.size.width), height: 20)
                }
            }
            .frame(height: 20)
            
            // Goal percentage
            Text("\(Int(viewModel.dailyTotal / viewModel.dailyGoal * 100))% of daily goal")
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
    
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Quick Add")
                .font(.headline)
            
            HStack(spacing: 10) {
                quickAddButton(amount: 100, unit: .ml)
                quickAddButton(amount: 250, unit: .ml)
                quickAddButton(amount: 500, unit: .ml)
                quickAddButton(amount: 1000, unit: .ml)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var customAmountSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Custom Amount")
                .font(.headline)
            
            VStack(spacing: 10) {
                // Current amount display
                HStack {
                    Spacer()
                    
                    Text("\(Int(viewModel.waterAmount))")
                        .font(.system(size: 36, weight: .bold))
                    
                    Picker("Unit", selection: $viewModel.selectedUnit) {
                        ForEach(WaterUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 100)
                    
                    Spacer()
                }
                
                // Slider
                Slider(
                    value: $viewModel.waterAmount,
                    in: 0...1000,
                    step: 50
                )
                .tint(AppColors.accentBlue)
                
                // Stepper for fine adjustments
                Stepper("Adjust Amount", value: $viewModel.waterAmount, in: 0...1000, step: 50)
                    .labelsHidden()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var todayEntriesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Today's Entries")
                .font(.headline)
            
            if viewModel.waterHistory.isEmpty {
                emptyStateView
            } else {
                ForEach(viewModel.waterHistory) { entry in
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(AppColors.accentBlue)
                        
                        Text("\(Int(entry.amount)) \(entry.unit.rawValue)")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(viewModel.timeFormatter.string(from: entry.timestamp))
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
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "drop.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No Water Logged Today")
                .font(.headline)
            
            Text("Start tracking your water intake")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Helper Views
    
    private func quickAddButton(amount: Double, unit: WaterUnit) -> some View {
        Button(action: {
            viewModel.setWaterAmount(amount: amount, unit: unit)
        }) {
            VStack(spacing: 8) {
                Image(systemName: "drop.fill")
                    .font(.title3)
                    .foregroundColor(AppColors.accentBlue)
                
                Text("\(Int(amount))")
                    .font(.headline)
                
                Text(unit.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(viewModel.waterAmount == amount && viewModel.selectedUnit == unit ? AppColors.accentBlue.opacity(0.2) : Color(.systemGray6))
            )
        }
    }
}

// MARK: - Supporting Types

enum WaterUnit: String, CaseIterable, Identifiable {
    case ml = "ml"
    case oz = "oz"
    
    var id: String { self.rawValue }
}

struct WaterEntry: Identifiable {
    let id: UUID
    let amount: Double
    let unit: WaterUnit
    let timestamp: Date
}

#Preview {
    WaterLogView()
        .environmentObject(AppState())
}
