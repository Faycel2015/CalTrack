//
//  SettingsView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SettingsViewModel
    @EnvironmentObject private var appState: AppState

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationView {
            Form {
                // Appearance Section
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $appState.colorScheme) {
                        Text("System Default").tag(nil as ColorScheme?)
                        Text("Light").tag(ColorScheme.light as ColorScheme?)
                        Text("Dark").tag(ColorScheme.dark as ColorScheme?)
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Toggle("Use Accent Color", isOn: $viewModel.useAccentColor)

                    ColorPicker("Custom Accent Color", selection: $viewModel.customAccentColor)
                        .disabled(!viewModel.useAccentColor)
                }

                // Nutrition Tracking Section
                Section(header: Text("Nutrition Tracking")) {
                    Toggle("Show Calorie Goal Notifications", isOn: $viewModel.showCalorieGoalNotifications)

                    Toggle("Track Macronutrients", isOn: $viewModel.trackMacronutrients)

                    if viewModel.trackMacronutrients {
                        Picker("Macro Goal Display", selection: $viewModel.macroGoalDisplayMode) {
                            ForEach(MacroGoalDisplayMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                    }

                    Stepper(
                        "Daily Water Goal: \(viewModel.dailyWaterGoal, specifier: "%.0f") ml",
                        value: $viewModel.dailyWaterGoal,
                        in: 500 ... 5000,
                        step: 250
                    )
                }

                // Tracking Features Section
                Section(header: Text("Tracking Features")) {
                    ForEach(AppFeature.allCases) { feature in
                        Toggle(feature.rawValue, isOn: Binding(
                            get: { viewModel.isFeatureEnabled(feature) },
                            set: { _ in viewModel.toggleFeature(feature) }
                        ))
                    }
                }

                // Privacy and Data Section
                Section(header: Text("Privacy & Data")) {
                    NavigationLink(destination: dataPrivacyDetailView) {
                        HStack {
                            Image(systemName: "lock.shield")
                            Text("Data Privacy")
                        }
                    }

                    Button(action: {
                        viewModel.exportUserData()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export My Data")
                        }
                    }

                    Button(role: .destructive, action: {
                        viewModel.showDeleteDataConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete All Data")
                        }
                    }
                }

                // App Information Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build Number")
                        Spacer()
                        Text(viewModel.buildNumber)
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: aboutAppView) {
                        Text("About CalTrack")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarItems(
                trailing: Button("Done") {
                    viewModel.saveSettings()
                    dismiss()
                }
            )
            .alert(isPresented: $viewModel.showDeleteDataConfirmation) {
                Alert(
                    title: Text("Delete All Data"),
                    message: Text("Are you sure you want to delete all your data? This cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        viewModel.deleteAllUserData()
                    },
                    secondaryButton: .cancel()
                )
            }
            // And update your alert in SettingsView
            .alert(item: $viewModel.identifiableError) { identifiableError in
                Alert(
                    title: Text("Error"),
                    message: Text(identifiableError.localizedDescription),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Detailed Views

    private var dataPrivacyDetailView: some View {
        List {
            Section(header: Text("Data Collection")) {
                Text("CalTrack collects and stores the following information:")

                ForEach(viewModel.collectedDataTypes, id: \.self) { dataType in
                    Text(dataType)
                }
            }

            Section(header: Text("Data Usage")) {
                Text("Your data is used to:")

                ForEach(viewModel.dataUsagePurposes, id: \.self) { purpose in
                    Text(purpose)
                }
            }

            Section(header: Text("Data Security")) {
                Text("We use industry-standard encryption to protect your personal information.")
            }
        }
        .navigationTitle("Data Privacy")
    }

    private var aboutAppView: some View {
        List {
            Section(header: Text("Our Mission")) {
                Text("CalTrack is dedicated to helping you achieve your nutrition and fitness goals through personalized tracking and insights.")
            }

            Section(header: Text("Contact")) {
                HStack {
                    Text("Email")
                    Spacer()
                    Text("support@caltrack.app")
                }

                HStack {
                    Text("Website")
                    Spacer()
                    Text("www.caltrack.app")
                }
            }

            Section(header: Text("Social")) {
                HStack {
                    Image(systemName: "logo.instagram")
                    Text("@CalTrackApp")
                }

                HStack {
                    Image(systemName: "logo.twitter")
                    Text("@CalTrackApp")
                }
            }

            Section {
                Text("Made with ❤️ by FayTek")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("About CalTrack")
    }
}

// MARK: - View Model

class SettingsViewModel: ObservableObject {
    // MARK: - Properties

    private let modelContext: ModelContext
    private let userRepository: UserRepository
    @Published var identifiableError: IdentifiableError?

    // Appearance
    @Published var useAccentColor: Bool = false
    @Published var customAccentColor: Color = .blue

    // Nutrition Tracking
    @Published var showCalorieGoalNotifications: Bool = true
    @Published var trackMacronutrients: Bool = true
    @Published var macroGoalDisplayMode: MacroGoalDisplayMode = .percentage
    @Published var dailyWaterGoal: Double = 2000

    // Features
    @Published var enabledFeatures: [AppFeature] = AppFeature.allCases

    // State
    @Published var showDeleteDataConfirmation: Bool = false
    @Published var error: Error?

    // App Info
    let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let buildNumber: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

    // Privacy Details
    let collectedDataTypes: [String] = [
        "Personal Information",
        "Body Measurements",
        "Nutrition Tracking Data",
        "Weight History",
    ]

    let dataUsagePurposes: [String] = [
        "Personalize nutrition recommendations",
        "Track progress towards health goals",
        "Provide insights and analytics",
        "Improve app functionality",
    ]

    // MARK: - Initializer

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        userRepository = UserRepository(modelContext: modelContext)
        loadSettings()
    }

    // MARK: - Methods

    func loadSettings() {
        // Load saved settings from user defaults or database
        // Placeholder for actual implementation
    }

    func saveSettings() {
        // Save settings to user defaults or database
        // Placeholder for actual implementation
    }

    func isFeatureEnabled(_ feature: AppFeature) -> Bool {
        return enabledFeatures.contains(feature)
    }

    func toggleFeature(_ feature: AppFeature) {
        if enabledFeatures.contains(feature) {
            enabledFeatures.removeAll { $0 == feature }
        } else {
            enabledFeatures.append(feature)
        }
    }

    // Update your error handling methods
    func exportUserData() {
        do {
            // Example: Export user profile and tracking data
            _ = try userRepository.getCurrentUserProfile()
            // Create export logic
        } catch {
            // Log the error using your ErrorHandler
            ErrorHandler.shared.handle(error, context: "Data Export")
            // Wrap the error for display
            self.identifiableError = IdentifiableError(error: error)
        }
    }

    func deleteAllUserData() {
        do {
            try userRepository.deleteUserProfile()
            // Additional cleanup logic
        } catch {
            // Log the error using your ErrorHandler
            ErrorHandler.shared.handle(error, context: "Data Deletion")
            // Wrap the error for display
            self.identifiableError = IdentifiableError(error: error)
        }
    }
}

// MARK: - Supporting Enums

enum MacroGoalDisplayMode: String, CaseIterable, Identifiable {
    case percentage = "Percentage"
    case grams = "Grams"
    case calories = "Calories"

    var id: String { rawValue }
}

#Preview {
    SettingsView(modelContext: try! ModelContainer(for: UserProfile.self).mainContext)
        .environmentObject(AppState())
}
