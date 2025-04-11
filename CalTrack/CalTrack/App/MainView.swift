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
    @Environment(\.scenePhase) private var scenePhase
    
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
                    .task {
                        // Use task instead of onAppear for better SwiftUI lifecycle handling
                        await initializeViewModel()
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
            if !appState.showOnboarding {
                return Alert(
                    title: Text("Error"),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK")) {
                        appState.clearError()
                    }
                )
            } else {
                return Alert(title: Text(""), message: Text(""), dismissButton: .default(Text("OK")))
            }
        }
        // Handle app lifecycle events
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if let viewModel = mainViewModel {
                Task {
                    await viewModel.handleAppStateChange(newPhase)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func initializeViewModel() async {
        // Add a slight delay to show the splash screen
        try? await Task.sleep(nanoseconds: 1_000_000_000) // keep splash for 1 second
        
        // Initialize the main view model after services are initialized
        await MainActor.run {
            AppServices.shared.initialize(with: modelContext)
            mainViewModel = MainViewModel(modelContext: modelContext, appState: appState)
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
@MainActor
class MainViewModel: ObservableObject {
    // MARK: - Properties
    
    // Dependencies
    private let modelContext: ModelContext
    private let appState: AppState
    private let userRepository: UserRepository
    private let nutritionService: NutritionService
    
    // State
    @Published var hasUserProfile: Bool = false
    @Published var isCheckingProfile: Bool = true
    @Published var error: AppError? = nil
    @Published var isInitialized: Bool = false
    
    // MARK: - Initializers
    
    init(modelContext: ModelContext, appState: AppState) {
        self.modelContext = modelContext
        self.appState = appState
        
        // Get repositories and services from service locator
        self.userRepository = AppServices.shared.getUserRepository()
        self.nutritionService = AppServices.shared.getNutritionService()
        
        // Check if user profile exists
        Task {
            await initializeApp()
        }
    }
    
    // Set model context after initialization (useful for previews)
    func setModelContext(_ context: ModelContext) {
        // This is helpful for preview environments
    }
    
    // MARK: - App Initialization
    
    private func initializeApp() async {
        isCheckingProfile = true
        
        do {
            // Initialize user data
            try await initializeUserData()
            
            // Load cached nutrition data
            try await nutritionService.loadCachedData()
            
            // Set app state based on user status
            if !hasUserProfile {
                appState.selectedTab = 3 // Go to profile tab if no user
            }
            
            // Mark as initialized
            isInitialized = true
        } catch {
            self.error = AppError.initializationError("Failed to initialize app: \(error.localizedDescription)")
            appState.showError(AppError.initializationError("Failed to initialize app: \(error.localizedDescription)"))
        }
        
        isCheckingProfile = false
    }
    
    private func initializeUserData() async throws {
        do {
            let profile = try userRepository.getCurrentUserProfile()
            hasUserProfile = profile != nil
            appState.hasCompletedOnboarding = profile != nil
        } catch {
            self.error = AppError.dataError("Failed to check user profile: \(error.localizedDescription)")
            appState.showError(AppError.dataError("Failed to check user profile: \(error.localizedDescription)"))
            throw error
        }
    }
    
    // MARK: - App State Management
    
    func handleAppStateChange(_ scenePhase: ScenePhase) async {
        switch scenePhase {
        case .active:
            // App became active
            if isInitialized {
                // Refresh data if needed
                try? await refreshAppData()
            }
        case .background:
            // App went to background
            // Perform cleanup or save state if needed
            break
        case .inactive:
            // App is inactive
            break
        @unknown default:
            break
        }
    }
    
    private func refreshAppData() async throws {
        // Refresh nutrition data
        try await nutritionService.refreshData()
        
        // Check user profile again
        try await initializeUserData()
    }
    
    // MARK: - Deep Link Handling
    
    func handleDeepLink(_ url: URL) {
        // Parse URL and set appropriate deep link
        let urlString = url.absoluteString
        
        if urlString.contains("meal") {
            // Example: caltrack://meal/123
            let components = urlString.components(separatedBy: "/")
            if components.count > 2 {
                let mealId = components[2]
                appState.deepLink = .mealDetail(mealId)
            }
        } else if urlString.contains("macro") {
            // Example: caltrack://macro/protein
            let components = urlString.components(separatedBy: "/")
            if components.count > 2 {
                let macroString = components[2].lowercased()
                if macroString == "protein" {
                    appState.deepLink = .macroDetail(.protein)
                } else if macroString == "carbs" {
                    appState.deepLink = .macroDetail(.carbs)
                } else if macroString == "fat" {
                    appState.deepLink = .macroDetail(.fat)
                } else if macroString == "calories" {
                    appState.deepLink = .macroDetail(.calories)
                }
            }
        } else if urlString.contains("insights") {
            // Example: caltrack://insights
            appState.deepLink = .insights
        } else if urlString.contains("profile") {
            // Example: caltrack://profile
            appState.deepLink = .profile
        }
    }
    
    /// Handle onboarding completion
    func handleOnboardingComplete() {
        appState.completeOnboarding()
        
        // Recheck user profile
        Task {
            try? await initializeUserData()
        }
    }
}
