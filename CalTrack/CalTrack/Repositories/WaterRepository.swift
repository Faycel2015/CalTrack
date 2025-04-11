//
//  WaterRepository.swift
//  CalTrack
//
//  Created by FayTek on 4/9/25.
//

import SwiftUI
import SwiftData

@Model
final class WaterEntryRecord {
    var id: UUID // Add this explicit UUID property
    var amount: Double
    var unit: String
    var timestamp: Date
    var createdAt: Date
    
    init(id: UUID = UUID(), amount: Double, unit: String, timestamp: Date) {
        self.id = id
        self.amount = amount
        self.unit = unit
        self.timestamp = timestamp
        self.createdAt = Date()
    }
}

/// Repository class for handling water tracking data operations
class WaterRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Water Entry Operations
    
    /// Save a water entry
    /// - Parameter entry: The water entry to save
    func saveWaterEntry(_ entry: WaterEntry) throws {
        let record = WaterEntryRecord(
            id: entry.id, // Use the provided ID directly
            amount: entry.amount,
            unit: entry.unit.rawValue,
            timestamp: entry.timestamp
        )
        
        modelContext.insert(record)
        try modelContext.save()
    }
    
    /// Get water entries for a specific date
    /// - Parameter date: The date to fetch entries for
    /// - Returns: Array of water entries for the specified date
    func getWaterEntriesForDate(_ date: Date) throws -> [WaterEntry] {
        let startOfDay = date.startOfDay()
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<WaterEntryRecord> { entry in
            entry.timestamp >= startOfDay && entry.timestamp < endOfDay
        }
        
        let descriptor = FetchDescriptor<WaterEntryRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        let records = try modelContext.fetch(descriptor)
        
        return records.map { record in
            WaterEntry(
                id: record.id, // Use the ID directly
                amount: record.amount,
                unit: WaterUnit(rawValue: record.unit) ?? .ml,
                timestamp: record.timestamp
            )
        }
    }
    
    /// Get water entries for a date range
    /// - Parameters:
    ///   - startDate: The start date of the range
    ///   - endDate: The end date of the range
    /// - Returns: Array of water entries within the date range
    func getWaterEntriesForDateRange(startDate: Date, endDate: Date) throws -> [WaterEntry] {
        let startOfStartDay = startDate.startOfDay()
        let endOfEndDay = Calendar.current.date(byAdding: .day, value: 1, to: endDate.startOfDay())!
        
        let predicate = #Predicate<WaterEntryRecord> { entry in
            entry.timestamp >= startOfStartDay && entry.timestamp < endOfEndDay
        }
        
        let descriptor = FetchDescriptor<WaterEntryRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        let records = try modelContext.fetch(descriptor)
        
        return records.map { record in
            WaterEntry(
                id: record.id,
                amount: record.amount,
                unit: WaterUnit(rawValue: record.unit) ?? .ml,
                timestamp: record.timestamp
            )
        }
    }
    
    /// Delete a water entry
    /// - Parameter entry: The water entry to delete
    func deleteWaterEntry(_ entryId: UUID) throws {
        // Update the predicate to use the id property directly
        let predicate = #Predicate<WaterEntryRecord> { entry in
            entry.id == entryId
        }
        
        let descriptor = FetchDescriptor<WaterEntryRecord>(predicate: predicate)
        let entries = try modelContext.fetch(descriptor)
        
        if let entry = entries.first {
            modelContext.delete(entry)
            try modelContext.save()
        } else {
            throw WaterRepositoryError.entryNotFound
        }
    }
    
    /// Get total water intake for a date
    /// - Parameter date: The date to calculate total for
    /// - Returns: Total water intake in ml
    func getTotalWaterIntakeForDate(_ date: Date) throws -> Double {
        let entries = try getWaterEntriesForDate(date)
        
        return entries.reduce(0) { total, entry in
            let amountInMl = entry.unit == .oz ? entry.amount * 29.5735 : entry.amount
            return total + amountInMl
        }
    }
    
    /// Get daily water intake for a date range
    /// - Parameters:
    ///   - startDate: The start date of the range
    ///   - endDate: The end date of the range
    /// - Returns: Dictionary mapping dates to total water intake
    func getDailyWaterIntakeForDateRange(startDate: Date, endDate: Date) throws -> [Date: Double] {
        let entries = try getWaterEntriesForDateRange(startDate: startDate, endDate: endDate)
        
        var dailyTotals: [Date: Double] = [:]
        let calendar = Calendar.current
        
        for entry in entries {
            let day = calendar.startOfDay(for: entry.timestamp)
            let amountInMl = entry.unit == .oz ? entry.amount * 29.5735 : entry.amount
            
            if let currentTotal = dailyTotals[day] {
                dailyTotals[day] = currentTotal + amountInMl
            } else {
                dailyTotals[day] = amountInMl
            }
        }
        
        return dailyTotals
    }
}

// MARK: - Errors

enum WaterRepositoryError: Error {
    case entryNotFound
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    
    var errorDescription: String {
        switch self {
        case .entryNotFound:
            return "Water entry not found"
        case .saveFailed(let error):
            return "Failed to save water entry: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch water entries: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete water entry: \(error.localizedDescription)"
        }
    }
}
