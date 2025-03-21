//
//  MealType.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

// Enum for meal types
enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "sunset"
        case .snack: return "apple"
        case .other: return "fork.knife"
        }
    }
    
    var color: String {
        switch self {
        case .breakfast: return "breakfast-color" // Define in asset catalog
        case .lunch: return "lunch-color"
        case .dinner: return "dinner-color"
        case .snack: return "snack-color"
        case .other: return "other-meal-color"
        }
    }
}
