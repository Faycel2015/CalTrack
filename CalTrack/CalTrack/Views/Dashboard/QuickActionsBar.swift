//
//  QuickActionsBar.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct QuickActionsBar: View {
    // Actions
    let onLogWaterTapped: () -> Void
    let onLogExerciseTapped: () -> Void
    let onFoodScannerTapped: () -> Void
    let onMealPlanTapped: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                quickActionButton(
                    title: "Log Water",
                    systemImage: "drop.fill",
                    color: .blue,
                    action: onLogWaterTapped
                )
                
                quickActionButton(
                    title: "Log Exercise",
                    systemImage: "figure.walk",
                    color: .green,
                    action: onLogExerciseTapped
                )
                
                quickActionButton(
                    title: "Food Scanner",
                    systemImage: "barcode.viewfinder",
                    color: .orange,
                    action: onFoodScannerTapped
                )
                
                quickActionButton(
                    title: "Meal Plan",
                    systemImage: "fork.knife",
                    color: .purple,
                    action: onMealPlanTapped
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func quickActionButton(
        title: String,
        systemImage: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Circular icon background
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: systemImage)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                // Title
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(width: 100)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            )
        }
    }
    
    // Convenience initializer for preview
    static func sample() -> QuickActionsBar {
        QuickActionsBar(
            onLogWaterTapped: {},
            onLogExerciseTapped: {},
            onFoodScannerTapped: {},
            onMealPlanTapped: {}
        )
    }
}

#Preview {
    QuickActionsBar.sample()
        .background(Color(.systemGray6))
}
