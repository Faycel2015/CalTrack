//
//  CustomButton.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct CustomButton: View {
    var title: String
    var icon: String?
    var style: ButtonStyle = .primary
    var size: ButtonSize = .medium
    var isFullWidth: Bool = false
    var isDisabled: Bool = false
    var action: () -> Void
    
    // Button style enum
    enum ButtonStyle {
        case primary
        case secondary
        case outline
        case destructive
        case plain
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return .accentColor
            case .secondary:
                return Color(.systemGray5)
            case .outline, .plain:
                return .clear
            case .destructive:
                return .red
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .destructive:
                return .white
            case .secondary:
                return .primary
            case .outline:
                return .accentColor
            case .plain:
                return .accentColor
            }
        }
        
        var hasBorder: Bool {
            return self == .outline
        }
    }
    
    // Button size enum
    enum ButtonSize {
        case small
        case medium
        case large
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 12
            case .large: return 16
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 24
            }
        }
        
        var font: Font {
            switch self {
            case .small: return .subheadline
            case .medium: return .body
            case .large: return .title3
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            case .large: return 12
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize))
                }
                
                Text(title)
                    .font(size.font.weight(.medium))
                    .lineLimit(1)
            }
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(style.backgroundColor.opacity(isDisabled ? 0.5 : 1.0))
            .foregroundColor(style.foregroundColor.opacity(isDisabled ? 0.6 : 1.0))
            .cornerRadius(size.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(style.hasBorder ? style.foregroundColor : .clear, lineWidth: 1.5)
            )
        }
        .disabled(isDisabled)
    }
}

// Convenience initializers
extension CustomButton {
    static func primary(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> CustomButton {
        CustomButton(
            title: title,
            icon: icon,
            style: .primary,
            size: size,
            isFullWidth: isFullWidth,
            isDisabled: isDisabled,
            action: action
        )
    }
    
    static func secondary(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> CustomButton {
        CustomButton(
            title: title,
            icon: icon,
            style: .secondary,
            size: size,
            isFullWidth: isFullWidth,
            isDisabled: isDisabled,
            action: action
        )
    }
    
    static func outline(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> CustomButton {
        CustomButton(
            title: title,
            icon: icon,
            style: .outline,
            size: size,
            isFullWidth: isFullWidth,
            isDisabled: isDisabled,
            action: action
        )
    }
    
    static func destructive(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> CustomButton {
        CustomButton(
            title: title,
            icon: icon,
            style: .destructive,
            size: size,
            isFullWidth: isFullWidth,
            isDisabled: isDisabled,
            action: action
        )
    }
    
    static func plain(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .medium,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> CustomButton {
        CustomButton(
            title: title,
            icon: icon,
            style: .plain,
            size: size,
            isFullWidth: false,
            isDisabled: isDisabled,
            action: action
        )
    }
}

// Preview provider
struct CustomButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Group {
                CustomButton.primary("Primary Button", icon: "plus", action: {})
                CustomButton.secondary("Secondary Button", icon: "gear", action: {})
                CustomButton.outline("Outline Button", icon: "pencil", action: {})
                CustomButton.destructive("Delete", icon: "trash", action: {})
                CustomButton.plain("Plain Button", icon: "info.circle", action: {})
            }
            
            Divider()
            
            Group {
                CustomButton.primary("Small Primary", size: .small, action: {})
                CustomButton.primary("Medium Primary", size: .medium, action: {})
                CustomButton.primary("Large Primary", size: .large, action: {})
            }
            
            Divider()
            
            Group {
                CustomButton.primary("Full Width", isFullWidth: true, action: {})
                CustomButton.primary("Disabled Button", isDisabled: true, action: {})
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
