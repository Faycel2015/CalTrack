//
//  ErrorHandler.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftUI

/// Comprehensive error handling utility for CalTrack
public class ErrorHandler {
    /// Singleton instance
    public static let shared = ErrorHandler()
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Defines different error types for the application
    public enum CalTrackError: Error {
        // Network Errors
        case networkUnreachable
        case serverError(message: String)
        
        // Authentication Errors
        case invalidCredentials
        case accountLocked
        case emailNotVerified
        
        // Data Validation Errors
        case invalidInput(field: String, reason: String)
        case dataProcessingError
        
        // Storage Errors
        case storageLimitExceeded
        case dataCorruption
        
        // Nutrition Tracking Errors
        case calorieGoalExceeded
        case nutritionDataMissing
        
        // General Errors
        case unknownError
        case featureNotSupported
    }
    
    /// Handles and logs errors
    /// - Parameters:
    ///   - error: The error to handle
    ///   - context: Additional context about the error
    public func handle(_ error: Error, context: String? = nil) {
        // Log the error
        Logger.shared.logError(error, context: context)
        
        // Additional error-specific handling
        if let calTrackError = error as? CalTrackError {
            handleSpecificError(calTrackError)
        }
    }
    
    /// Handles specific CalTrack errors with custom logic
    /// - Parameter error: CalTrack-specific error
    private func handleSpecificError(_ error: CalTrackError) {
        switch error {
        case .networkUnreachable:
            showErrorAlert(title: "Network Error",
                           message: "Unable to connect to the internet. Please check your connection.")
        
        case .serverError(let message):
            showErrorAlert(title: "Server Error", message: message)
        
        case .invalidCredentials:
            showErrorAlert(title: "Login Failed",
                           message: "Invalid email or password. Please try again.")
        
        case .accountLocked:
            showErrorAlert(title: "Account Locked",
                           message: "Your account has been temporarily locked. Please reset your password.")
        
        case .emailNotVerified:
            showErrorAlert(title: "Verification Required",
                           message: "Please verify your email address to continue.")
        
        case .invalidInput(let field, let reason):
            showErrorAlert(title: "Invalid Input",
                           message: "There was an issue with \(field): \(reason)")
        
        case .calorieGoalExceeded:
            showErrorAlert(title: "Calorie Goal",
                           message: "You've exceeded your daily calorie goal. Would you like to adjust your plan?")
        
        default:
            showErrorAlert(title: "Error",
                           message: "An unexpected error occurred. Please try again.")
        }
    }
    
    /// Displays an error alert to the user
    /// - Parameters:
    ///   - title: Alert title
    ///   - message: Alert message
    private func showErrorAlert(title: String, message: String) {
        DispatchQueue.main.async {
            // In a real app, you'd use a more robust method to present alerts
            // This is a placeholder implementation
            print("🚨 Error Alert: \(title) - \(message)")
        }
    }
    
    /// Creates a user-friendly error message
    /// - Parameter error: The error to convert
    /// - Returns: A user-friendly error message
    public func userFriendlyMessage(for error: Error) -> String {
        if let calTrackError = error as? CalTrackError {
            switch calTrackError {
            case .networkUnreachable:
                return "No internet connection. Please check your network."
            case .serverError(let message):
                return message
            case .invalidCredentials:
                return "Invalid login. Please check your credentials."
            case .accountLocked:
                return "Your account is temporarily locked. Reset your password."
            case .invalidInput(let field, let reason):
                return "Invalid \(field): \(reason)"
            default:
                return "An unexpected error occurred. Please try again."
            }
        }
        
        // Fallback for non-CalTrackError types
        return error.localizedDescription
    }
    
    /// Generates a custom error from a generic error
    /// - Parameter error: The original error
    /// - Returns: A CalTrackError representation
    public func convertToCalTrackError(_ error: Error) -> CalTrackError {
        // You can add more sophisticated error conversion logic here
        if let nsError = error as NSError? {
            switch nsError.domain {
            case NSURLErrorDomain:
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet,
                     NSURLErrorTimedOut,
                     NSURLErrorCannotConnectToHost:
                    return .networkUnreachable
                default:
                    return .serverError(message: nsError.localizedDescription)
                }
            default:
                return .unknownError
            }
        }
        
        return .unknownError
    }
}

// MARK: - Error Handling Extensions

/// Extends Error to provide more convenient error handling
extension Error {
    /// Converts the error to a user-friendly message
    var userFriendlyMessage: String {
        return ErrorHandler.shared.userFriendlyMessage(for: self)
    }
    
    /// Handles the error using the shared ErrorHandler
    func handle(context: String? = nil) {
        ErrorHandler.shared.handle(self, context: context)
    }
}
