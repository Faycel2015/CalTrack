//
//  ColorExtensions.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

extension Color {
    /// Creates a color with a brightness variation
    /// - Parameter percentage: Percentage to brighten or darken the color (positive for brighter, negative for darker)
    func adjusted(by percentage: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        let adjustedBrightness = max(0, min(1, brightness + (percentage / 100)))
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: adjustedBrightness, alpha: alpha))
    }
    
    /// Converts the color to a readable hex string
    var hexString: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let hexString = String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
        return hexString
    }
    
    /// Creates a contrasting text color based on the background color
    var contrastingTextColor: Color {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Calculate luminance
        let luminance = ((red * 299) + (green * 587) + (blue * 114)) / 1000
        
        // Return black or white based on luminance
        return luminance > 0.5 ? .black : .white
    }
    
    /// Generates a random color
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
    
    /// Creates a gradient between two colors
    func gradient(to endColor: Color, stops: Int = 5) -> [Color] {
        let startUIColor = UIColor(self)
        let endUIColor = UIColor(endColor)
        
        var components = [Color]()
        
        for step in 0..<stops {
            let progress = CGFloat(step) / CGFloat(stops - 1)
            
            var startRed: CGFloat = 0, startGreen: CGFloat = 0, startBlue: CGFloat = 0, startAlpha: CGFloat = 0
            var endRed: CGFloat = 0, endGreen: CGFloat = 0, endBlue: CGFloat = 0, endAlpha: CGFloat = 0
            
            startUIColor.getRed(&startRed, green: &startGreen, blue: &startBlue, alpha: &startAlpha)
            endUIColor.getRed(&endRed, green: &endGreen, blue: &endBlue, alpha: &endAlpha)
            
            let interpolatedRed = startRed + (endRed - startRed) * progress
            let interpolatedGreen = startGreen + (endGreen - startGreen) * progress
            let interpolatedBlue = startBlue + (endBlue - startBlue) * progress
            
            components.append(Color(red: Double(interpolatedRed),
                                    green: Double(interpolatedGreen),
                                    blue: Double(interpolatedBlue)))
        }
        
        return components
    }
}
