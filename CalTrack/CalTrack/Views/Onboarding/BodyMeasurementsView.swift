//
//  BodyMeasurementsView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

// Step 2: Body Measurements
private var bodyMeasurementsView: some View {
    VStack(alignment: .leading, spacing: 20) {
        Text("Body Measurements")
            .font(.title2.bold())
            .padding(.bottom, 5)
        
        VStack(alignment: .leading) {
            Text("Height (cm)")
                .font(.headline)
            TextField("Enter your height in cm", text: $viewModel.heightCm)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
            
            if !viewModel.heightIsValid {
                Text("Please enter a valid height")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        
        VStack(alignment: .leading) {
            Text("Weight (kg)")
                .font(.headline)
            TextField("Enter your weight in kg", text: $viewModel.weightKg)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
            
            if !viewModel.weightIsValid {
                Text("Please enter a valid weight")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    .cardStyle()
}

#Preview {
    BodyMeasurementsView()
}
