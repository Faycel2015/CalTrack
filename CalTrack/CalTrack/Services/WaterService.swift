//
//  WaterService.swift
//  CalTrack
//
//  Created by FayTek on 4/9/25.
//

import Foundation
import SwiftData

/// Service class that coordinates water tracking operations
@MainActor
class WaterService {
    private let waterRepository: WaterRepository
    private let userRepository: UserRepository
    
    init(waterRepository: WaterRepository, userRepository: UserRepository) {
        self.waterRepository = waterRepository
        self.userRepository = userRepository
    }
    
    // MARK: - Water Entry Operations
    
    /// Log a water entry
    /// - Parameters:
    ///   - amount: Amount of water
    ///   - unit: Unit of measurement (ml or oz)
    ///   - timestamp: Time of consumption (default is now)
    /// - Returns: The created water entry
    func logWaterEntry(
        amount: Double,
        unit: WaterUnit,
        timestamp: Date = Date()
    ) throws -> WaterEntry {
        // Create the entry
        let entry = WaterEntry(
            id: UUID(),
            amount: amount,
            unit: unit,
            timestamp: timestamp
        )
        
        // Save the entry
        try waterRepository.saveWaterEntry(entry)
        
        return entry
    }
    
    /// Delete a water entry
    /// - Parameter entry: The entry to delete
    func deleteWaterEntry(_ entry: WaterEntry) throws {
        try waterRepository.deleteWaterEntry(entry.id)
    }
    
    // MARK: - Water Summary Operations
    
    /// Get water summary for a specific date
    /// - Parameter date: The date to get summary for
    /// - Returns: Water summary for the date
    func getWaterSummary(for date: Date) async throws -> WaterSummary {
        let totalWaterIntake = try waterRepository.getTotalWaterIntakeForDate(date)
        
        // Get user's daily water goal
        var dailyWaterGoal: Double = 2000 // Default value
        
        if let userProfile = try? userRepository.getCurrentUserProfile() {
            // In a real app, the user profile would have a water goal property
            // For now, we use a formula based on weight
            dailyWaterGoal = userProfile.weight * 30 // 30ml per kg of body weight
        }
        
        // Calculate remaining water
        let remainingWater = max(0, dailyWaterGoal - totalWaterIntake)
        
        // Calculate percentage of goal completed
        let percentage = min(1.0, totalWaterIntake / dailyWaterGoal)
        
        // Get water entries for the day
        let entries = try waterRepository.getWaterEntriesForDate(date)
        
        return WaterSummary(
            date: date,
            totalWaterIntake: totalWaterIntake,
            dailyGoal: dailyWaterGoal,
            remainingWater: remainingWater,
            percentage: percentage,
            entries: entries
        )
    }
    
    /// Get weekly water summary
    /// - Parameter endDate: The end date of the week (default is today)
    /// - Returns: Weekly water summary
    func getWeeklyWaterSummary(endDate: Date = Date()) async throws -> WeeklyWaterSummary {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -6, to: endDate)!
        
        // Get daily water intake for the week
        let dailyIntake = try waterRepository.getDailyWaterIntakeForDateRange(
            startDate: startDate,
            endDate: endDate
        )
        
        // Sort dates for consistent ordering
        let sortedDates = dailyIntake.keys.sorted()
        
        // Create daily summaries
        var dailySummaries: [Date: WaterSummary] = [:]
        
        for date in sortedDates {
            let summary = try await getWaterSummary(for: date)
            dailySummaries[date] = summary
        }
        
        // Calculate totals and averages
        let totalIntake = dailyIntake.values.reduce(0, +)
        let averageIntake = totalIntake / Double(max(1, dailyIntake.count))
        
        // Get the user's daily goal
        var dailyGoal: Double = 2000 // Default
        if let userProfile = try? userRepository.getCurrentUserProfile() {
            dailyGoal = userProfile.weight * 30
        }
        
        // Calculate streak
        let streak = calculateStreak(dailySummaries: dailySummaries, dailyGoal: dailyGoal)
        
        return WeeklyWaterSummary(
            startDate: startDate,
            endDate: endDate,
            dailySummaries: dailySummaries,
            totalIntake: totalIntake,
            averageIntake: averageIntake,
            streak: streak
        )
    }
    
    // MARK: - Helper Methods
    
    /// Calculate current streak of meeting daily goal
    /// - Parameters:
    ///   - dailySummaries: Dictionary of daily summaries
    ///   - dailyGoal: Daily water goal
    /// - Returns: Current streak count
    private func calculateStreak(dailySummaries: [Date: WaterSummary], dailyGoal: Double) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var streak = 0
        var currentDate = today
        
        // Check backwards from today
        while true {
            if let summary = dailySummaries[currentDate], summary.totalWaterIntake >= dailyGoal * 0.9 {
                streak += 1
            } else {
                break
            }
            
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            
            currentDate = previousDate
        }
        
        return streak
    }
}

// MARK: - Data Models

/// Water summary for a specific day
struct WaterSummary {
    let date: Date
    let totalWaterIntake: Double
    let dailyGoal: Double
    let remainingWater: Double
    let percentage: Double
    let entries: [WaterEntry]
    
    /// Check if the goal is met
    var isGoalMet: Bool {
        return totalWaterIntake >= dailyGoal
    }
    
    /// Get intake status categorization
    var status: WaterIntakeStatus {
        if percentage < 0.5 {
            return .low
        } else if percentage < 0.8 {
            return .moderate
        } else {
            return .good
        }
    }
}

/// Weekly water tracking summary
struct WeeklyWaterSummary {
    let startDate: Date
    let endDate: Date
    let dailySummaries: [Date: WaterSummary]
    let totalIntake: Double
    let averageIntake: Double
    let streak: Int
    
    /// Get days where the goal was met
    var daysGoalMet: Int {
        return dailySummaries.values.filter { $0.isGoalMet }.count
    }
    
    /// Get percentage of days the goal was met
    var goalCompletionRate: Double {
        return Double(daysGoalMet) / Double(max(1, dailySummaries.count))
    }
}

/// Water intake status categories
enum WaterIntakeStatus {
    case low
    case moderate
    case good
    
    var description: String {
        switch self {
        case .low:
            return "Low - Drink more water!"
        case .moderate:
            return "Moderate - Keep drinking water."
        case .good:
            return "Good - Well hydrated!"
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "red"
        case .moderate:
            return "yellow"
        case .good:
            return "green"
        }
    }
}

// MARK: - Errors

enum WaterServiceError: Error {
    case invalidEntryData(String)
    case failedToSave(String)
    
    var errorDescription: String {
        switch self {
        case .invalidEntryData(let reason):
            return "Invalid water entry data: \(reason)"
        case .failedToSave(let errorMessage):
            return "Failed to save: \(errorMessage)"
        }
    }
}

// Register water service with app services
extension AppServices {
    func getWaterService() -> WaterService {
        guard let waterRepository = getWaterRepository(),
              let userRepository = userRepository else {
            fatalError("Required repositories not initialized")
        }
        
        return WaterService(
            waterRepository: waterRepository,
            userRepository: userRepository
        )
    }
    
    func getWaterRepository() -> WaterRepository? {
        guard let modelContext = modelContext else {
            return nil
        }
        
        return WaterRepository(modelContext: modelContext)
    }
}
