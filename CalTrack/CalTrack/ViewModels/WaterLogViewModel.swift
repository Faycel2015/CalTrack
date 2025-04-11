//
//  WaterLogViewModel.swift
//  CalTrack
//
//  Created by FayTek on 4/9/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class WaterLogViewModel: ObservableObject {
    // MARK: - Services
    
    private let waterService: WaterService
    
    // MARK: - Published Properties
    
    // Form inputs
    @Published var waterAmount: Double = 250
    @Published var selectedUnit: WaterUnit = .ml
    
    // Data
    @Published var waterHistory: [WaterEntry] = []
    @Published var dailyTotal: Double = 0
    @Published var dailyGoal: Double = 2000
    @Published var weeklySummary: WeeklyWaterSummary?
    
    // UI State
    @Published var isLoading: Bool = false
    @Published var showingConfirmation: Bool = false
    @Published var error: AppError? = nil
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Formatters
    
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    // MARK: - Initializer
    
    init(waterService: WaterService? = nil) {
        // Get service from service locator or use the provided one
        if let waterService = waterService {
            self.waterService = waterService
        } else {
            self.waterService = AppServices.shared.getWaterService()
        }
        
        // Load initial data
        loadWaterSummary()
    }
    
    // MARK: - Public Methods
    
    /// Load water tracking data
    func loadWaterSummary() {
        isLoading = true
        
        Task {
            do {
                // Get water summary for today
                let summary = try await waterService.getWaterSummary(for: Date())
                
                // Load weekly summary
                let weeklySummary = try await waterService.getWeeklyWaterSummary()
                
                // Update UI state
                self.waterHistory = summary.entries
                self.dailyTotal = summary.totalWaterIntake
                self.dailyGoal = summary.dailyGoal
                self.weeklySummary = weeklySummary
                self.isLoading = false
            } catch {
                self.error = AppError.dataError("Failed to load water data: \(error.localizedDescription)")
                self.isLoading = false
                self.loadMockWaterHistory() // Fall back to mock data
            }
        }
    }
    
    /// Set water amount and unit
    /// - Parameters:
    ///   - amount: Water amount
    ///   - unit: Unit of measurement
    func setWaterAmount(amount: Double, unit: WaterUnit) {
        waterAmount = amount
        selectedUnit = unit
    }
    
    /// Log water entry
    func logWater() {
        // Don't allow empty or negative values
        guard waterAmount > 0 else { return }
        
        isLoading = true
        
        Task {
            do {
                // Log water entry through service
                let entry = try waterService.logWaterEntry(
                    amount: waterAmount,
                    unit: selectedUnit
                )
                
                // Add to history and update total
                let amountInMl = selectedUnit == .oz ? waterAmount * 29.5735 : waterAmount
                
                // Update UI state
                self.waterHistory.insert(entry, at: 0)
                self.dailyTotal += amountInMl
                self.showingConfirmation = true
                self.isLoading = false
                
                // After saving, refresh full summary
                loadWaterSummary()
            } catch {
                self.error = AppError.dataError("Failed to log water entry: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
    }
    
    /// Delete water entry
    /// - Parameter entry: The entry to delete
    func deleteWaterEntry(_ entry: WaterEntry) {
        isLoading = true
        
        Task {
            do {
                try waterService.deleteWaterEntry(entry)
                
                // Reload data after deletion
                loadWaterSummary()
            } catch {
                self.error = AppError.dataError("Failed to delete water entry: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Load mock water history (used for previews or fallbacks)
    func loadMockWaterHistory() {
        // In a real app, this would load from a repository
        // For demonstration, let's just create some mock data
        
        let calendar = Calendar.current
        let now = Date()
        
        // Set initial total based on mock data
        dailyTotal = 750
        
        // Create mock entries
        waterHistory = [
            WaterEntry(id: UUID(), amount: 250, unit: .ml, timestamp: calendar.date(byAdding: .hour, value: -1, to: now)!),
            WaterEntry(id: UUID(), amount: 250, unit: .ml, timestamp: calendar.date(byAdding: .hour, value: -3, to: now)!),
            WaterEntry(id: UUID(), amount: 250, unit: .ml, timestamp: calendar.date(byAdding: .hour, value: -6, to: now)!)
        ]
        
        isLoading = false
    }
    
    /// Get completion status string
    var completionStatus: String {
        let percentage = Int(dailyTotal / dailyGoal * 100)
        
        if percentage < 50 {
            return "Low - Drink more water!"
        } else if percentage < 80 {
            return "Moderate - Keep drinking water."
        } else {
            return "Good - Well hydrated!"
        }
    }
    
    /// Get completion status color
    var completionStatusColor: Color {
        let percentage = dailyTotal / dailyGoal
        
        if percentage < 0.5 {
            return .red
        } else if percentage < 0.8 {
            return .yellow
        } else {
            return .green
        }
    }
}

// For integration with your error handling system
//struct AppError: Error, Identifiable {
//    let id = UUID()
//    let message: String
//    let underlyingError: Error?
//    
//    init(message: String, underlyingError: Error? = nil) {
//        self.message = message
//        self.underlyingError = underlyingError
//    }
//    
//    static func dataError(_ message: String) -> AppError {
//        return AppError(message: message)
//    }
//}
