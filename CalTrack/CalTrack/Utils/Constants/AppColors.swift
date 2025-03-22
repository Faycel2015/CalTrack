//
//  AppColors.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

/// A centralized color palette for the CalTrack application
public enum AppColors {
    // Primary colors
    public static let primaryGreen = Color(hex: "#4CAF50")
    public static let primaryBackground = Color(hex: "#F5F5F5")
    
    // Accent colors
    public static let accentBlue = Color(hex: "#2196F3")
    public static let accentRed = Color(hex: "#F44336")
    
    // Text colors
    public static let primaryText = Color(hex: "#333333")
    public static let secondaryText = Color(hex: "#666666")
    
    // Nutrition category colors
    public static let proteinColor = Color(hex: "#FF9800")
    public static let carbColor = Color(hex: "#2196F3")
    public static let fatColor = Color(hex: "#9C27B0")
}

// Extension to allow hex color initialization
extension Color {
    /// Initialize a Color from a hex string
    /// - Parameter hex: A hex color string (with or without #)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
