//
//  WeightHistoryView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

struct WeightHistoryView: View {
    @StateObject private var viewModel = WeightHistoryViewModel()
    
    // Chart configuration
    private let gridColor = Color(.systemGray5)
    private let animationDuration: Double = 1.0
    @State private var showAnimation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Statistics summary
                statisticsCard
                
                // Weight chart
                chartCard
                
                // Weight entry list
                entriesCard
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("Weight History")
        .navigationBarItems(
            trailing: Button(action: {
                viewModel.showAddEntry = true
            }) {
                Image(systemName: "plus")
            }
        )
        .sheet(isPresented: $viewModel.showAddEntry) {
            addEntrySheet
        }
        .alert(item: $viewModel.error) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            viewModel.loadWeightHistory()
        }
    }
    
    // MARK: - Statistics Card
    
    private var statisticsCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Statistics")
                    .font(.headline)
                
                Spacer()
                
                Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                    ForEach(WeightHistoryViewModel.TimeRange.allCases, id: \.self) { range in
                        Text(range.description).tag(range)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            HStack(spacing: 20) {
                statItem(
                    value: viewModel.totalChange,
                    label: "Total Change",
                    valueFormat: { value in
                        let formattedValue = String(format: "%.1f", abs(value))
                        return value >= 0 ? "+\(formattedValue) kg" : "-\(formattedValue) kg"
                    },
                    valueColor: { value in
                        if viewModel.goalType == .lose {
                            return value <= 0 ? .green : .red
                        } else if viewModel.goalType == .gain {
                            return value >= 0 ? .green : .red
                        } else {
                            return value == 0 ? .green : (value > 0 ? .orange : .blue)
                        }
                    }
                )
                
                Divider()
                    .frame(height: 40)
                
                statItem(
                    value: viewModel.averageWeeklyChange,
                    label: "Weekly Avg",
                    valueFormat: { value in
                        let formattedValue = String(format: "%.1f", abs(value))
                        return value >= 0 ? "+\(formattedValue) kg" : "-\(formattedValue) kg"
                    },
                    valueColor: { value in
                        if viewModel.goalType == .lose {
                            return value <= 0 ? .green : .red
                        } else if viewModel.goalType == .gain {
                            return value >= 0 ? .green : .red
                        } else {
                            return value == 0 ? .green : (value > 0 ? .orange : .blue)
                        }
                    }
                )
                
                Divider()
                    .frame(height: 40)
                
                statItem(
                    value: viewModel.progressPercentage,
                    label: "Goal Progress",
                    valueFormat: { value in
                        return "\(Int(value))%"
                    },
                    valueColor: { _ in .accentColor }
                )
            }
            
            if let goalText = viewModel.goalDescription {
                Text(goalText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showAnimation = true
            }
        }
    }
    
    // MARK: - Chart Card
    
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Weight Trend")
                .font(.headline)
            
            if viewModel.filteredEntries.isEmpty {
                emptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No Weight Data",
                    message: "Add weight entries to see your progress chart"
                )
                .frame(height: 200)
            } else {
                // Weight chart
                ZStack(alignment: .topLeading) {
                    // Y-axis labels and grid lines
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(0..<5) { index in
                            Spacer()
                            HStack(alignment: .center, spacing: 4) {
                                Text("\(viewModel.yAxisLabels[index])")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 30, alignment: .trailing)
                                
                                Rectangle()
                                    .fill(gridColor.opacity(0.5))
                                    .frame(height: 1)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding(.leading, 4)
                    
                    // Chart area
                    HStack(alignment: .bottom, spacing: 0) {
                        // Y-axis spacer
                        Color.clear.frame(width: 34)
                        
                        // Chart
                        GeometryReader { geometry in
                            ZStack(alignment: .bottom) {
                                // Line chart
                                Path { path in
                                    // Start at the first point
                                    if let first = viewModel.normalizedWeights.first {
                                        path.move(to: CGPoint(
                                            x: 0,
                                            y: geometry.size.height * (1 - first)
                                        ))
                                        
                                        // Draw lines to subsequent points
                                        for i in 1..<viewModel.normalizedWeights.count {
                                            let x = geometry.size.width * CGFloat(i) / CGFloat(viewModel.normalizedWeights.count - 1)
                                            let y = geometry.size.height * (1 - viewModel.normalizedWeights[i])
                                            
                                            path.addLine(to: CGPoint(x: x, y: y))
                                        }
                                    }
                                }
                                .trim(from: 0, to: showAnimation ? 1 : 0)
                                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                .animation(.easeOut(duration: animationDuration), value: showAnimation)
                                
                                // Data points
                                ForEach(0..<viewModel.normalizedWeights.count, id: \.self) { i in
                                    let x = geometry.size.width * CGFloat(i) / CGFloat(max(1, viewModel.normalizedWeights.count - 1))
                                    let y = geometry.size.height * (1 - viewModel.normalizedWeights[i])
                                    
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 8, height: 8)
                                        .position(x: x, y: y)
                                        .opacity(showAnimation ? 1 : 0)
                                        .animation(.easeOut(duration: animationDuration).delay(Double(i) * 0.05), value: showAnimation)
                                }
                            }
                        }
                    }
                }
                .frame(height: 200)
                .padding(.bottom, 20) // Space for X axis labels
                
                // X-axis labels
                HStack {
                    Color.clear.frame(width: 30) // Y-axis space
                    
                    ForEach(viewModel.xAxisLabels.indices, id: \.self) { i in
                        Text(viewModel.xAxisLabels[i])
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showAnimation = true
            }
        }
    }
    
    // MARK: - Entries Card
    
    private var entriesCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Weight Entries")
                    .font(.headline)
                
                Spacer()
                
                // Sort button
                Menu {
                    Button(action: {
                        viewModel.sortOption = .dateNewest
                    }) {
                        Label("Newest First", systemImage: "arrow.down")
                    }
                    
                    Button(action: {
                        viewModel.sortOption = .dateOldest
                    }) {
                        Label("Oldest First", systemImage: "arrow.up")
                    }
                    
                    Button(action: {
                        viewModel.sortOption = .weightHighest
                    }) {
                        Label("Highest Weight", systemImage: "arrow.down")
                    }
                    
                    Button(action: {
                        viewModel.sortOption = .weightLowest
                    }) {
                        Label("Lowest Weight", systemImage: "arrow.up")
                    }
                } label: {
                    Label("", systemImage: "arrow.up.arrow.down")
                        .font(.subheadline)
                }
            }
            
            if viewModel.sortedEntries.isEmpty {
                emptyStateView(
                    icon: "scalemass",
                    title: "No Weight Entries",
                    message: "Add weight entries to track your progress"
                )
                .padding(.vertical, 20)
            } else {
                // Weight entries list
                ForEach(viewModel.sortedEntries) { entry in
                    HStack {
                        // Date
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.formattedDate)
                                .font(.subheadline)
                            
                            Text(entry.formattedDayOfWeek)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Weight
                        Text("\(String(format: "%.1f", entry.weight)) kg")
                            .font(.headline)
                        
                        // Change from previous
                        if let change = viewModel.weightChanges[entry.id] {
                            Text(change >= 0 ? "+\(String(format: "%.1f", change))" : "\(String(format: "%.1f", change))")
                                .font(.caption)
                                .foregroundColor(change == 0 ? .secondary : (change > 0 ? .red : .green))
                                .frame(width: 50, alignment: .trailing)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                    
                    if entry.id != viewModel.sortedEntries.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Add Entry Sheet
    
    private var addEntrySheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Weight")) {
                    HStack {
                        TextField("Enter weight", text: $viewModel.newWeight)
                            .keyboardType(.decimalPad)
                        
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Date")) {
                    DatePicker(
                        "Select Date",
                        selection: $viewModel.newEntryDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                }
                
                Section {
                    Button(action: {
                        viewModel.addWeightEntry()
                    }) {
                        Text("Save Entry")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(!viewModel.isValidWeight)
                }
            }
            .navigationTitle("Add Weight Entry")
            .navigationBarItems(trailing: Button("Cancel") {
                viewModel.showAddEntry = false
            })
        }
    }
    
    // MARK: - Helper Views
    
    private func statItem(
        value: Double,
        label: String,
        valueFormat: @escaping (Double) -> String,
        valueColor: @escaping (Double) -> Color
    ) -> some View {
        VStack(spacing: 5) {
            Text(valueFormat(value))
                .font(.headline)
                .foregroundColor(valueColor(value))
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - View Model

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

#Preview {
    NavigationView {
        WeightHistoryView()
    }
}
