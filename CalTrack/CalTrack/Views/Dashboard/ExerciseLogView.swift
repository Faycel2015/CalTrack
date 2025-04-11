//
//  ExerciseLogView.swift
//  CalTrack
//
//  Created by FayTek on 4/9/25.
//

import SwiftUI
import SwiftData

struct ExerciseLogView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Form values
    @State private var exerciseType = ExerciseType.walking
    @State private var duration: Double = 30
    @State private var caloriesBurned: Double = 150
    @State private var date = Date()
    @State private var intensityLevel: IntensityLevel = .moderate
    @State private var notes = ""
    
    // Confirmation state
    @State private var showingConfirmation = false
    
    // Exercise data
    @State private var exerciseHistory: [ExerciseEntry] = []
    @State private var weeklyTotal: Double = 0
    @State private var weeklyGoal: Double = 150
    
    var body: some View {
        NavigationView {
            Form {
                // Exercise type
                Section(header: Text("Exercise Details")) {
                    Picker("Exercise Type", selection: $exerciseType) {
                        ForEach(ExerciseType.allCases) { type in
                            HStack {
                                Image(systemName: type.iconName)
                                    .foregroundColor(type.color)
                                Text(type.name)
                            }
                            .tag(type)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                // Duration and Intensity
                Section(header: Text("Duration & Intensity")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Duration: \(Int(duration)) minutes")
                            Spacer()
                        }
                        
                        Slider(value: $duration, in: 5...180, step: 5) { _ in
                            updateCaloriesBurned()
                        }
                    }
                    
                    Picker("Intensity", selection: $intensityLevel) {
                        ForEach(IntensityLevel.allCases) { level in
                            Text(level.description)
                                .tag(level)
                        }
                    }
                    .onChange(of: intensityLevel) { _, _ in
                        updateCaloriesBurned()
                    }
                }
                
                // Calories burned
                Section(header: Text("Calories")) {
                    HStack {
                        Text("Estimated Calories Burned")
                        Spacer()
                        Text("\(Int(caloriesBurned))")
                            .foregroundColor(.green)
                            .bold()
                    }
                }
                
                // Notes
                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                // Weekly summary
                Section(header: Text("Weekly Progress")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("This Week")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(weeklyTotal)) min")
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Weekly Goal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(weeklyGoal)) min")
                                .font(.headline)
                        }
                    }
                    
                    // Progress bar
                    ProgressView(value: min(weeklyTotal / weeklyGoal, 1.0))
                        .accentColor(.green)
                    
                    Text("\(Int(weeklyTotal / weeklyGoal * 100))% of weekly goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Save button
                Section {
                    Button(action: {
                        saveExercise()
                    }) {
                        Text("Save Exercise")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Log Exercise")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
            .onAppear {
                loadExerciseHistory()
            }
            .alert(isPresented: $showingConfirmation) {
                Alert(
                    title: Text("Exercise Logged"),
                    message: Text("Successfully added \(exerciseType.name) for \(Int(duration)) minutes."),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                    }
                )
            }
        }
    }
    
    // MARK: - Methods
    
    private func updateCaloriesBurned() {
        // Simple calculation based on exercise type, duration, and intensity
        let baseRate = exerciseType.caloriesPerMinute
        let intensityMultiplier = intensityLevel.calorieMultiplier
        
        caloriesBurned = baseRate * duration * intensityMultiplier
    }
    
    private func saveExercise() {
        // Create new entry
        let newEntry = ExerciseEntry(
            id: UUID(),
            type: exerciseType,
            duration: duration,
            caloriesBurned: caloriesBurned,
            date: date,
            intensity: intensityLevel,
            notes: notes
        )
        
        // In a real app, we would save this to a repository
        // For demonstration, just add to local array
        exerciseHistory.insert(newEntry, at: 0)
        
        // Update weekly total
        weeklyTotal += duration
        
        // Show confirmation
        showingConfirmation = true
    }
    
    private func loadExerciseHistory() {
        // In a real app, this would load from a repository
        // For demonstration, let's just create some mock data
        
        // Set initial weekly total for demonstration
        weeklyTotal = 90
        
        // Create mock entries for the week
        let calendar = Calendar.current
        exerciseHistory = [
            ExerciseEntry(
                id: UUID(),
                type: .walking,
                duration: 30,
                caloriesBurned: 150,
                date: calendar.date(byAdding: .day, value: -1, to: Date())!,
                intensity: .moderate,
                notes: "Evening walk"
            ),
            ExerciseEntry(
                id: UUID(),
                type: .running,
                duration: 25,
                caloriesBurned: 280,
                date: calendar.date(byAdding: .day, value: -2, to: Date())!,
                intensity: .vigorous,
                notes: "Morning run"
            ),
            ExerciseEntry(
                id: UUID(),
                type: .cycling,
                duration: 35,
                caloriesBurned: 210,
                date: calendar.date(byAdding: .day, value: -4, to: Date())!,
                intensity: .moderate,
                notes: "Bike ride in the park"
            )
        ]
        
        // Set current exercise type from most recent entry
        if let lastEntry = exerciseHistory.first {
            exerciseType = lastEntry.type
            duration = lastEntry.duration
            intensityLevel = lastEntry.intensity
            updateCaloriesBurned()
        }
    }
}

// MARK: - Supporting Types

enum ExerciseType: CaseIterable, Identifiable {
    case walking
    case running
    case cycling
    case swimming
    case weightLifting
    case yoga
    case hiit
    case other
    
    var id: String { self.name }
    
    var name: String {
        switch self {
        case .walking: return "Walking"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .weightLifting: return "Weight Lifting"
        case .yoga: return "Yoga"
        case .hiit: return "HIIT"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .weightLifting: return "dumbbell"
        case .yoga: return "figure.mind.and.body"
        case .hiit: return "heart.circle"
        case .other: return "figure.mixed.cardio"
        }
    }
    
    var color: Color {
        switch self {
        case .walking: return .blue
        case .running: return .green
        case .cycling: return .orange
        case .swimming: return .cyan
        case .weightLifting: return .purple
        case .yoga: return .indigo
        case .hiit: return .red
        case .other: return .gray
        }
    }
    
    var caloriesPerMinute: Double {
        switch self {
        case .walking: return 4.0
        case .running: return 10.0
        case .cycling: return 7.0
        case .swimming: return 8.0
        case .weightLifting: return 5.0
        case .yoga: return 3.0
        case .hiit: return 12.0
        case .other: return 5.0
        }
    }
}

enum IntensityLevel: CaseIterable, Identifiable {
    case light
    case moderate
    case vigorous
    
    var id: String { self.description }
    
    var description: String {
        switch self {
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .vigorous: return "Vigorous"
        }
    }
    
    var calorieMultiplier: Double {
        switch self {
        case .light: return 0.8
        case .moderate: return 1.0
        case .vigorous: return 1.3
        }
    }
}

struct ExerciseEntry: Identifiable {
    let id: UUID
    let type: ExerciseType
    let duration: Double
    let caloriesBurned: Double
    let date: Date
    let intensity: IntensityLevel
    let notes: String
}

#Preview {
    ExerciseLogView()
}
