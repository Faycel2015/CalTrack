//
//  BarcodeService.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import AVFoundation
import UIKit
import SwiftUI

/// Service for barcode scanning and food product lookup
@MainActor
class BarcodeService: NSObject {
    // MARK: - Properties
    
    // Capture session for camera
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Current capture session status
    private var isScanning: Bool = false
    
    // Food database API configuration
    private let foodDbBaseURL = "https://world.openfoodfacts.org/api/v0/product/"
    private let urlSession: URLSession
    
    // Completion handler for barcode detection
    private var onBarcodeDetected: ((String) -> Void)?
    
    // Result processing
    private var lastScannedCode: String?
    private let debounceInterval: TimeInterval = 3.0 // Seconds between scanning the same barcode
    private var lastScanTime: Date?
    
    // MARK: - Initializer
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Initialize the barcode scanner and configure camera
    /// - Parameters:
    ///   - cameraView: UIView to display camera preview
    ///   - completion: Callback for when a barcode is scanned
    /// - Returns: Boolean indicating if setup was successful
    func setupBarcodeScanner(in cameraView: UIView, completion: @escaping (String) -> Void) -> Bool {
        // Store completion handler
        self.onBarcodeDetected = completion
        
        // Create capture session
        let captureSession = AVCaptureSession()
        
        // Configure camera input
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return false
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return false
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return false
        }
        
        // Configure metadata output
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = supportedBarcodeTypes
        } else {
            return false
        }
        
        // Configure preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = cameraView.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        cameraView.layer.addSublayer(previewLayer)
        
        // Store references
        self.captureSession = captureSession
        self.previewLayer = previewLayer
        
        return true
    }
    
    /// Start the barcode scanning session
    nonisolated func startScanning() {
        Task { @MainActor in
            guard let captureSession = captureSession, !isScanning else { return }
            
            isScanning = true
            captureSession.startRunning()
        }
    }
    
    /// Stop the barcode scanning session
    nonisolated func stopScanning() {
        Task { @MainActor in
            guard let captureSession = captureSession, isScanning else { return }
            
            captureSession.stopRunning()
            isScanning = false
        }
    }
    
    /// Update the preview layer frame
    /// - Parameter frame: New frame for the preview layer
    func updatePreviewLayerFrame(frame: CGRect) {
        previewLayer?.frame = frame
    }
    
    /// Toggle device torch/flashlight
    /// - Returns: Boolean indicating if torch is now on
    func toggleTorch() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else {
            return false
        }
        
        do {
            try device.lockForConfiguration()
            
            if device.torchMode == .on {
                device.torchMode = .off
            } else {
                try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
            }
            
            device.unlockForConfiguration()
            return device.torchMode == .on
        } catch {
            return false
        }
    }
    
    /// Look up product information by barcode
    /// - Parameter barcode: The scanned barcode
    /// - Returns: Food item with nutritional information
    func lookupProductByBarcode(_ barcode: String) async throws -> FoodItem {
        // Construct URL
        guard let url = URL(string: "\(foodDbBaseURL)\(barcode).json") else {
            throw BarcodeServiceError.invalidURL
        }
        
        // Send request - nonisolated work
        let (data, response) = try await urlSession.data(from: url)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BarcodeServiceError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw BarcodeServiceError.requestFailed(statusCode: httpResponse.statusCode)
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? Int,
              status == 1,
              let product = json["product"] as? [String: Any] else {
            throw BarcodeServiceError.invalidResponseFormat
        }
        
        // Extract product information and return the FoodItem
        return try parseFoodData(product, barcode: barcode)
    }
    
    /// Check if the device supports barcode scanning
    /// - Returns: Boolean indicating support
    class func isScanningSupported() -> Bool {
        return AVCaptureDevice.default(for: .video) != nil
    }
    
    // MARK: - Private Properties
    
    /// Supported barcode formats
    private var supportedBarcodeTypes: [AVMetadataObject.ObjectType] {
        return [
            .ean8,
            .ean13,
            .upce,
            .code39,
            .code128,
            .code93
        ]
    }
    
    // MARK: - Private Methods
    
    /// Parse food data from API response
    /// - Parameters:
    ///   - productData: Dictionary containing product data
    ///   - barcode: The scanned barcode
    /// - Returns: Food item with nutritional information
    private func parseFoodData(_ productData: [String: Any], barcode: String) throws -> FoodItem {
        // Extract basic product info
        guard let productName = productData["product_name"] as? String else {
            throw BarcodeServiceError.missingProductName
        }
        
        // Extract serving size
        let servingSizeStr = (productData["serving_size"] as? String) ?? "100g"
        
        // Extract nutritional values
        let nutriments = productData["nutriments"] as? [String: Any] ?? [:]
        
        // Extract per serving values if available, fallback to per 100g
        let caloriesPer100g = (nutriments["energy-kcal_100g"] as? Double) ?? (nutriments["energy-kcal"] as? Double) ?? 0
        let carbsPer100g = (nutriments["carbohydrates_100g"] as? Double) ?? (nutriments["carbohydrates"] as? Double) ?? 0
        let proteinPer100g = (nutriments["proteins_100g"] as? Double) ?? (nutriments["proteins"] as? Double) ?? 0
        let fatPer100g = (nutriments["fat_100g"] as? Double) ?? (nutriments["fat"] as? Double) ?? 0
        
        // Optional nutrients
        let sugarPer100g = (nutriments["sugars_100g"] as? Double) ?? (nutriments["sugars"] as? Double)
        let fiberPer100g = (nutriments["fiber_100g"] as? Double) ?? (nutriments["fiber"] as? Double)
        let sodiumPer100g = (nutriments["sodium_100g"] as? Double) ?? (nutriments["sodium"] as? Double)
        let saturatedFatPer100g = (nutriments["saturated-fat_100g"] as? Double) ?? (nutriments["saturated-fat"] as? Double)
        let cholesterolPer100g = (nutriments["cholesterol_100g"] as? Double) ?? (nutriments["cholesterol"] as? Double)
        let transFatPer100g = (nutriments["trans-fat_100g"] as? Double) ?? (nutriments["trans-fat"] as? Double)
        
        // Create food item matching your existing model
        return FoodItem(
            name: productName,
            servingSize: servingSizeStr,
            servingQuantity: 1.0,
            calories: caloriesPer100g,
            carbs: carbsPer100g,
            protein: proteinPer100g,
            fat: fatPer100g,
            sugar: sugarPer100g,
            fiber: fiberPer100g,
            sodium: sodiumPer100g,
            cholesterol: cholesterolPer100g,
            saturatedFat: saturatedFatPer100g,
            transFat: transFatPer100g,
            isCustom: false,
            barcode: barcode,
            foodDatabaseId: barcode,
            isFavorite: false,
            useCount: 0
        )
    }
    
    /// Provide haptic feedback when barcode is detected
    private func provideHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension BarcodeService: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else {
            return
        }
        
        Task { @MainActor in
            // Check if we're debouncing this barcode
            let currentTime = Date()
            if let lastCode = lastScannedCode, lastCode == stringValue,
               let lastTime = lastScanTime, currentTime.timeIntervalSince(lastTime) < debounceInterval {
                // Skip this scan (debounce)
                return
            }
            
            // Update scan tracking
            lastScannedCode = stringValue
            lastScanTime = currentTime
            
            // Notify listener of barcode detection
            onBarcodeDetected?(stringValue)
            
            // Optional: Provide haptic feedback
            provideHapticFeedback()
        }
    }
}

// MARK: - Errors

/// Errors that can occur during barcode scanning and product lookup
enum BarcodeServiceError: Error, Sendable {
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int)
    case invalidResponseFormat
    case missingProductName
    case cameraPermissionDenied
    case cameraNotAvailable
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL for product lookup"
        case .invalidResponse:
            return "Invalid response from server"
        case .requestFailed(let statusCode):
            return "Request failed with status code \(statusCode)"
        case .invalidResponseFormat:
            return "Product information format is invalid"
        case .missingProductName:
            return "Product name is missing"
        case .cameraPermissionDenied:
            return "Camera permission denied"
        case .cameraNotAvailable:
            return "Camera is not available on this device"
        }
    }
}
