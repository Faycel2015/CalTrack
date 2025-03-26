//
//  WeightEntry.swift
//  CalTrack
//
//  Created by FayTek on 3/26/25.
//

import Foundation
import SwiftData

// This should be in a separate file
@Model
final class WeightEntry: Identifiable, Hashable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var weight: Double
    
    // Computed properties for formatting
    var formattedDate: String {
        date.formatted(style: .medium)
    }
    
    var formattedDayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    // Required initializer for @Model class
    init(id: UUID = UUID(), date: Date, weight: Double) {
        self.id = id
        self.date = date
        self.weight = weight
    }
    
    // Implement Hashable
    static func == (lhs: WeightEntry, rhs: WeightEntry) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
