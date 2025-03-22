//
//  ProgressSection.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct ProgressSection: View {
    // Progress data models
    struct ProgressItem {
        let title: String
        let currentValue: Double
        let goalValue: Double
        let color: Color
        let iconName: String
        let trendDirection: TrendDirection?
    }
    
    // Trend direction enum
    enum TrendDirection {
        case up, down
        
        var iconName: String {
            switch self {
            case .up: return "arrow.up.circle.fill"
            case .down: return "arrow.down.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            }
        }
    }
    
    // Progress items
    let progressItems: [ProgressItem]
    
    // Optional tap handlers
    let onItemTapped: ((String) -> Void)?
    
    // Initializer
    init(
        progressItems: [ProgressItem],
        onItemTapped: ((String) -> Void)? = nil
    ) {
        self.progressItems = progressItems
        self.onItemTapped = onItemTapped
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Section Title
            Text("Progress Tracking")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Scrollable progress cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(progressItems, id: \.title) { item in
                        progressCard(for: item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // Progress card view
    private func progressCard(for item: ProgressItem) -> some View {
        Button(action: {
            onItemTapped?(item.title)
        }) {
            VStack(alignment: .leading, spacing: 10) {
                // Card Header
                HStack {
                    // Title and Icon
                    Image(systemName: item.iconName)
                        .foregroundColor(item.color)
                        .font(.title3)
                    
                    Text(item.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Trend Indicator
                    if let trend = item.trendDirection {
                        HStack(spacing: 4) {
                            Image(systemName: trend.iconName)
                                .foregroundColor(trend.color)
                            
                            Text(trend == .up ? "+5%" : "-5%")
                                .font(.caption)
                                .foregroundColor(trend.color)
                        }
                    }
                }
                
                // Progress Visualization
                HStack(spacing: 15) {
                    // Circular Progress
                    ZStack {
                        // Background Circle
                        Circle()
                            .stroke(item.color.opacity(0.2), lineWidth: 10)
                            .frame(width: 80, height: 80)
                        
                        // Progress Circle
                        Circle()
                            .trim(from: 0, to: min(item.currentValue / item.goalValue, 1.0))
                            .stroke(
                                item.color,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        // Progress Text
                        VStack {
                            Text("\(Int(item.currentValue))")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text(progressUnitText(for: item.title))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Progress Details
                    VStack(alignment: .leading, spacing: 5) {
                        progressDetailRow(
                            title: "Current",
                            value: "\(Int(item.currentValue)) \(progressUnitText(for: item.title))",
                            color: item.color
                        )
                        
                        progressDetailRow(
                            title: "Goal",
                            value: "\(Int(item.goalValue)) \(progressUnitText(for: item.title))",
                            color: .secondary
                        )
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .frame(width: 300)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper method to get unit text
    private func progressUnitText(for title: String) -> String {
        switch title.lowercased() {
        case "calories": return "cal"
        case "weight": return "kg"
        case "exercise": return "min"
        default: return ""
        }
    }
    
    // Progress detail row
    private func progressDetailRow(title: String, value: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .foregroundColor(color)
        }
    }
    
    // Convenience initializer for sample data
    static func sample() -> ProgressSection {
        ProgressSection(
            progressItems: [
                ProgressItem(
                    title: "Calories",
                    currentValue: 1650,
                    goalValue: 2000,
                    color: .orange,
                    iconName: "flame.fill",
                    trendDirection: .down
                ),
                ProgressItem(
                    title: "Weight",
                    currentValue: 75.5,
                    goalValue: 70.0,
                    color: .purple,
                    iconName: "figure.mixed.body.weight",
                    trendDirection: .down
                ),
                ProgressItem(
                    title: "Exercise",
                    currentValue: 35,
                    goalValue: 45,
                    color: .green,
                    iconName: "figure.walk",
                    trendDirection: .up
                )
            ],
            onItemTapped: { title in
                print("Tapped on \(title) progress")
            }
        )
    }
}

#Preview {
    ProgressSection.sample()
        .background(Color(.systemGray6))
}
