//
//  MainView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

/// The main entry point view for the app
struct MainView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @StateObject private var appState = AppState()
    
    // MARK: - View Model
    
    @State private var mainViewModel: MainViewModel?
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let mainViewModel = mainViewModel {
                ContentView(viewModel: mainViewModel)
                    .environmentObject(appState)
            } else {
                SplashScreen()
                    .onAppear {
                        // Initialize the main view model with a slight delay
                        // to show the splash screen
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            mainViewModel = MainViewModel(
                                modelContext: modelContext,
                                appState: appState
                            )
                        }
                    }
            }
        }
        .sheet(isPresented: $appState.showOnboarding) {
            OnboardingView(
                modelContext: modelContext,
                onComplete: appState.completeOnboarding
            )
        }
        .alert(item: $appState.globalError) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK")) {
                    appState.clearError()
                }
            )
        }
    }
}

// MARK: - Splash Screen

/// Splash screen shown during app initialization
struct SplashScreen: View {
    @State private var scaleEffect: CGFloat = 0.8
    @State private var opacityEffect: Double = 0
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App logo
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "fork.knife")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                // App name
                Text("CalTrack")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)
                
                // Tagline
                Text("Track calories, reach your goals")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Loading indicator
                ProgressView()
                    .padding(.top, 20)
            }
            .scaleEffect(scaleEffect)
            .opacity(opacityEffect)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    scaleEffect = 1
                    opacityEffect = 1
                }
            }
        }
    }
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
            appState.showError(AppError.dataError("Failed to check user profile: \(error.localizedDescription)"))
        }
        
        isCheckingProfile = false
    }
    
    /// Handle onboarding completion
    func handleOnboardingComplete() {
        appState.completeOnboarding()
        checkUserProfile()
    }
}
