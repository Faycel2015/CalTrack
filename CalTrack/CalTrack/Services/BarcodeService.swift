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
    func startScanning() {
        guard let captureSession = captureSession, !isScanning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.isScanning = true
            captureSession.startRunning()
        }
    }
    
    /// Stop the barcode scanning session
    func stopScanning() {
        guard let captureSession = captureSession, isScanning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            captureSession.stopRunning()
            self?.isScanning = false
        }
    }
    
    /// Update the preview layer frame
    /// - Parameter frame: New frame for the preview layer
    func updatePreviewLayerFrame(frame: CGRect) {
        previewLayer?.frame = frame
    }
    
    /// Look up product information by barcode
    /// - Parameter barcode: The scanned barcode
    /// - Returns: Food item with nutritional information
    func lookupProductByBarcode(_ barcode: String) async throws -> FoodItem {
        // Construct URL
        guard let url = URL(string: "\(foodDbBaseURL)\(barcode).json") else {
            throw BarcodeServiceError.invalidURL
        }
        
        // Send request
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
        
        // Extract product information
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
        
        // Create food item
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
            saturatedFat: saturatedFatPer100g,
            isCustom: false,
            barcode: barcode,
            foodDatabaseId: barcode
        )
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension BarcodeService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if we have barcode metadata
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else {
            return
        }
        
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
    
    /// Provide haptic feedback when barcode is detected
    private func provideHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - SwiftUI View Extension

/// SwiftUI view for barcode scanning
struct BarcodeScannerView: UIViewRepresentable {
    // MARK: - Properties
    
    var barcodeService: BarcodeService
    var onBarcodeScanned: (String) -> Void
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        // Setup barcode scanner
        let setupSuccess = barcodeService.setupBarcodeScanner(in: view) { barcode in
            onBarcodeScanned(barcode)
        }
        
        if !setupSuccess {
            // Show error message if setup fails
            let label = UILabel()
            label.text = "Camera permission denied or hardware unavailable"
            label.textColor = .white
            label.textAlignment = .center
            label.frame = view.bounds
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(label)
        } else {
            // Start scanning
            barcodeService.startScanning()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame if view size changes
        barcodeService.updatePreviewLayerFrame(frame: uiView.layer.bounds)
    }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        // This cleanup code is needed but has no effect because we can't
        // access the barcodeService from this static method
        // In a real app, use a coordinator to hold the barcodeService reference
    }
}

// MARK: - SwiftUI Barcode Scanner View

/// SwiftUI container view for barcode scanning with UI overlay
struct BarcodeScannerContainerView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = BarcodeScannerViewModel()
    @Environment(\.presentationMode) private var presentationMode
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Camera view
            BarcodeScannerView(
                barcodeService: viewModel.barcodeService,
                onBarcodeScanned: { barcode in
                    viewModel.handleScannedBarcode(barcode)
                }
            )
            .edgesIgnoringSafeArea(.all)
            
            // Scanner overlay
            VStack {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.toggleTorch()
                    }) {
                        Image(systemName: viewModel.isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                }
                .padding()
                
                Spacer()
                
                // Scanner guide
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white, lineWidth: 3)
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
                
                Spacer()
                
                // Status and manual entry
                VStack(spacing: 15) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .padding()
                    } else if let foodItem = viewModel.scannedFoodItem {
                        // Food item found
                        VStack(spacing: 8) {
                            Text(foodItem.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("\(Int(foodItem.calories)) cal | C: \(Int(foodItem.carbs))g | P: \(Int(foodItem.protein))g | F: \(Int(foodItem.fat))g")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Button(action: {
                                viewModel.addToMeal()
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Add to Meal")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white)
                                    )
                            }
                            .padding(.top, 5)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.7))
                        )
                        .padding(.horizontal)
                    } else if let error = viewModel.error {
                        // Error
                        VStack(spacing: 8) {
                            Text(error.localizedDescription)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                viewModel.resetScan()
                            }) {
                                Text("Try Again")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white)
                                    )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.7))
                        )
                        .padding(.horizontal)
                    } else {
                        // Manual entry option
                        Button(action: {
                            // Navigate to manual entry
                            presentationMode.wrappedValue.dismiss()
                            viewModel.showManualEntry = true
                        }) {
                            Text("Enter food manually")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.5))
                                )
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            // Request camera permission
            viewModel.requestCameraPermission()
        }
        .sheet(isPresented: $viewModel.showManualEntry) {
            // Manual food entry view would go here
            Text("Manual Food Entry")
                .font(.headline)
                .padding()
        }
        .alert(isPresented: $viewModel.showPermissionAlert) {
            Alert(
                title: Text("Camera Access Required"),
                message: Text("Please allow camera access in Settings to scan barcodes."),
                primaryButton: .default(Text("Open Settings"), action: {
                    viewModel.openSettings()
                }),
                secondaryButton: .cancel(Text("Cancel"), action: {
                    presentationMode.wrappedValue.dismiss()
                })
            )
        }
    }
}

// MARK: - BarcodeScannerViewModel

/// View model for barcode scanner
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
    
    // MARK: - Methods
    
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
                let foodItem = try await barcodeService.lookupProductByBarcode(barcode)
                
                await MainActor.run {
                    self.scannedFoodItem = foodItem
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Add the scanned food item to the meal
    func addToMeal() {
        // In a real app, this would add the food item to the current meal
        // For now, just reset the scanner
        resetScan()
    }
    
    /// Reset the scanner state
    func resetScan() {
        scannedFoodItem = nil
        error = nil
    }
    
    /// Toggle the torch/flashlight
    func toggleTorch() {
        // In a real app, this would toggle the device torch
        isTorchOn.toggle()
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
                    DispatchQueue.main.async {
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

// MARK: - Errors

/// Errors that can occur during barcode scanning and product lookup
enum BarcodeServiceError: Error {
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
        // Notify listener of barcode detection
        onBarcodeDetected?(stringValue)
        
        // Optional: Provide haptic feedback
        provideHapticFeedback()
    }
    
    /// Provide haptic feedback when barcode is detected
    private func provideHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - SwiftUI View Extension

/// SwiftUI view for barcode scanning with coordinator pattern
struct BarcodeScannerView: UIViewRepresentable {
    // MARK: - Properties
    
    var barcodeService: BarcodeService
    var onBarcodeScanned: (String) -> Void
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: BarcodeScannerView
        
        init(_ parent: BarcodeScannerView) {
            self.parent = parent
        }
        
        // Optionally add additional coordinator methods as needed
    }
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        // Setup barcode scanner
        let setupSuccess = barcodeService.setupBarcodeScanner(in: view) { barcode in
            onBarcodeScanned(barcode)
        }
        
        if !setupSuccess {
            // Show error message if setup fails
            let label = UILabel()
            label.text = "Camera permission denied or hardware unavailable"
            label.textColor = .white
            label.textAlignment = .center
            label.frame = view.bounds
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(label)
        } else {
            // Start scanning
            barcodeService.startScanning()
        }
        
        // Store the barcodeService in the coordinator
        context.coordinator.parent.barcodeService = barcodeService
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame if view size changes
        barcodeService.updatePreviewLayerFrame(frame: uiView.layer.bounds)
    }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        // Now we can access the barcodeService via the coordinator
        coordinator.parent.barcodeService.stopScanning()
    }
}

/// SwiftUI container view for barcode scanning with UI overlay
struct BarcodeScannerContainerView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = BarcodeScannerViewModel()
    @Environment(\.presentationMode) private var presentationMode
    
    // Optional callback for when a food item is successfully added
    var onFoodItemAdded: ((FoodItem) -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Camera view
            BarcodeScannerView(
                barcodeService: viewModel.barcodeService,
                onBarcodeScanned: { barcode in
                    viewModel.handleScannedBarcode(barcode)
                }
            )
            .edgesIgnoringSafeArea(.all)
            
            // Scanner overlay
            VStack {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.toggleTorch()
                    }) {
                        Image(systemName: viewModel.isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                }
                .padding()
                
                Spacer()
                
                // Scanner guide
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white, lineWidth: 3)
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
                
                Spacer()
                
                // Status and manual entry
                VStack(spacing: 15) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .padding()
                    } else if let foodItem = viewModel.scannedFoodItem {
                        // Food item found
                        VStack(spacing: 8) {
                            Text(foodItem.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("\(Int(foodItem.calories)) cal | C: \(Int(foodItem.carbs))g | P: \(Int(foodItem.protein))g | F: \(Int(foodItem.fat))g")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Button(action: {
                                if let callback = onFoodItemAdded {
                                    callback(foodItem)
                                }
                                viewModel.addToMeal()
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Add to Meal")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white)
                                    )
                            }
                            .padding(.top, 5)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.7))
                        )
                        .padding(.horizontal)
                    } else if let error = viewModel.error {
                        // Error
                        VStack(spacing: 8) {
                            Text(error.localizedDescription)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                viewModel.resetScan()
                            }) {
                                Text("Try Again")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white)
                                    )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.7))
                        )
                        .padding(.horizontal)
                    } else {
                        // Manual entry option
                        Button(action: {
                            // Navigate to manual entry
                            presentationMode.wrappedValue.dismiss()
                            viewModel.showManualEntry = true
                        }) {
                            Text("Enter food manually")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.5))
                                )
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            // Request camera permission
            viewModel.requestCameraPermission()
        }
        .onDisappear {
            // Ensure scanning stops when view disappears
            viewModel.stopScanning()
        }
        .sheet(isPresented: $viewModel.showManualEntry) {
            // Manual food entry view would go here
            Text("Manual Food Entry")
                .font(.headline)
                .padding()
        }
        .alert(isPresented: $viewModel.showPermissionAlert) {
            Alert(
                title: Text("Camera Access Required"),
                message: Text("Please allow camera access in Settings to scan barcodes."),
                primaryButton: .default(Text("Open Settings"), action: {
                    viewModel.openSettings()
                }),
                secondaryButton: .cancel(Text("Cancel"), action: {
                    presentationMode.wrappedValue.dismiss()
                })
            )
        }
    }
}

// MARK: - BarcodeScannerViewModel

/// View model for barcode scanner
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
    
    // MARK: - Methods
    
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
                let foodItem = try await barcodeService.lookupProductByBarcode(barcode)
                
                await MainActor.run {
                    self.scannedFoodItem = foodItem
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Add the scanned food item to the meal
    func addToMeal() {
        // In a real app, this would add the food item to the current meal
        // For now, just reset the scanner
        resetScan()
    }
    
    /// Reset the scanner state
    func resetScan() {
        scannedFoodItem = nil
        error = nil
    }
    
    /// Stop scanning
    func stopScanning() {
        barcodeService.stopScanning()
    }
    
    /// Toggle the torch/flashlight
    func toggleTorch() {
        // In a real implementation, this would toggle the device torch
        // using AVCaptureDevice's torch mode
        isTorchOn.toggle()
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
                    DispatchQueue.main.async {
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
