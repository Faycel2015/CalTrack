//
//  ViewExtensions.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

// MARK: - View Styling Extensions
extension View {
    /// Applies a standard card-like appearance to the view
    func cardStyle(backgroundColor: Color = AppColors.primaryBackground) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(AppDimensions.CornerRadius.medium)
            .shadow(color: .black.opacity(AppDimensions.Shadow.light), radius: 2, x: 0, y: 1)
    }
    
    /// Adds a standard button style with consistent padding and corner radius
    func primaryButtonStyle(backgroundColor: Color = AppColors.primaryGreen) -> some View {
        self
            .frame(height: AppDimensions.Size.buttonHeight)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(AppDimensions.CornerRadius.medium)
            .font(AppFonts.Button.primary())
    }
    
    /// Applies a conditional opacity based on a disabled state
    func disableOpacity(_ disabled: Bool) -> some View {
        self.opacity(disabled ? 0.5 : 1.0)
    }
    
    /// Adds a loading indicator overlay when processing
    func loadingOverlay(_ isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryGreen))
                }
            }
        )
    }
    
    /// Adds a conditional border to the view
    func conditionalBorder(color: Color = AppColors.primaryGreen, width: CGFloat = 1, condition: Bool) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: AppDimensions.CornerRadius.medium)
                .stroke(condition ? color : Color.clear, lineWidth: width)
        )
    }
}

// MARK: - Binding Extensions
extension Binding {
    /// Creates a binding with a transformation function
    func map<T>(transform: @escaping (Value) -> T, inverse: @escaping (T) -> Value) -> Binding<T> {
        Binding<T>(
            get: { transform(self.wrappedValue) },
            set: { self.wrappedValue = inverse($0) }
        )
    }
}
