//
//  StringExtensions.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation

extension String {
    /// Validates if the string is a valid email address
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    /// Trims whitespace from both ends of the string
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Checks if the string is not empty after trimming
    var isNotEmpty: Bool {
        return !self.trimmed.isEmpty
    }
    
    /// Truncates the string to a specified length
    /// - Parameters:
    ///   - length: Maximum length of the string
    ///   - trailing: String to append if truncation occurs (e.g., "...")
    func truncate(to length: Int, trailing: String = "...") -> String {
        guard self.count > length else { return self }
        return String(self.prefix(length)) + trailing
    }
    
    /// Converts string to a safe filename
    var sanitizedFilename: String {
        return self.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "_")
    }
    
    /// Converts string to a formatted calorie display
    var calorieDisplay: String {
        guard let calories = Int(self) else { return "0 cal" }
        return "\(calories) cal"
    }
}

// Extension for localization and formatting
extension String {
    /// Localized string with optional comment
    /// - Parameters:
    ///   - comment: A comment for translators
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
    
    /// Formats the string as a percentage
    func percentageFormatted() -> String {
        guard let doubleValue = Double(self) else { return "0%" }
        return String(format: "%.1f%%", doubleValue * 100)
    }
}
