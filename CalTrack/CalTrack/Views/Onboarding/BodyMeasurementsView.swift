//
//  BodyMeasurementsView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import SwiftData

struct BodyMeasurementsView: View {
    @Binding var heightCm: String
    @Binding var weightKg: String
    var heightIsValid: Bool
    var weightIsValid: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Body Measurements")
                .font(.title2.bold())
                .padding(.bottom, 5)
            
            VStack(alignment: .leading) {
                Text("Height (cm)")
                    .font(.headline)
                TextField("Enter your height in cm", text: $heightCm)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                
                if !heightIsValid {
                    Text("Please enter a valid height")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            VStack(alignment: .leading) {
                Text("Weight (kg)")
                    .font(.headline)
                TextField("Enter your weight in kg", text: $weightKg)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                
                if !weightIsValid {
                    Text("Please enter a valid weight")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    BodyMeasurementsView(
        heightCm: .constant("170"),
        weightKg: .constant("70"),
        heightIsValid: true,
        weightIsValid: true
    )
}
