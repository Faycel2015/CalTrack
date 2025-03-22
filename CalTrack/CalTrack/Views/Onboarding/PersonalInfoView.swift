//
//  PersonalInfoView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

struct PersonalInfoView: View {
    @Binding var name: String
    @Binding var age: String
    @Binding var gender: Gender

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
                    .onChange(of: name) { _ in
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
                    .onChange(of: age) { _ in
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
                    ForEach(Gender.allCases) { genderOption in
                        Text(genderOption.rawValue).tag(genderOption)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: gender) { _ in
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

#Preview {
    struct PreviewWrapper: View {
        @State private var name = ""
        @State private var age = ""
        @State private var gender = Gender.notSpecified

        var body: some View {
            PersonalInfoView(
                name: $name,
                age: $age,
                gender: $gender
            )
            .padding()
        }
    }

    return PreviewWrapper()
}
