//
//  AppStrings.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation

/// A centralized collection of localized strings for the CalTrack application
public enum AppStrings {
    // MARK: - General
    public static let appName = NSLocalizedString("CalTrack", comment: "The name of the application")
    public static let ok = NSLocalizedString("OK", comment: "Confirmation button")
    public static let cancel = NSLocalizedString("Cancel", comment: "Cancellation button")
    
    // MARK: - Onboarding
    public enum Onboarding {
        public static let welcome = NSLocalizedString("Welcome to CalTrack", comment: "Onboarding welcome message")
        public static let getStarted = NSLocalizedString("Get Started", comment: "Button to begin using the app")
    }
    
    // MARK: - Nutrition Tracking
    public enum Nutrition {
        public static let dailyGoal = NSLocalizedString("Daily Calorie Goal", comment: "Title for daily calorie goal")
        public static let addMeal = NSLocalizedString("Add Meal", comment: "Button to add a new meal")
        public static let foodDiary = NSLocalizedString("Food Diary", comment: "Title for food tracking section")
    }
    
    // MARK: - Profile
    public enum Profile {
        public static let editProfile = NSLocalizedString("Edit Profile", comment: "Button to edit user profile")
        public static let height = NSLocalizedString("Height", comment: "User's height")
        public static let weight = NSLocalizedString("Weight", comment: "User's weight")
    }
    
    // MARK: - Errors
    public enum Errors {
        public static let genericError = NSLocalizedString("An error occurred", comment: "Generic error message")
        public static let networkError = NSLocalizedString("Network connection failed", comment: "Network error message")
    }
}
