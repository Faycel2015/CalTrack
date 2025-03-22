//
//  MealType.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftUI
import SwiftData

/// Enum representing different types of meals
enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    /// System image name for the meal type
    var systemImage: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "sunset"
        case .snack: return "apple"
        case .other: return "fork.knife"
        }
    }
    
    /// Color asset name for the meal type
    var color: String {
        switch self {
        case .breakfast: return "breakfast-color" // Define in asset catalog
        case .lunch: return "lunch-color"
        case .dinner: return "dinner-color"
        case .snack: return "snack-color"
        case .other: return "other-meal-color"
        }
    }
    
    /// SwiftUI color for the meal type (fallback if asset colors not defined)
    var uiColor: Color {
        switch self {
        case .breakfast: return .blue
        case .lunch: return .green
        case .dinner: return .orange
        case .snack: return .purple
        case .other: return .gray
        }
    }
    
    /// Time range for this meal type (for suggesting meal times)
    var suggestedTimeRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        // Extract just the date part for today
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        let todayDate = calendar.date(from: todayComponents)!
        
        switch self {
        case .breakfast:
            let start = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: todayDate)!
            let end = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: todayDate)!
            return (start, end)
            
        case .lunch:
            let start = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: todayDate)!
            let end = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: todayDate)!
            return (start, end)
            
        case .dinner:
            let start = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: todayDate)!
            let end = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: todayDate)!
            return (start, end)
            
        case .snack, .other:
            // Default range for snacks and other
            let start = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: todayDate)!
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: todayDate)!
            return (start, end)
        }
    }
    
    /// Get suggested meal type based on current time
    static func suggestedTypeForCurrentTime() -> MealType {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        
        switch hour {
        case 5..<11: return .breakfast
        case 11..<15: return .lunch
        case 17..<22: return .dinner
        default: return .snack
        }
    }
}
