//
//  BarcodeScannerView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = BarcodeScannerViewModel()
    @Environment(\.presentationMode) private var presentationMode
    
    // Callback for when a food item is successfully scanned
    var onFoodItemScanned: ((FoodItem) -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreviewView(barcodeService: viewModel.barcodeService)
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
            viewModel.requestCameraPermission()
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
                onFoodItemScanned?(foodItem)
                viewModel.addToMeal()
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

// Camera Preview Wrapper
struct CameraPreviewView: UIViewRepresentable {
    let barcodeService: BarcodeService
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let setupSuccess = barcodeService.setupBarcodeScanner(in: view) { _ in
            // Barcode handling is done in the ViewModel
        }
        
        if !setupSuccess {
            let label = UILabel()
            label.text = "Camera unavailable"
            label.textColor = .white
            label.textAlignment = .center
            label.frame = view.bounds
            view.addSubview(label)
        } else {
            barcodeService.startScanning()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        barcodeService.updatePreviewLayerFrame(frame: uiView.bounds)
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
