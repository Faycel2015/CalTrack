//
//  NotificationManager.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import UserNotifications

/// Manages push and local notifications for CalTrack
public class NotificationManager {
    /// Singleton instance
    public static let shared = NotificationManager()
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Notification categories for different types of alerts
    public enum NotificationCategory: String {
        case dailyGoal = "DAILY_GOAL_CATEGORY"
        case mealReminder = "MEAL_REMINDER_CATEGORY"
        case waterIntake = "WATER_INTAKE_CATEGORY"
        case weightTracking = "WEIGHT_TRACKING_CATEGORY"
    }
    
    /// Requests notification permissions
    public func requestPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Logger.shared.logError(error, context: "Notification Permission Request")
            }
            
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// Schedules a daily goal reminder notification
    /// - Parameters:
    ///   - time: Time for the notification
    ///   - title: Notification title
    ///   - body: Notification body message
    public func scheduleDailyGoalReminder(at time: Date, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = NotificationCategory.dailyGoal.rawValue
        content.sound = .default
        
        // Extract time components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create and add notification request
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.shared.logError(error, context: "Daily Goal Reminder")
            }
        }
    }
    
    /// Schedules a meal reminder notification
    /// - Parameters:
    ///   - mealType: Type of meal (breakfast, lunch, dinner)
    ///   - time: Time for the meal reminder
    public func scheduleMealReminder(mealType: String, at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time for \(mealType)!"
        content.body = "Don't forget to log your \(mealType) and track your calories."
        content.categoryIdentifier = NotificationCategory.mealReminder.rawValue
        content.sound = .default
        
        // Extract time components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create and add notification request
        let request = UNNotificationRequest(identifier: "meal_\(mealType)_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.shared.logError(error, context: "Meal Reminder")
            }
        }
    }
}
