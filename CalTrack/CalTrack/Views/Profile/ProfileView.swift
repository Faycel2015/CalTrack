//
//  ProfileView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

// Profile View - Shows user profile
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationView {
            if let profile = userProfiles.first {
                List {
                    Section(header: Text("Personal Information")) {
                        ProfileInfoRow(label: "Name", value: profile.name)
                        ProfileInfoRow(label: "Age", value: "\(profile.age) years")
                        ProfileInfoRow(label: "Gender", value: profile.gender.rawValue)
                    }
                    
                    Section(header: Text("Body Measurements")) {
                        ProfileInfoRow(label: "Height", value: "\(Int(profile.height)) cm")
                        ProfileInfoRow(label: "Weight", value: "\(Int(profile.weight)) kg")
                    }
                    
                    Section(header: Text("Activity & Goals")) {
                        ProfileInfoRow(label: "Activity Level", value: profile.activityLevel.rawValue)
                        ProfileInfoRow(label: "Weight Goal", value: profile.weightGoal.rawValue)
                    }
                    
                    Section(header: Text("Nutrition Targets")) {
                        ProfileInfoRow(label: "Daily Calories", value: "\(Int(profile.dailyCalorieGoal)) cal")
                        
                        HStack {
                            Text("Macro Distribution")
                            Spacer()
                            Text("Carbs: \(Int(profile.carbPercentage * 100))% • Protein: \(Int(profile.proteinPercentage * 100))% • Fat: \(Int(profile.fatPercentage * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        ProfileInfoRow(label: "Carbs Target", value: "\(Int(profile.carbGoalGrams))g")
                        ProfileInfoRow(label: "Protein Target", value: "\(Int(profile.proteinGoalGrams))g")
                        ProfileInfoRow(label: "Fat Target", value: "\(Int(profile.fatGoalGrams))g")
                    }
                    
                    Button("Edit Profile") {
                        showEditProfile = true
                    }
                }
                .navigationTitle("Profile")
                .sheet(isPresented: $showEditProfile) {
                    OnboardingView(modelContext: modelContext)
                }
            }
        }
    }
}

// Profile Info Row Helper
struct ProfileInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}sheet(isPresented: $showEditProfile) {
                    OnboardingView(modelContext: modelContext)
                }
            } else {
                VStack {
                    Text("No Profile Found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Button("Create Profile") {
                        showEditProfile = true
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
                .navigationTitle("Profile")
                .sheet(isPresented: $showEditProfile) {
                    OnboardingView(modelContext: modelContext)
                }
                

#Preview {
    ProfileView()
}
