//
//  DashboardView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftData
import SwiftUI

// Dashboard View - Shows today's summary
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    // States
    @State private var showMacroTracking = false
    @State private var showAddMeal = false
    @State private var mockCalorieIntake: Double = 1650
    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with greeting and date
                    dashboardHeader

                    // Nutrition progress card
                    NutritionProgressCard.forDashboard(
                        calories: mockCalorieIntake,
                        calorieGoal: userProfile?.dailyCalorieGoal ?? 2000,
                        carbs: mockCalorieIntake * 0.4 / 4, // 40% of calories from carbs (4 cal/g)
                        carbGoal: userProfile?.carbGoalGrams ?? 250,
                        protein: mockCalorieIntake * 0.3 / 4, // 30% of calories from protein (4 cal/g)
                        proteinGoal: userProfile?.proteinGoalGrams ?? 120,
                        fat: mockCalorieIntake * 0.3 / 9, // 30% of calories from fat (9 cal/g)
                        fatGoal: userProfile?.fatGoalGrams ?? 65,
                        onAddTapped: {
                            showAddMeal = true
                        },
                        onCardTapped: {
                            showMacroTracking = true
                        }
                    )

                    // Meal cards
                    mealSection

                    // Weekly progress
                    weeklyProgressSection

                    // Quick actions
                    quickActionsSection
                }
                .padding(.bottom, 30)
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
            .sheet(isPresented: $showMacroTracking) {
                MacroTrackingView()
            }
            .sheet(isPresented: $showAddMeal) {
                // This would be replaced with your actual meal adding view
                Text("Add Meal View")
                    .font(.title)
                    .padding()
            }
        }
    }

    // MARK: - Computed Properties

    var userProfile: UserProfile? {
        return userProfiles.first
    }

    // MARK: - Dashboard Sections

    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Hello, \(userProfile?.name ?? "there")")
                        .font(.title2.bold())

                    Text(selectedDate.formatted(date: .complete, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    // Calendar button action
                }) {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "calendar")
                                .font(.headline)
                                .foregroundColor(.primary)
                        )
                }
            }

            // Date selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(-3 ... 3, id: \.self) { offset in
                        let day = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()

                        Button(action: {
                            withAnimation {
                                selectedDate = day
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(dayFormatter(day))
                                    .font(.caption)
                                    .foregroundColor(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? .white : .secondary)

                                Text(day.formatted(.dateTime.day()))
                                    .font(.headline)
                                    .foregroundColor(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? .white : .primary)
                            }
                            .frame(width: 48, height: 70)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? Color.accentColor : Color(.systemGray6))
                            )
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal)
    }

    private var mealSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Today's Meals")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    // Sample meal cards
                    mealCard(
                        title: "Breakfast",
                        time: "8:30 AM",
                        calories: 450,
                        carbs: 65,
                        protein: 20,
                        fat: 12,
                        color: .blue
                    )

                    mealCard(
                        title: "Lunch",
                        time: "12:45 PM",
                        calories: 650,
                        carbs: 80,
                        protein: 35,
                        fat: 20,
                        color: .green
                    )

                    mealCard(
                        title: "Snack",
                        time: "3:30 PM",
                        calories: 180,
                        carbs: 15,
                        protein: 12,
                        fat: 8,
                        color: .orange
                    )

                    // Add meal card
                    Button(action: {
                        showAddMeal = true
                    }) {
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray6))
                                    .frame(width: 60, height: 60)

                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                            }

                            Text("Add Meal")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .frame(width: 120, height: 150)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Weekly Progress")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    // Calorie progress
                    weeklyProgressCard(
                        title: "Calories",
                        averageValue: "1,850",
                        goalValue: "2,000",
                        progress: 0.92,
                        color: .orange
                    )

                    // Weight progress
                    weeklyProgressCard(
                        title: "Weight",
                        averageValue: userProfile?.weight != nil ? String(format: "%.1f kg", userProfile!.weight) : "0 kg",
                        goalValue: "75.0 kg",
                        progress: 0.85,
                        color: .purple,
                        showTrend: true,
                        trendDirection: .down,
                        trendValue: "-0.5 kg"
                    )

                    // Exercise progress
                    weeklyProgressCard(
                        title: "Exercise",
                        averageValue: "35 min",
                        goalValue: "45 min",
                        progress: 0.78,
                        color: .green,
                        showTrend: true,
                        trendDirection: .up,
                        trendValue: "+15%"
                    )
                }
                .padding(.horizontal)
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    // Some quick action buttons
                    quickActionButton(
                        title: "Log Water",
                        icon: "drop.fill",
                        color: .blue
                    ) {
                        // Water logging action
                    }

                    quickActionButton(
                        title: "Log Exercise",
                        icon: "figure.walk",
                        color: .green
                    ) {
                        // Exercise logging action
                    }

                    quickActionButton(
                        title: "Food Scanner",
                        icon: "barcode.viewfinder",
                        color: .orange
                    ) {
                        // Barcode scanner action
                    }

                    quickActionButton(
                        title: "Meal Suggestions",
                        icon: "fork.knife",
                        color: .purple
                    ) {
                        // Meal suggestions action
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Helper Views

    private func mealCard(title: String, time: String, calories: Double, carbs: Double, protein: Double, fat: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Meal header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)

                    Text(time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(Int(calories))")
                    .font(.headline)
                    .foregroundColor(color) +
                    Text(" cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Macro nutrients
            HStack {
                macroLabel(title: "Carbs", value: "\(Int(carbs))g", color: .blue)
                Spacer()
                macroLabel(title: "Protein", value: "\(Int(protein))g", color: .green)
                Spacer()
                macroLabel(title: "Fat", value: "\(Int(fat))g", color: .yellow)
            }
        }
        .padding()
        .frame(width: 200, height: 150)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }

    private func macroLabel(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func weeklyProgressCard(
        title: String,
        averageValue: String,
        goalValue: String,
        progress: CGFloat,
        color: Color,
        showTrend: Bool = false,
        trendDirection: TrendDirection = .neutral,
        trendValue: String = ""
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            Text(title)
                .font(.headline)

            // Circular progress
            HStack {
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(color, lineWidth: 8)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 14, weight: .bold))
                }

                VStack(alignment: .leading, spacing: 5) {
                    ValueLabel(title: "Average", value: averageValue)
                    ValueLabel(title: "Goal", value: goalValue)

                    if showTrend {
                        HStack(spacing: 3) {
                            Image(systemName: trendDirection.iconName)
                                .font(.caption)
                                .foregroundColor(trendDirection.color)

                            Text(trendValue)
                                .font(.caption)
                                .foregroundColor(trendDirection.color)
                        }
                    }
                }
                .padding(.leading, 5)
            }
        }
        .padding()
        .frame(width: 180, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }

    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(color)
                    )

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 100, height: 110)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
        }
    }

    // MARK: - Helper Types and Methods

    private func dayFormatter(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    enum TrendDirection {
        case up, down, neutral

        var iconName: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .blue
            case .neutral: return .gray
            }
        }
    }

    struct ValueLabel: View {
        let title: String
        let value: String

        var body: some View {
            HStack(spacing: 5) {
                Text(title + ":")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline.bold())
            }
        }
    }
}

#Preview {
    DashboardView()
}
