//
//  PersonalInfoView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

struct PersonalInfoView: View {
    @Binding var name: String
    @Binding var age: String
    @Binding var gender: UserProfile.Gender

    var onInfoChanged: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title and Description
            VStack(alignment: .leading, spacing: 10) {
                Text("Personal Information")
                    .font(.title2.bold())

                Text("Help us personalize your nutrition tracking")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Name Input
            VStack(alignment: .leading) {
                Text("Full Name")
                    .font(.headline)

                TextField("Enter your name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .onChange(of: name) { oldValue, newValue in
                        onInfoChanged?()
                    }
                if !isNameValid {
                    Text("Please enter a valid name")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // Age Input
            VStack(alignment: .leading) {
                Text("Age")
                    .font(.headline)

                TextField("Enter your age", text: $age)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .onChange(of: age) { oldValue, newValue in
                        onInfoChanged?()
                    }

                if !isAgeValid {
                    Text("Please enter a valid age (15-100)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // Gender Selection
            VStack(alignment: .leading) {
                Text("Gender")
                    .font(.headline)

                Picker("Gender", selection: $gender) {
                    ForEach(UserProfile.Gender.allCases) { genderOption in
                        Text(genderOption.rawValue).tag(genderOption)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: gender) { oldValue, newValue in
                    onInfoChanged?()
                }
            }

            // Gender Information
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)

                Text("This helps us calculate your nutritional needs more accurately")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }

    // MARK: - Validation

    private var isNameValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isAgeValid: Bool {
        guard let ageValue = Int(age) else { return false }
        return ageValue >= 15 && ageValue <= 100
    }
}

// Define a simple mock version of UserProfile.Gender just for the preview
// This allows the preview to compile without needing the actual UserProfile dependency
#if DEBUG
enum GenderPreview: String, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    case nonBinary = "Non-binary"
    case notSpecified = "Prefer not to say"
    
    var id: String { self.rawValue }
}

extension GenderPreview {
    static func convert(to userProfileGender: GenderPreview) -> UserProfile.Gender {
        switch userProfileGender {
        case .male: return .male
        case .female: return .female
        case .nonBinary: return .nonBinary
        case .notSpecified: return .notSpecified
        }
    }
}
#endif

#Preview {
    struct PreviewWrapper: View {
        @State private var name = ""
        @State private var age = ""
        @State private var gender = GenderPreview.notSpecified
        
        var body: some View {
            PersonalInfoView(
                name: $name,
                age: $age,
                gender: Binding<UserProfile.Gender>(
                    get: { UserProfile.Gender.notSpecified },
                    set: { _ in }
                )
            )
            .padding()
        }
    }

    return PreviewWrapper()
}
