//
//  DateExtensions.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation

extension Date {
    /// Converts date to a formatted string
    /// - Parameter style: DateFormatter style (default is medium)
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Calculates age based on birthday
    var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: self, to: Date())
        return ageComponents.year ?? 0
    }
    
    /// Checks if the date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Checks if the date is in the past
    var isPast: Bool {
        return self < Date()
    }
    
    /// Creates a date from components
    /// - Parameters:
    ///   - year: Year
    ///   - month: Month (1-12)
    ///   - day: Day of the month
    static func from(year: Int, month: Int, day: Int) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        
        return Calendar.current.date(from: dateComponents)
    }
    
    /// Returns start of the day
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// Returns end of the day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    /// Formats date for nutrition tracking (e.g., "Mon, 22 Mar")
    var nutritionFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter.string(from: self)
    }
    
    /// Calculates days between two dates
    func daysBetween(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: date)
        return abs(components.day ?? 0)
    }
}

// Extension for date calculations specific to CalTrack
extension Date {
    /// Checks if a date is within the current week
    var isInCurrentWeek: Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// Returns an array of dates for the current week
    var currentWeekDates: [Date] {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else {
            return []
        }
        
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
    }
}
