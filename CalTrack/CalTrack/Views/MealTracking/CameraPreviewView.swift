//
//  CameraPreviewView.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import AVFoundation

/// UIViewRepresentable for displaying the camera preview with barcode scanning
struct CameraPreviewView: UIViewRepresentable {
    // MARK: - Properties
    
    var barcodeService: BarcodeService
    
    // Optional callback to handle barcode detection directly
    var onBarcodeDetected: ((String) -> Void)?
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: CameraPreviewView
        
        init(_ parent: CameraPreviewView) {
            self.parent = parent
        }
    }
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        // Setup barcode scanner with callback
        let setupSuccess = barcodeService.setupBarcodeScanner(in: view) { barcode in
            // Pass the barcode to the provided callback if available
            onBarcodeDetected?(barcode)
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
        barcodeService.updatePreviewLayerFrame(frame: uiView.bounds)
    }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        // Access the barcodeService via the coordinator to stop scanning
        // This ensures resources are properly released when the view disappears
        coordinator.parent.barcodeService.stopScanning()
    }
}
