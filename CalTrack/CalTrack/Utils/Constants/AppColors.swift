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
    public static let primaryBackground = Color(hex: "#F5F5F5")
    
    // MARK: - Accent Colors
    public static let accentBlue = Color(hex: "#2196F3")
    public static let accentRed = Color(hex: "#F44336")
    
    // MARK: - Text Colors
    public static let primaryText = Color(hex: "#333333")
    public static let secondaryText = Color(hex: "#666666")
    
    // MARK: - Nutrition Category Colors
    public static let proteinColor = Color(hex: "#FF9800")
    public static let carbColor = Color(hex: "#2196F3")
    public static let fatColor = Color(hex: "#9C27B0")
    
    // MARK: - Semantic Colors
    public static let success = Color(hex: "#4CAF50")
    public static let warning = Color(hex: "#FF9800")
    public static let error = Color(hex: "#F44336")
    
    // MARK: - Dark Mode Variants
    public enum Dark {
        public static let primaryBackground = Color(hex: "#121212")
        public static let secondaryBackground = Color(hex: "#1E1E1E")
    }
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
