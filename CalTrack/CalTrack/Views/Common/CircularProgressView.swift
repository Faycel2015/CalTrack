//
//  CircularProgressView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct CircularProgressView: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 10
    var size: CGFloat = 80
    var showText: Bool = true
    var text: String?
    var subText: String?
    var textFont: Font = .system(size: 16, weight: .bold)
    var subTextFont: Font = .caption2
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Foreground ring (progress)
            Circle()
                .trim(from: 0, to: min(CGFloat(progress), 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            
            // Percentage text
            if showText {
                VStack(spacing: 0) {
                    Text(text ?? "\(Int(progress * 100))%")
                        .font(textFont)
                        .foregroundColor(.primary)
                    
                    if let subText = subText {
                        Text(subText)
                            .font(subTextFont)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// Extension for different size presets
extension CircularProgressView {
    static func small(
        progress: Double,
        color: Color,
        text: String? = nil,
        subText: String? = nil
    ) -> CircularProgressView {
        CircularProgressView(
            progress: progress,
            color: color,
            lineWidth: 6,
            size: 60,
            text: text,
            subText: subText,
            textFont: .system(size: 14, weight: .bold),
            subTextFont: .caption2
        )
    }
    
    static func medium(
        progress: Double,
        color: Color,
        text: String? = nil,
        subText: String? = nil
    ) -> CircularProgressView {
        CircularProgressView(
            progress: progress,
            color: color,
            lineWidth: 10,
            size: 80,
            text: text,
            subText: subText
        )
    }
    
    static func large(
        progress: Double,
        color: Color,
        text: String? = nil,
        subText: String? = nil
    ) -> CircularProgressView {
        CircularProgressView(
            progress: progress,
            color: color,
            lineWidth: 14,
            size: 120,
            text: text,
            subText: subText,
            textFont: .system(size: 24, weight: .bold),
            subTextFont: .caption
        )
    }
}

// Preview Provider
struct CircularProgressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Small size
            HStack(spacing: 20) {
                CircularProgressView.small(progress: 0.35, color: .blue, text: "35%")
                CircularProgressView.small(progress: 0.68, color: .green, text: "68%")
                CircularProgressView.small(progress: 0.92, color: .orange, text: "92%")
            }
            
            // Medium size
            HStack(spacing: 20) {
                CircularProgressView.medium(
                    progress: 0.45,
                    color: .blue,
                    text: "45g",
                    subText: "/ 100g"
                )
                
                CircularProgressView.medium(
                    progress: 0.72,
                    color: .green,
                    text: "72g",
                    subText: "/ 100g"
                )
            }
            
            // Large size
            CircularProgressView.large(
                progress: 0.65,
                color: .purple,
                text: "1,300",
                subText: "calories"
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

#Preview {
    CircularProgressView()
}
