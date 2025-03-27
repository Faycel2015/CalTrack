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
        case .snack: return "apple.logo"
        case .other: return "fork.knife"
        }
    }
    
    /// Color for the meal type from AppColors
    var color: Color {
        switch self {
        case .breakfast: return AppColors.breakfastColor
        case .lunch: return AppColors.lunchColor
        case .dinner: return AppColors.dinnerColor
        case .snack: return AppColors.snackColor
        case .other: return AppColors.otherMealColor
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
        case 5..<10: return .breakfast
        case 10..<14: return .lunch
        case 14..<16: return .snack
        case 16..<21: return .dinner
        default: return .snack
        }
    }
}
