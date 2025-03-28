//
//  AppColors.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

/// A centralized color palette for the CalTrack application
public enum AppColors {
    // MARK: - Primary Colors
    
    public static let primaryGreen = Color(hex: "#4CAF50")
//    public static let primaryBackground = Color(hex: "#F5F5F5")
    
    // MARK: - Accent Colors
    
    public static let accentBlue = Color("accentBlue")
    public static let accentRed = Color("accentRed")
    
    // MARK: - Text Colors
    
    public static let primaryText = Color("primaryText")
    public static let secondaryText = Color("secondaryText")
    
    // MARK: - Macro Nutrition Colors
    
    public static let caloriesColor = Color("calories-color")
    public static let carbsColor = Color("carbs-color")
    public static let proteinColor = Color("protein-color")
    public static let fatColor = Color("fat-color")
    
    // MARK: - Meal Type Colors
    
    public static let breakfastColor = Color("breakfast-color")
    public static let lunchColor = Color("lunch-color")
    public static let dinnerColor = Color("dinner-color")
    public static let snackColor = Color("snack-color")
    public static let otherMealColor = Color("other-meal-color")
    
    // MARK: - Weight Goal Colors
    
    public static let weightLoseColor = Color("weight-lose-color")
    public static let weightMaintainColor = Color("weight-maintain-color")
    public static let weightGainColor = Color("weight-gain-color")
    
    // MARK: - Semantic Colors
    
    public static let success = Color("success")
    public static let warning = Color("warning")
    public static let error = Color("error")
    
    // MARK: - Dark Mode Variants
    
    public enum Dark {
        public static let dark = Color("dark")
        public static let light = Color("light")
    }
    
    // MARK: - UI Colors
    
    public static let launchScreenBackground = Color("launchScreenBackground")
    
    // MARK: - Improve UI Contrast & Dynamic Colors
    
    public static let primaryBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? .black : .white
    })
    
    public static let cardBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.systemGray6 : UIColor.systemBackground
    })
    
    public static let cardShadow = Color.black.opacity(0.1)
    
}

// Extension to allow hex color initialization
extension Color {
    /// Initialize a Color from a hex string
    /// - Parameter hex: A hex color string (with or without #)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1.0
        )
    }

    /// Creates a color with a brightness variation
    /// - Parameter percentage: Percentage to brighten or darken the color (positive for brighter, negative for darker)
    func adjustedBrightness(by percentage: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let adjustedBrightness = max(0, min(1, brightness + (percentage / 100)))

        return Color(UIColor(hue: hue, saturation: saturation, brightness: adjustedBrightness, alpha: alpha))
    }
}
