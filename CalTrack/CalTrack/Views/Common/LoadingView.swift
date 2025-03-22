//
//  LoadingView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct LoadingView: View {
    var title: String?
    var subtitle: String?
    var loadingProgress: Double?
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated loading indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryGreen))
                .scaleEffect(1.5)
            
            // Optional title and subtitle
            VStack(spacing: 8) {
                if let title = title {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            
            // Optional progress bar
            if let progress = loadingProgress {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primaryGreen))
                    .padding(.horizontal)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .transition(.opacity)
        .animation(.easeInOut, value: loadingProgress ?? 0)
    }
    
    // Convenience initializers
    static func standard() -> LoadingView {
        LoadingView(
            title: "Loading",
            subtitle: "Please wait while we prepare your data..."
        )
    }
    
    static func nutritionLoading() -> LoadingView {
        LoadingView(
            title: "Updating Nutrition",
            subtitle: "Syncing your latest meals and progress",
            loadingProgress: 0.5
        )
    }
    
    static func syncLoading() -> LoadingView {
        LoadingView(
            title: "Syncing Data",
            subtitle: "Connecting to your account and retrieving information",
            loadingProgress: 0.7
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingView.standard()
        LoadingView.nutritionLoading()
        LoadingView.syncLoading()
    }
    .background(Color(.systemGray6))
}
