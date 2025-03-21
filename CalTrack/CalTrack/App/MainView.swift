//
//  MainView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

// MARK: - Main View

/// The main entry point view for the app
struct MainView: View {
    // MARK: - Environment

//    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    @ObservedObject var viewModel: MainViewModel
    @EnvironmentObject var appState: AppState
//    @State private var appState = AppState()
    
    // MARK: - View Model
//    let modelContainer: ModelContainer
//    @State private var mainViewModel: MainViewModel?
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if viewModel.isCheckingProfile {
                ProgressView("Loading profile...")
            } else if !viewModel.hasUserProfile || !appState.hasCompletedOnboarding {
                OnboardingView(onComplete: viewModel.handleOnboardingComplete)
            } else {
                ContentView()
            }
        }
        .alert(item: $viewModel.error) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Supporting Types

    /// Application error types
    enum AppError: Error {
        case dataError(String)
        case networkError(String)
        case userError(String)
        case serverError(String)
        case unknown(String)
        
        var message: String {
            switch self {
            case .dataError(let message):
                return "Data Error: \(message)"
            case .networkError(let message):
                return "Network Error: \(message)"
            case .userError(let message):
                return "User Error: \(message)"
            case .serverError(let message):
                return "Server Error: \(message)"
            case .unknown(let message):
                return "Unknown Error: \(message)"
            }
        }
    }

    /// Application feature flags
    enum AppFeature: String, CaseIterable {
        case aiMealSuggestions
        case barcodeScan
        case waterTracking
        case exerciseTracking
        case weightTracking
        case exportData
        case darkMode
    }
    
    // MARK: - Main View Model

    /// View model for the main content view
    class MainViewModel: ObservableObject {
        // MARK: - Properties
        
        // Dependencies
        private let modelContext: ModelContext
        private let appState: AppState
        private let userRepository: UserRepository
        
        // State
        @Published var hasUserProfile: Bool = false
        @Published var isCheckingProfile: Bool = true
        @Published var error: AppError? = nil
        
        // MARK: - Initializers
        
        init(modelContext: ModelContext, appState: AppState) {
            self.modelContext = modelContext
            self.appState = appState
            
            // Get repository from service locator
            self.userRepository = AppServices.shared.getUserRepository()
            
            // Check if user profile exists
            checkUserProfile()
        }
        
        // MARK: - Methods
        
        /// Check if a user profile exists
        private func checkUserProfile() {
            isCheckingProfile = true
            
            do {
                let profile = try userRepository.getCurrentUserProfile()
                hasUserProfile = profile != nil
                appState.hasCompletedOnboarding = profile != nil
            } catch {
                self.error = AppError.dataError("Failed to check user profile: \(error.localizedDescription)")
            }
            
            isCheckingProfile = false
        }
        
        /// Handle onboarding completion
        func handleOnboardingComplete() {
            appState.completeOnboarding()
            checkUserProfile()
        }
    }
}
