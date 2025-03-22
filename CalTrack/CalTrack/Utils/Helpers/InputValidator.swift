//
//  InputValidator.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation

/// Comprehensive input validation utility for CalTrack
public enum InputValidator {
    /// Validates email address
    /// - Parameter email: Email string to validate
    /// - Returns: Boolean indicating if email is valid
    public static func validateEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validates password strength
    /// - Parameters:
    ///   - password: Password string to validate
    ///   - minLength: Minimum password length (default 8)
    /// - Returns: Password validation result
    public static func validatePassword(_ password: String, minLength: Int = 8) -> PasswordValidationResult {
        var result = PasswordValidationResult()
        
        result.meetsLengthRequirement = password.count >= minLength
        result.hasUppercaseLetter = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        result.hasLowercaseLetter = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        result.hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        result.hasSpecialCharacter = password.rangeOfCharacter(from: .symbols) != nil
        
        return result
    }
    
    /// Validates calorie input
    /// - Parameters:
    ///   - calories: Calorie value to validate
    ///   - maxCalories: Maximum allowed calories (default 5000)
    /// - Returns: Boolean indicating if calorie input is valid
    public static func validateCalories(_ calories: String, maxCalories: Int = 5000) -> Bool {
        guard let calorieValue = Double(calories) else { return false }
        return calorieValue >= 0 && calorieValue <= Double(maxCalories)
    }
    
    /// Validates weight input
    /// - Parameters:
    ///   - weight: Weight value to validate
    ///   - minWeight: Minimum allowed weight (default 20)
    ///   - maxWeight: Maximum allowed weight (default 300)
    /// - Returns: Boolean indicating if weight input is valid
    public static func validateWeight(_ weight: String, minWeight: Double = 20, maxWeight: Double = 300) -> Bool {
        guard let weightValue = Double(weight) else { return false }
        return weightValue >= minWeight && weightValue <= maxWeight
    }
    
    /// Validates height input
    /// - Parameters:
    ///   - height: Height value to validate
    ///   - minHeight: Minimum allowed height in cm (default 100)
    ///   - maxHeight: Maximum allowed height in cm (default 250)
    /// - Returns: Boolean indicating if height input is valid
    public static func validateHeight(_ height: String, minHeight: Double = 100, maxHeight: Double = 250) -> Bool {
        guard let heightValue = Double(height) else { return false }
        return heightValue >= minHeight && heightValue <= maxHeight
    }
}

/// Represents the result of password validation
public struct PasswordValidationResult {
    /// Indicates if password meets minimum length requirement
    public var meetsLengthRequirement: Bool = false
    
    /// Indicates if password contains an uppercase letter
    public var hasUppercaseLetter: Bool = false
    
    /// Indicates if password contains a lowercase letter
    public var hasLowercaseLetter: Bool = false
    
    /// Indicates if password contains a number
    public var hasNumber: Bool = false
    
    /// Indicates if password contains a special character
    public var hasSpecialCharacter: Bool = false
    
    /// Checks if the password passes all validation checks
    public var isValid: Bool {
        return meetsLengthRequirement &&
               hasUppercaseLetter &&
               hasLowercaseLetter &&
               hasNumber &&
               hasSpecialCharacter
    }
    
    /// Provides a detailed explanation of password requirements
    public var validationMessages: [String] {
        var messages: [String] = []
        
        if !meetsLengthRequirement {
            messages.append("Password must be at least 8 characters long")
        }
        if !hasUppercaseLetter {
            messages.append("Password must contain an uppercase letter")
        }
        if !hasLowercaseLetter {
            messages.append("Password must contain a lowercase letter")
        }
        if !hasNumber {
            messages.append("Password must contain a number")
        }
        if !hasSpecialCharacter {
            messages.append("Password must contain a special character")
        }
        
        return messages
    }
}
