//
//  CardView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct CardView<Content: View>: View {
    var title: String?
    var icon: String?
    var iconColor: Color = .accentColor
    var actionLabel: String?
    var actionIcon: String?
    var onAction: (() -> Void)?
    let content: Content
    
    init(
        title: String? = nil,
        icon: String? = nil,
        iconColor: Color = .accentColor,
        actionLabel: String? = nil,
        actionIcon: String? = nil,
        onAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.actionLabel = actionLabel
        self.actionIcon = actionIcon
        self.onAction = onAction
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header (optional)
            if title != nil || icon != nil || actionLabel != nil {
                HStack {
                    // Title with optional icon
                    HStack(spacing: 8) {
                        if let icon = icon {
                            Image(systemName: icon)
                                .font(.headline)
                                .foregroundColor(iconColor)
                        }
                        
                        if let title = title {
                            Text(title)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    // Action button (optional)
                    if let actionLabel = actionLabel, let onAction = onAction {
                        Button(action: onAction) {
                            HStack(spacing: 4) {
                                Text(actionLabel)
                                    .font(.subheadline)
                                
                                if let actionIcon = actionIcon {
                                    Image(systemName: actionIcon)
                                        .font(.subheadline)
                                }
                            }
                            .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            
            // Divider (if we have a header)
            if title != nil || icon != nil || actionLabel != nil {
                Divider()
            }
            
            // Content
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// Static convenience methods
extension CardView {
    // Card with title and no action
    static func titled<C: View>(
        _ title: String,
        icon: String? = nil,
        iconColor: Color = .accentColor,
        @ViewBuilder content: () -> C
    ) -> CardView<C> {
        return CardView<C>(
            title: title,
            icon: icon,
            iconColor: iconColor,
            content: content
        )
    }
    
    // Card with title and action
    static func withAction<C: View>(
        _ title: String,
        icon: String? = nil,
        iconColor: Color = .accentColor,
        actionLabel: String,
        actionIcon: String? = "chevron.right",
        onAction: @escaping () -> Void,
        @ViewBuilder content: () -> C
    ) -> CardView<C> {
        return CardView<C>(
            title: title,
            icon: icon,
            iconColor: iconColor,
            actionLabel: actionLabel,
            actionIcon: actionIcon,
            onAction: onAction,
            content: content
        )
    }
    
    // Simple card with no header
    static func simple<C: View>(@ViewBuilder content: () -> C) -> CardView<C> {
        return CardView<C>(content: content)
    }
}

// Preview provider
struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Simple card
            CardView<Text>.simple {
                Text("This is a simple card with no header")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
            
            // Titled card
            CardView<VStack<TupleView<(Text, Text, Text)>>>.titled("Daily Summary", icon: "calendar") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Calories: 1,850 / 2,200")
                    Text("Protein: 95g / 130g")
                    Text("Steps: 7,500 / 10,000")
                }
            }
            
            // Card with action
            CardView<VStack<TupleView<(HStack<TupleView<(Text, Spacer, Text)>>, HStack<TupleView<(Text, Spacer, Text)>>)>>>.withAction(
                "Recent Meals",
                icon: "fork.knife",
                actionLabel: "See All",
                onAction: {}
            ) {
                VStack(spacing: 12) {
                    HStack {
                        Text("Breakfast")
                        Spacer()
                        Text("450 cal")
                    }
                    HStack {
                        Text("Lunch")
                        Spacer()
                        Text("620 cal")
                    }
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .previewLayout(.sizeThatFits)
    }
}
