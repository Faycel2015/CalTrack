//
//  AppDimensions.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

/// A centralized collection of dimension constants for the CalTrack application
public enum AppDimensions {
    // MARK: - Spacing
    public enum Spacing {
        public static let small: CGFloat = 4
        public static let medium: CGFloat = 8
        public static let large: CGFloat = 16
        public static let extraLarge: CGFloat = 24
    }
    
    // MARK: - Sizing
    public enum Size {
        public static let buttonHeight: CGFloat = 48
        public static let textFieldHeight: CGFloat = 44
        public static let iconSize: CGFloat = 24
        public static let thumbnailSize: CGFloat = 64
    }
    
    // MARK: - Corners
    public enum CornerRadius {
        public static let small: CGFloat = 4
        public static let medium: CGFloat = 8
        public static let large: CGFloat = 12
        public static let circular: CGFloat = 100
    }
    
    // MARK: - Shadows
    public enum Shadow {
        public static let light: CGFloat = 0.1
        public static let medium: CGFloat = 0.2
        public static let heavy: CGFloat = 0.3
    }
    
    // MARK: - Chart Dimensions
    public enum Chart {
        public static let height: CGFloat = 200
        public static let width: CGFloat = UIScreen.main.bounds.width - 32
    }
}
