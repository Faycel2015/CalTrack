//
//  MacroCircularIndicator.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct MacroCircularIndicator: View {
    // MARK: - Properties
    
    // Data values
    var value: Double // Current value
    var goal: Double // Target value
    var title: String // Macro title (e.g., "Carbs")
    var unit: String = "g" // Unit of measurement
    
    // Customization
    var color: Color // Primary color
    var lineWidth: CGFloat = 12
    var size: CGFloat = 120
    var animationDuration: Double = 1.0
    var showPercentage: Bool = true
    
    // Animation
    @State private var animatedProgress: Double = 0
    
    // MARK: - Computed Properties
    
    private var progress: Double {
        if goal <= 0 { return 0 }
        return min(1.0, value / goal)
    }
    
    private var percentComplete: Int {
        return Int(progress * 100)
    }
    
    private var capAmount: CGFloat {
        return lineWidth * 0.5
    }
    
    private var gradientColors: [Color] {
        // More vibrant gradients for each macro type
        switch title.lowercased() {
        case "carbs", "carbohydrates":
            return [color, color.opacity(0.7), color.opacity(0.5)]
        case "protein":
            return [color, color.opacity(0.8), color.opacity(0.6)]
        case "fat", "fats":
            return [color, color.opacity(0.7), color.opacity(0.5)]
        default:
            return [color, color.opacity(0.7)]
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            ZStack {
                // Background track
                Circle()
                    .stroke(color.opacity(0.15), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                
                // Progress track with gradient
                Circle()
                    .trim(from: 0, to: CGFloat(animatedProgress))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: gradientColors),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(360 * animatedProgress - 90)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                // Inner content
                VStack(spacing: 0) {
                    Text("\(Int(value))")
                        .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(unit)
                        .font(.system(size: size * 0.12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    if showPercentage {
                        Text("\(percentComplete)%")
                            .font(.system(size: size * 0.14, weight: .medium, design: .rounded))
                            .foregroundColor(percentComplete >= 100 ? .green : .secondary)
                            .padding(.top, 2)
                    }
                }
            }
            .frame(width: size, height: size)
            
            Text(title)
                .font(.system(size: size * 0.15, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.top, 5)
            
            Text("of \(Int(goal))\(unit)")
                .font(.system(size: size * 0.12, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) \(Int(value)) of \(Int(goal)) \(unit), \(percentComplete) percent complete")
        .onAppear {
            withAnimation(.easeOut(duration: animationDuration)) {
                animatedProgress = progress
            }
        }
        .onChange(of: value) { newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = progress
            }
        }
        .onChange(of: goal) { newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = progress
            }
        }
    }
    
    // MARK: - Initializers
    
    init(
        value: Double,
        goal: Double,
        title: String,
        unit: String = "g",
        color: Color,
        lineWidth: CGFloat = 12,
        size: CGFloat = 120,
        showPercentage: Bool = true
    ) {
        self.value = value
        self.goal = goal
        self.title = title
        self.unit = unit
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
        self.showPercentage = showPercentage
    }
}

// MARK: - Preset Styles

extension MacroCircularIndicator {
    static func carbs(value: Double, goal: Double, size: CGFloat = 120) -> MacroCircularIndicator {
        MacroCircularIndicator(
            value: value,
            goal: goal,
            title: "Carbs",
            color: .blue,
            size: size
        )
    }
    
    static func protein(value: Double, goal: Double, size: CGFloat = 120) -> MacroCircularIndicator {
        MacroCircularIndicator(
            value: value,
            goal: goal,
            title: "Protein",
            color: .green,
            size: size
        )
    }
    
    static func fat(value: Double, goal: Double, size: CGFloat = 120) -> MacroCircularIndicator {
        MacroCircularIndicator(
            value: value,
            goal: goal,
            title: "Fat",
            color: .yellow,
            size: size
        )
    }
    
    static func calories(value: Double, goal: Double, size: CGFloat = 120) -> MacroCircularIndicator {
        MacroCircularIndicator(
            value: value,
            goal: goal,
            title: "Calories",
            unit: "cal",
            color: .orange,
            size: size
        )
    }
}

// Preview Provider
struct MacroCircularIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            HStack(spacing: 20) {
                MacroCircularIndicator.carbs(value: 182, goal: 250, size: 110)
                MacroCircularIndicator.protein(value: 95, goal: 120, size: 110)
                MacroCircularIndicator.fat(value: 48, goal: 65, size: 110)
            }
            
            MacroCircularIndicator.calories(value: 1580, goal: 2000, size: 140)
            
            // Over goal example
            MacroCircularIndicator(
                value: 72,
                goal: 65,
                title: "Fat",
                color: .yellow,
                size: 100
            )
            
            // Almost complete example
            MacroCircularIndicator(
                value: 118,
                goal: 120,
                title: "Protein",
                color: .green,
                size: 100
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .previewLayout(.sizeThatFits)
    }
}

#Preview {
    MacroCircularIndicator()
}
