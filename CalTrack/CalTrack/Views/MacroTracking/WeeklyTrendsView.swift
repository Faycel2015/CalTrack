//
//  WeeklyTrendsView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import Charts

struct WeeklyTrendsView: View {
    // Trend data for different metrics
    struct TrendData {
        let metricName: String
        let color: Color
        let unit: String
        let weeklyValues: [DailyValue]
        let goal: Double?
    }
    
    // Daily value structure
    struct DailyValue: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }
    
    // Available trend metrics
    enum TrendMetric: String, CaseIterable {
        case calories = "Calories"
        case carbs = "Carbs"
        case protein = "Protein"
        case fat = "Fat"
        case weight = "Weight"
        case exercise = "Exercise"
        
        var color: Color {
            switch self {
            case .calories: return .orange
            case .carbs: return .blue
            case .protein: return .green
            case .fat: return .yellow
            case .weight: return .purple
            case .exercise: return .red
            }
        }
        
        var unit: String {
            switch self {
            case .calories: return "cal"
            case .carbs, .protein, .fat: return "g"
            case .weight: return "kg"
            case .exercise: return "min"
            }
        }
    }
    
    // State and data
    @State private var selectedMetric: TrendMetric = .calories
    
    // Sample trend data (would be replaced with actual data)
    private func generateSampleTrendData(metric: TrendMetric) -> TrendData {
        let calendar = Calendar.current
        let today = Date()
        
        var values: [DailyValue] = []
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            
            let value: Double
            switch metric {
            case .calories:
                value = Double.random(in: 1500...2200)
            case .carbs:
                value = Double.random(in: 150...300)
            case .protein:
                value = Double.random(in: 80...150)
            case .fat:
                value = Double.random(in: 40...80)
            case .weight:
                value = Double.random(in: 70...76)
            case .exercise:
                value = Double.random(in: 30...60)
            }
            
            values.append(DailyValue(date: date, value: value))
        }
        
        // Reverse to have oldest date first
        values.reverse()
        
        // Goal based on metric
        let goal: Double?
        switch metric {
        case .calories: goal = 2000
        case .carbs: goal = 250
        case .protein: goal = 120
        case .fat: goal = 65
        case .weight: goal = 75
        case .exercise: goal = 45
        }
        
        return TrendData(
            metricName: metric.rawValue,
            color: metric.color,
            unit: metric.unit,
            weeklyValues: values,
            goal: goal
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header with metric selector
            headerSection
            
            // Trend Chart
            trendChartSection
            
            // Detailed Insights
            insightsSection
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .animation(.default, value: selectedMetric)
    }
    
    // Header with metric selector
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Metric Title
            Text(generateSampleTrendData(metric: selectedMetric).metricName + " Trend")
                .font(.title3)
                .fontWeight(.bold)
            
            // Metric Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TrendMetric.allCases, id: \.self) { metric in
                        Button(action: {
                            withAnimation {
                                selectedMetric = metric
                            }
                        }) {
                            Text(metric.rawValue)
                                .font(.subheadline)
                                .foregroundColor(selectedMetric == metric ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedMetric == metric ? metric.color : Color(.systemGray6))
                                )
                        }
                    }
                }
            }
        }
    }
    
    // Trend Chart Section
    private var trendChartSection: some View {
        let trendData = generateSampleTrendData(metric: selectedMetric)
        
        return VStack(alignment: .leading, spacing: 10) {
            // Chart
            Chart {
                ForEach(trendData.weeklyValues) { entry in
                    LineMark(
                        x: .value("Day", entry.date),
                        y: .value(trendData.metricName, entry.value)
                    )
                    .interpolationMethod(.cardinal)
                    .foregroundStyle(trendData.color)
                    
                    AreaMark(
                        x: .value("Day", entry.date),
                        y: .value(trendData.metricName, entry.value)
                    )
                    .interpolationMethod(.cardinal)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                trendData.color.opacity(0.5),
                                trendData.color.opacity(0.1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Points for each day
                    PointMark(
                        x: .value("Day", entry.date),
                        y: .value(trendData.metricName, entry.value)
                    )
                    .foregroundStyle(trendData.color)
                    .annotation(position: .overlay, alignment: .bottom) {
                        Text("\(Int(entry.value))")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                }
                
                // Goal line if available
                if let goal = trendData.goal {
                    RuleMark(y: .value("Goal", goal))
                        .foregroundStyle(trendData.color.opacity(0.5))
                        .lineStyle(StrokeStyle(lineCap: .round, dash: [5]))
                        .annotation(position: .overlay, alignment: .trailing) {
                            Text("Goal: \(Int(goal))")
                                .font(.caption)
                                .foregroundColor(trendData.color)
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisTick()
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 250)
            
            // Chart Description and Statistics
            VStack(alignment: .leading, spacing: 5) {
                Text("Weekly \(trendData.metricName) Trend")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Trend Statistics
                HStack {
                    // Average
                    VStack(alignment: .leading) {
                        Text("Avg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(calculateAverage(trendData.weeklyValues)))")
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    // Highest
                    VStack(alignment: .leading) {
                        Text("Highest")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(calculateHighest(trendData.weeklyValues)))")
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    // Lowest
                    VStack(alignment: .leading) {
                        Text("Lowest")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(calculateLowest(trendData.weeklyValues)))")
                            .font(.subheadline)
                    }
                }
                .padding(.top, 5)
            }
        }
    }
    
    // Insights Section
    private var insightsSection: some View {
        let trendData = generateSampleTrendData(metric: selectedMetric)
        
        return VStack(alignment: .leading, spacing: 15) {
            Text("Insights")
                .font(.headline)
            
            // Statistical Insights
            VStack(alignment: .leading, spacing: 10) {
                insightRow(
                    title: "Average",
                    value: "\(Int(calculateAverage(trendData.weeklyValues))) \(trendData.unit)",
                    color: trendData.color
                )
                
                insightRow(
                    title: "Highest",
                    value: "\(Int(calculateHighest(trendData.weeklyValues))) \(trendData.unit)",
                    color: .green
                )
                
                insightRow(
                    title: "Lowest",
                    value: "\(Int(calculateLowest(trendData.weeklyValues))) \(trendData.unit)",
                    color: .red
                )
                
                // Trend Indicator
                HStack {
                    Text("Weekly Trend")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    trendIndicator(for: trendData)
                }
                .foregroundColor(.secondary)
            }
            
            // Goal Comparison
            if let goal = trendData.goal {
                goalComparisonSection(
                    goal: goal,
                    values: trendData.weeklyValues,
                    unit: trendData.unit,
                    color: trendData.color
                )
            }
        }
    }
    
    // Calculation Helpers
    private func calculateAverage(_ values: [DailyValue]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0) { $0 + $1.value } / Double(values.count)
    }
    
    private func calculateHighest(_ values: [DailyValue]) -> Double {
        values.max { $0.value < $1.value }?.value ?? 0
    }
    
    private func calculateLowest(_ values: [DailyValue]) -> Double {
        values.min { $0.value < $1.value }?.value ?? 0
    }
    
    // Trend Indicator
    private func trendIndicator(for trendData: TrendData) -> some View {
        let trend = calculateTrend(trendData.weeklyValues)
        
        return HStack(spacing: 4) {
            Image(systemName: trend.iconName)
                .foregroundColor(trend.color)
            
            Text(trend.description)
                .font(.caption)
        }
    }
    
    // Trend Calculation
    private func calculateTrend(_ values: [DailyValue]) -> TrendIndicator {
        guard values.count >= 2 else { return .neutral }
        
        let startValue = values.first!.value
        let endValue = values.last!.value
        let percentChange = ((endValue - startValue) / startValue) * 100
        
        if percentChange > 5 {
            return .upSignificant
        } else if percentChange > 0 {
            return .upModerate
        } else if percentChange < -5 {
            return .downSignificant
        } else if percentChange < 0 {
            return .downModerate
        } else {
            return .neutral
        }
    }
    
    // Goal Comparison Section
    private func goalComparisonSection(
        goal: Double,
        values: [DailyValue],
        unit: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            
            Text("Goal Tracking")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Weekly Goal")
                        .font(.caption)
                    
                    Text("\(Int(goal)) \(unit)")
                        .font(.subheadline.bold())
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Goal Achievement")
                        .font(.caption)
                    
                    Text("\(calculateGoalAchievement(values, goal))%")
                        .font(.subheadline.bold())
                        .foregroundColor(color)
                }
            }
            
            // Progress Bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(color.opacity(0.2))
                    .frame(height: 10)
                    .cornerRadius(5)
                
                Rectangle()
                    .fill(color)
                    .frame(width: CGFloat(calculateGoalAchievement(values, goal)) / 100 * UIScreen.main.bounds.width * 0.8, height: 10)
                    .cornerRadius(5)
            }
        }
    }
    
    // Goal Achievement Calculation
    private func calculateGoalAchievement(_ values: [DailyValue], _ goal: Double) -> Int {
        let daysAboveGoal = values.filter { $0.value >= goal }.count
        return Int((Double(daysAboveGoal) / Double(values.count)) * 100)
    }
    
    // Insight Row Helper
    private func insightRow(
        title: String,
        value: String,
        color: Color
    ) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
    }
    
    // Trend Indicator Enum
    enum TrendIndicator {
        case upSignificant
        case upModerate
        case downSignificant
        case downModerate
        case neutral
        
        var iconName: String {
            switch self {
            case .upSignificant: return "arrow.up.circle.fill"
            case .upModerate: return "arrow.up"
            case .downSignificant: return "arrow.down.circle.fill"
            case .downModerate: return "arrow.down"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .upSignificant, .upModerate: return .green
            case .downSignificant, .downModerate: return .red
            case .neutral: return .gray
            }
        }
        
        var description: String {
            switch self {
            case .upSignificant: return "Strong Increase"
            case .upModerate: return "Slight Increase"
            case .downSignificant: return "Strong Decrease"
            case .downModerate: return "Slight Decrease"
            case .neutral: return "No Change"
            }
        }
    }
    
    // Convenience initializer for preview
    static func sample() -> WeeklyTrendsView {
        WeeklyTrendsView()
    }
}

#Preview {
    WeeklyTrendsView.sample()
        .padding()
        .background(Color(.systemGray6))
}
