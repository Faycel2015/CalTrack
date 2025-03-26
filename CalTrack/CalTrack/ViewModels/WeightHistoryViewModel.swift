//
//  WeightHistoryViewModel.swift
//  CalTrack
//
//  Created by FayTek on 3/26/25.
//

import Foundation
import SwiftUI
import SwiftData

class WeightHistoryViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // State
    @Published var isLoading = false
    @Published var error: AppError? = nil
    @Published var showAddEntry = false
    
    // Data
    @Published var weightEntries: [WeightEntry] = []
    @Published var selectedTimeRange: TimeRange = .oneMonth
    @Published var sortOption: SortOption = .dateNewest
    
    // Add entry form
    @Published var newWeight: String = ""
    @Published var newEntryDate: Date = Date()
    
    // MARK: - Computed Properties
    
    var filteredEntries: [WeightEntry] {
        let calendar = Calendar.current
        let today = Date()
        
        var startDate: Date?
        
        switch selectedTimeRange {
        case .oneWeek:
            startDate = calendar.date(byAdding: .day, value: -7, to: today)
        case .oneMonth:
            startDate = calendar.date(byAdding: .month, value: -1, to: today)
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: today)
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -6, to: today)
        case .oneYear:
            startDate = calendar.date(byAdding: .year, value: -1, to: today)
        case .all:
            startDate = nil
        }
        
        if let startDate = startDate {
            return weightEntries.filter { $0.date >= startDate }
        } else {
            return weightEntries
        }
    }
    
    var sortedEntries: [WeightEntry] {
        switch sortOption {
        case .dateNewest:
            return filteredEntries.sorted { $0.date > $1.date }
        case .dateOldest:
            return filteredEntries.sorted { $0.date < $1.date }
        case .weightHighest:
            return filteredEntries.sorted { $0.weight > $1.weight }
        case .weightLowest:
            return filteredEntries.sorted { $0.weight < $1.weight }
        }
    }
    
    var isValidWeight: Bool {
        guard let weight = Double(newWeight.replacingOccurrences(of: ",", with: ".")),
              weight > 0 else {
            return false
        }
        return true
    }
    
    var goalType: WeightGoal {
        // In a real app, this would come from the user profile
        return .lose
    }
    
    var totalChange: Double {
        guard let oldest = filteredEntries.min(by: { $0.date < $1.date }),
              let newest = filteredEntries.max(by: { $0.date < $1.date }) else {
            return 0
        }
        
        return newest.weight - oldest.weight
    }
    
    var averageWeeklyChange: Double {
        guard let oldest = filteredEntries.min(by: { $0.date < $1.date }),
              let newest = filteredEntries.max(by: { $0.date < $1.date }),
              oldest.id != newest.id else {
            return 0
        }
        
        let totalChange = newest.weight - oldest.weight
        let days = Calendar.current.dateComponents([.day], from: oldest.date, to: newest.date).day ?? 1
        let weeks = max(1, Double(days) / 7.0)
        
        return totalChange / weeks
    }
    
    var progressPercentage: Double {
        // In a real app, this would calculate against a goal
        return 65.0
    }
    
    var goalDescription: String? {
        switch goalType {
        case .lose:
            return "Goal: Lose weight at 0.5-1 kg per week"
        case .gain:
            return "Goal: Gain weight at 0.5 kg per week"
        case .maintain:
            return "Goal: Maintain current weight"
        }
    }
    
    // MARK: - Chart Data
    
    // Calculate weight changes from previous entry
    var weightChanges: [UUID: Double] {
        var changes: [UUID: Double] = [:]
        let sortedByDate = weightEntries.sorted { $0.date < $1.date }
        
        for i in 1..<sortedByDate.count {
            let currentWeight = sortedByDate[i].weight
            let previousWeight = sortedByDate[i-1].weight
            changes[sortedByDate[i].id] = currentWeight - previousWeight
        }
        
        return changes
    }
    
    // Normalized weights for the chart (0-1 scale)
    var normalizedWeights: [CGFloat] {
        let entries = filteredEntries.sorted { $0.date < $1.date }
        guard !entries.isEmpty else { return [] }
        
        let weights = entries.map { $0.weight }
        let minWeight = (weights.min() ?? 0) - 1
        let maxWeight = (weights.max() ?? 0) + 1
        let range = max(0.1, maxWeight - minWeight)
        
        return entries.map { CGFloat(($0.weight - minWeight) / range) }
    }
    
    // X-axis labels for the chart
    var xAxisLabels: [String] {
        let entries = filteredEntries.sorted { $0.date < $1.date }
        guard !entries.isEmpty else { return [] }
        
        // Determine how many labels to show based on the number of entries
        let numLabels = min(5, entries.count)
        guard numLabels > 0 else { return [] }
        
        let step = max(1, entries.count / numLabels)
        var labels: [String] = []
        
        for i in stride(from: 0, to: entries.count, by: step) {
            let entry = entries[i]
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            labels.append(formatter.string(from: entry.date))
        }
        
        // Always include the last label if we haven't already
        if labels.count < numLabels, let lastEntry = entries.last {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            labels.append(formatter.string(from: lastEntry.date))
        }
        
        return labels
    }
    
    // Y-axis labels for the chart
    var yAxisLabels: [String] {
        let entries = filteredEntries
        guard !entries.isEmpty else { return Array(repeating: "", count: 5) }
        
        let weights = entries.map { $0.weight }
        let minWeight = (weights.min() ?? 0) - 1
        let maxWeight = (weights.max() ?? 0) + 1
        let range = maxWeight - minWeight
        let step = range / 4
        
        return (0...4).map {
            let value = maxWeight - (Double($0) * step)
            return String(format: "%.1f", value)
        }
    }
    
    // MARK: - Methods
    
    func loadWeightHistory() {
        isLoading = true
        
        // In a real app, this would load from a repository
        // For now, generate mock data
        
        var entries: [WeightEntry] = []
        let calendar = Calendar.current
        var mockWeight: Double = 75.0
        
        // Generate entries for the last 3 months
        for i in (0...90).reversed() {
            if i % 3 == 0 { // Every 3 days
                let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
                
                // Add some realistic variation
                let change = Double.random(in: -0.5...0.3)
                mockWeight += change
                
                entries.append(WeightEntry(date: date, weight: mockWeight))
            }
        }
        
        weightEntries = entries
        isLoading = false
    }
    
    func addWeightEntry() {
        guard let weight = Double(newWeight.replacingOccurrences(of: ",", with: ".")) else {
            error = AppError.userError("Please enter a valid weight")
            return
        }
        
        let newEntry = WeightEntry(date: newEntryDate, weight: weight)
        weightEntries.append(newEntry)
        
        // In a real app, save to the database
        
        // Reset form
        newWeight = ""
        newEntryDate = Date()
        showAddEntry = false
    }
    
    // MARK: - Enums
    
    enum TimeRange: String, CaseIterable {
        case oneWeek = "1W"
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case all = "All"
        
        var description: String {
            switch self {
            case .oneWeek: return "1 Week"
            case .oneMonth: return "1 Month"
            case .threeMonths: return "3 Months"
            case .sixMonths: return "6 Months"
            case .oneYear: return "1 Year"
            case .all: return "All Time"
            }
        }
    }
    
    enum SortOption {
        case dateNewest
        case dateOldest
        case weightHighest
        case weightLowest
    }
}
