//
//  ActivityLevel.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

/// Enum representing different activity levels for calculating TDEE
public enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary = "Sedentary (little or no exercise)"
    case light = "Lightly active (light exercise 1-3 days/week)"
    case moderate = "Moderately active (moderate exercise 3-5 days/week)"
    case active = "Active (hard exercise 6-7 days/week)"
    case veryActive = "Very active (very hard exercise & physical job)"
    
    public var id: String { self.rawValue }
    
    /// TDEE multiplier for this activity level
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }
    
    /// Short description of the activity level
    var shortDescription: String {
        switch self {
        case .sedentary:
            return "Little to no regular exercise, mostly sitting activities"
        case .light:
            return "Light exercise or sports 1-3 days per week"
        case .moderate:
            return "Moderate exercise or sports 3-5 days per week"
        case .active:
            return "Hard exercise or sports 6-7 days per week"
        case .veryActive:
            return "Very hard daily exercise/sports and physical job or training twice daily"
        }
    }
    
    /// Examples of activities for this level
    var examples: [String] {
        switch self {
        case .sedentary:
            return ["Office work with minimal movement", "Driving", "Watching TV", "Reading"]
        case .light:
            return ["Walking 1-3 days a week", "Light housework", "Golf", "Casual cycling"]
        case .moderate:
            return ["Jogging 3-5 days a week", "Recreational swimming", "Dancing", "Hiking"]
        case .active:
            return ["Running 6-7 days a week", "Intense gym training", "Team sports", "Construction work"]
        case .veryActive:
            return ["Professional athlete", "Very hard manual labor", "Training twice daily", "Marathon training"]
        }
    }
    
    /// Recommended protein intake (g per kg bodyweight) for this activity level
    var recommendedProteinIntake: Double {
        switch self {
        case .sedentary: return 0.8  // 0.8g per kg for sedentary individuals
        case .light: return 1.0      // 1.0g per kg for light activity
        case .moderate: return 1.2    // 1.2g per kg for moderate activity
        case .active: return 1.6      // 1.6g per kg for active individuals
        case .veryActive: return 2.0  // 2.0g per kg for very active individuals
        }
    }
}
