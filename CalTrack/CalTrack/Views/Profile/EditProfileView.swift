//
//  EditProfileView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditProfileViewModel
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: EditProfileViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Personal Information Section
                Section(header: Text("Personal Information")) {
                    personalInfoFields
                }
                
                // Body Measurements Section
                Section(header: Text("Body Measurements")) {
                    bodyMeasurementFields
                }
                
                // Goals and Activity Section
                Section(header: Text("Goals & Activity")) {
                    goalsAndActivityFields
                }
                
                // Macro Distribution Section
                Section(header: Text("Macro Distribution")) {
                    macroDistributionFields
                }
                
                // Danger Zone
                Section(header: Text("Account"), footer: Text("Deleting your profile will remove all your data")) {
                    Button(role: .destructive, action: {
                        viewModel.deleteProfile()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Profile")
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    viewModel.saveProfile()
                    dismiss()
                }
                .disabled(!viewModel.isProfileValid)
            )
            .alert(item: $viewModel.error) { error in
                Alert(
                    title: Text("Error"),
                    message: Text(error.localizedDescription),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Personal Information Fields
    
    private var personalInfoFields: some View {
        Group {
            TextField("Full Name", text: $viewModel.name)
                .autocapitalization(.words)
            
            TextField("Age", text: $viewModel.age)
                .keyboardType(.numberPad)
            
            Picker("Gender", selection: $viewModel.gender) {
                ForEach(Gender.allCases) { gender in
                    Text(gender.rawValue).tag(gender)
                }
            }
        }
    }
    
    // MARK: - Body Measurement Fields
    
    private var bodyMeasurementFields: some View {
        Group {
            TextField("Height (cm)", text: $viewModel.heightCm)
                .keyboardType(.decimalPad)
            
            TextField("Weight (kg)", text: $viewModel.weightKg)
                .keyboardType(.decimalPad)
        }
    }
    
    // MARK: - Goals and Activity Fields
    
    private var goalsAndActivityFields: some View {
        Group {
            Picker("Activity Level", selection: $viewModel.activityLevel) {
                ForEach(ActivityLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            
            Picker("Weight Goal", selection: $viewModel.weightGoal) {
                ForEach(WeightGoal.allCases) { goal in
                    Text(goal.rawValue).tag(goal)
                }
            }
            
            // Calorie Goal Preview
            if let calorieGoal = viewModel.dailyCalorieGoal {
                HStack {
                    Text("Daily Calorie Goal")
                    Spacer()
                    Text("\(Int(calorieGoal)) cal")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Macro Distribution Fields
    
    private var macroDistributionFields: some View {
        Group {
            VStack(alignment: .leading) {
                Text("Carbohydrates: \(Int(viewModel.carbPercentage))%")
                Slider(value: $viewModel.carbPercentage, in: 5...70, step: 5)
            }
            
            VStack(alignment: .leading) {
                Text("Protein: \(Int(viewModel.proteinPercentage))%")
                Slider(value: $viewModel.proteinPercentage, in: 5...70, step: 5)
            }
            
            VStack(alignment: .leading) {
                Text("Fat: \(Int(viewModel.fatPercentage))%")
                Slider(value: $viewModel.fatPercentage, in: 5...70, step: 5)
            }
            
            // Total Percentage Warning
            HStack {
                Image(systemName: viewModel.totalPercentage == 100 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(viewModel.totalPercentage == 100 ? .green : .red)
                
                Text("Total: \(Int(viewModel.totalPercentage))%")
                    .font(.subheadline)
                    .foregroundColor(viewModel.totalPercentage == 100 ? .green : .red)
            }
        }
    }
}

// MARK: - View Model

class EditProfileViewModel: ObservableObject {
    // MARK: - Properties
    private let modelContext: ModelContext
    private var userProfile: UserProfile?
    
    @Published var name: String = ""
    @Published var age: String = ""
    @Published var gender: Gender = .notSpecified
    @Published var heightCm: String = ""
    @Published var weightKg: String = ""
    @Published var activityLevel: ActivityLevel = .moderate
    @Published var weightGoal: WeightGoal = .maintain
    @Published var carbPercentage: Double = 40
    @Published var proteinPercentage: Double = 30
    @Published var fatPercentage: Double = 30
    
    @Published var error: Error?
    
    // MARK: - Computed Properties
    
    var isProfileValid: Bool {
        guard
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let ageValue = Int(age), ageValue >= 15 && ageValue <= 100,
            let heightValue = Double(heightCm), heightValue > 0,
            let weightValue = Double(weightKg), weightValue > 0
        else { return false }
        
        return true
    }
    
    var totalPercentage: Double {
        return carbPercentage + proteinPercentage + fatPercentage
    }
    
    var dailyCalorieGoal: Double? {
        guard
            let ageValue = Int(age),
            let heightValue = Double(heightCm),
            let weightValue = Double(weightKg)
        else { return nil }
        
        // Create a temporary profile to calculate goals
        let tempProfile = UserProfile(
            name: name,
            age: ageValue,
            gender: gender,
            height: heightValue,
            weight: weightValue,
            activityLevel: activityLevel,
            weightGoal: weightGoal,
            carbPercentage: carbPercentage / 100,
            proteinPercentage: proteinPercentage / 100,
            fatPercentage: fatPercentage / 100
        )
        
        return tempProfile.dailyCalorieGoal
    }
    
    // MARK: - Initializer
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserProfile()
    }
    
    // MARK: - Methods
    
    private func loadUserProfile() {
        do {
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try modelContext.fetch(descriptor)
            
            if let existingProfile = profiles.first {
                userProfile = existingProfile
                
                name = existingProfile.name
                age = "\(existingProfile.age)"
                gender = existingProfile.gender
                heightCm = "\(existingProfile.height)"
                weightKg = "\(existingProfile.weight)"
                activityLevel = existingProfile.activityLevel
                weightGoal = existingProfile.weightGoal
                carbPercentage = existingProfile.carbPercentage * 100
                proteinPercentage = existingProfile.proteinPercentage * 100
                fatPercentage = existingProfile.fatPercentage * 100
            }
        } catch {
            self.error = error
        }
    }
    
    func saveProfile() {
        guard isProfileValid else { return }
        
        let ageValue = Int(age) ?? 0
        let heightValue = Double(heightCm) ?? 0
        let weightValue = Double(weightKg) ?? 0
        
        let carbPerc = carbPercentage / 100
        let proteinPerc = proteinPercentage / 100
        let fatPerc = fatPercentage / 100
        
        if let existingProfile = userProfile {
            // Update existing profile
            existingProfile.name = name
            existingProfile.age = ageValue
            existingProfile.gender = gender
            existingProfile.height = heightValue
            existingProfile.weight = weightValue
            existingProfile.activityLevel = activityLevel
            existingProfile.weightGoal = weightGoal
            existingProfile.carbPercentage = carbPerc
            existingProfile.proteinPercentage = proteinPerc
            existingProfile.fatPercentage = fatPerc
            
            existingProfile.calculateNutritionGoals()
        } else {
            // Create new profile
            let newProfile = UserProfile(
                name: name,
                age: ageValue,
                gender: gender,
                height: heightValue,
                weight: weightValue,
                activityLevel: activityLevel,
                weightGoal: weightGoal,
                carbPercentage: carbPerc,
                proteinPercentage: proteinPerc,
                fatPercentage: fatPerc
            )
            
            modelContext.insert(newProfile)
        }
        
        do {
            try modelContext.save()
        } catch {
            self.error = error
        }
    }
    
    func deleteProfile() {
        guard let profile = userProfile else { return }
        
        modelContext.delete(profile)
        
        do {
            try modelContext.save()
        } catch {
            self.error = error
        }
    }
}

#Preview {
    EditProfileView(modelContext: try! ModelContainer(for: UserProfile.self).mainContext)
}
