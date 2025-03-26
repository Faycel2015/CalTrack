//
//  BarcodeScannerView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import AVFoundation
import SwiftData

struct BarcodeScannerView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = BarcodeScannerViewModel()
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var modelContext
    
    // Callback for when a food item is successfully scanned
    var onFoodItemScanned: ((FoodItem) -> Void)?
    
    // MARK: - Initialization
    
    init(onFoodItemScanned: ((FoodItem) -> Void)? = nil) {
        self.onFoodItemScanned = onFoodItemScanned
        // Note: We can't use modelContext here as it needs @Environment
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreviewView(
                barcodeService: viewModel.barcodeService,
                onBarcodeDetected: { barcode in
                    viewModel.handleScannedBarcode(barcode)
                }
            )
            .edgesIgnoringSafeArea(.all)
            
            // Scanner Overlay
            VStack {
                // Top Controls
                scannerHeader
                
                Spacer()
                
                // Scanner Guide
                scannerGuide
                
                Spacer()
                
                // Bottom Content
                scannerBottomContent
            }
        }
        .alert(isPresented: $viewModel.showPermissionAlert) {
            cameraPermissionAlert
        }
        .sheet(isPresented: $viewModel.showManualEntry) {
            ManualFoodEntryView()
        }
        .onAppear {
            // Set model context - Fixed: removed unnecessary cast
            viewModel.modelContext = modelContext
            // Request camera permission
            viewModel.requestCameraPermission()
        }
        .onDisappear {
            // Make sure to stop scanning when view disappears
            viewModel.stopScanning()
        }
    }
    
    // MARK: - Subviews
    
    private var scannerHeader: some View {
        HStack {
            // Close Button
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            
            Spacer()
            
            // Torch Toggle
            Button(action: viewModel.toggleTorch) {
                Image(systemName: viewModel.isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
        }
        .padding()
    }
    
    private var scannerGuide: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white, lineWidth: 3)
            .frame(width: 250, height: 150)
            .background(Color.white.opacity(0.1))
            .overlay(
                Text("Align barcode within frame")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(4)
                    .padding(.top, 130)
            )
    }
    
    private var scannerBottomContent: some View {
        VStack(spacing: 15) {
            // Loading State
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .padding()
            }
            // Food Item Found
            else if let foodItem = viewModel.scannedFoodItem {
                foodItemDetailsView(for: foodItem)
            }
            // Error State
            else if let error = viewModel.error {
                errorView(for: error)
            }
            // Default Manual Entry
            else {
                manualEntryButton
            }
        }
        .padding(.bottom, 30)
    }
    
    private func foodItemDetailsView(for foodItem: FoodItem) -> some View {
        VStack(spacing: 8) {
            Text(foodItem.name)
                .font(.headline)
                .foregroundColor(.white)
            
            Text("\(Int(foodItem.calories)) cal | C: \(Int(foodItem.carbs))g | P: \(Int(foodItem.protein))g | F: \(Int(foodItem.fat))g")
                .font(.subheadline)
                .foregroundColor(.white)
            
            Button(action: {
                // Pass the food item to the callback if provided
                onFoodItemScanned?(foodItem)
                // Add to meal using the view model
                viewModel.addToMeal()
                // Dismiss the scanner
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Add to Meal")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
        )
        .padding(.horizontal)
    }
    
    private func errorView(for error: Error) -> some View {
        VStack(spacing: 8) {
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Button(action: viewModel.resetScan) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
        )
        .padding(.horizontal)
    }
    
    private var manualEntryButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
            viewModel.showManualEntry = true
        }) {
            Text("Enter food manually")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
        }
    }
    
    private var cameraPermissionAlert: Alert {
        Alert(
            title: Text("Camera Access Required"),
            message: Text("Please allow camera access in Settings to scan barcodes."),
            primaryButton: .default(Text("Open Settings"), action: viewModel.openSettings),
            secondaryButton: .cancel(Text("Cancel"), action: { presentationMode.wrappedValue.dismiss() })
        )
    }
}

// Placeholder for Manual Food Entry View
struct ManualFoodEntryView: View {
    var body: some View {
        Text("Manual Food Entry")
            .font(.title)
            .padding()
    }
}

#Preview {
    BarcodeScannerView()
}
