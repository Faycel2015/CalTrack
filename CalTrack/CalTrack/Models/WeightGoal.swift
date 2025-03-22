//
//  WeightGoal.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftUI
import SwiftData

/// Enum representing different weight goals for nutrition planning
enum WeightGoal: String, Codable, CaseIterable, Identifiable {
    case lose = "Lose weight"
    case maintain = "Maintain weight"
    case gain = "Gain weight"
    
    var id: String { self.rawValue }
    
    /// Calorie adjustment to apply to TDEE to achieve this goal
    var calorieAdjustment: Double {
        switch self {
        case .lose: return -500.0  // 500 calorie deficit (approximately 1lb per week)
        case .maintain: return 0.0
        case .gain: return 500.0   // 500 calorie surplus (approximately 1lb per week)
        }
    }
    
    /// Description of the expected rate of change
    var rateDescription: String {
        switch self {
        case .lose: return "Approximately 0.5kg/1lb per week"
        case .maintain: return "No expected weight change"
        case .gain: return "Approximately 0.5kg/1lb per week"
        }
    }
    
    /// Recommended macro distribution for this goal
    var recommendedMacroDistribution: (carbs: Double, protein: Double, fat: Double) {
        switch self {
        case .lose:
            // Higher protein, moderate fat for weight loss
            return (carbs: 0.35, protein: 0.40, fat: 0.25)
        case .maintain:
            // Balanced distribution for maintenance
            return (carbs: 0.40, protein: 0.30, fat: 0.30)
        case .gain:
            // Higher carbs for weight/muscle gain
            return (carbs: 0.45, protein: 0.30, fat: 0.25)
        }
    }
    
    /// Icon for this goal
    var icon: String {
        switch self {
        case .lose: return "arrow.down.circle.fill"
        case .maintain: return "equal.circle.fill"
        case .gain: return "arrow.up.circle.fill"
        }
    }
    
    /// Color for this goal
    var color: Color {
        switch self {
        case .lose: return .blue
        case .maintain: return .green
        case .gain: return .orange
        }
    }
    
    /// Protein recommendation for this goal (g per kg bodyweight)
    var proteinRecommendation: Double {
        switch self {
        case .lose: return 1.6  // Higher protein for weight loss to preserve muscle
        case .maintain: return 1.2
        case .gain: return 1.8  // Higher protein for muscle gain
        }
    }
    
    /// Additional recommendations specific to this goal
    var additionalRecommendations: [String] {
        switch self {
        case .lose:
            return [
                "Focus on high-protein, high-fiber foods to stay fuller longer",
                "Prioritize strength training to preserve muscle mass",
                "Stay well hydrated, aim for 2-3 liters of water daily",
                "Consider intermittent fasting if it fits your lifestyle"
            ]
        case .maintain:
            return [
                "Monitor your weight regularly to ensure stability",
                "Adjust calories if you notice unintended weight shifts",
                "Focus on whole, nutrient-dense foods",
                "Maintain an active lifestyle with consistent exercise"
            ]
        case .gain:
            return [
                "Prioritize nutrient-dense, calorie-rich foods",
                "Include protein with every meal for muscle synthesis",
                "Focus on progressive resistance training",
                "Get adequate sleep (7-9 hours) for recovery and growth"
            ]
        }
    }
}
