//
//  BarcodeScannerViewModel.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import AVFoundation
import SwiftUI
import SwiftData

/// View model for barcode scanner
@MainActor // Mark the entire class as MainActor
class BarcodeScannerViewModel: ObservableObject {
    // MARK: - Properties
    
    // Services
    let barcodeService = BarcodeService()
    
    // UI State
    @Published var isLoading = false
    @Published var scannedFoodItem: FoodItem?
    @Published var error: Error?
    @Published var showManualEntry = false
    @Published var showPermissionAlert = false
    @Published var isTorchOn = false
    
    // SwiftData Integration
    var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        setupBarcodeCallback()
    }
    
    // MARK: - Methods
    
    /// Set up the callback for barcode detection
    private func setupBarcodeCallback() {
        // This function is called when the CameraPreviewView is created
        // It sets up the callback in BarcodeService.setupBarcodeScanner
    }
    
    /// Handle a scanned barcode
    /// - Parameter barcode: The scanned barcode
    func handleScannedBarcode(_ barcode: String) {
        // Reset previous results
        scannedFoodItem = nil
        error = nil
        isLoading = true
        
        // Look up product information
        Task {
            do {
                // Since BarcodeService.lookupProductByBarcode returns a non-Sendable type (FoodItem)
                // and we're in a @Sendable closure (Task), we need to make sure FoodItem is Sendable
                // or isolate this code properly
                let foodItem = try await barcodeService.lookupProductByBarcode(barcode)
                
                // Since the class is now @MainActor, we don't need MainActor.run here
                self.scannedFoodItem = foodItem
                self.isLoading = false
            } catch {
                // Since the class is now @MainActor, we don't need MainActor.run here
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    /// Add the scanned food item to the database
    func addToMeal() {
        guard let foodItem = scannedFoodItem else { return }
        
        // Record usage of the food item
        foodItem.recordUsage()
        
        // If we have a model context, insert the item
        if let modelContext = modelContext {
            modelContext.insert(foodItem)
            try? modelContext.save()
        }
        
        // Reset the scanner state
        resetScan()
    }
    
    /// Reset the scanner state
    func resetScan() {
        scannedFoodItem = nil
        error = nil
    }
    
    /// Stop scanning when the view disappears
    func stopScanning() {
        barcodeService.stopScanning()
    }
    
    /// Toggle the torch/flashlight
    func toggleTorch() {
        isTorchOn = barcodeService.toggleTorch()
    }
    
    /// Request camera permission
    func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Already authorized
            break
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if !granted {
                    Task { @MainActor in
                        self?.showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            // Permission denied
            showPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    /// Open app settings to allow camera permission
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
