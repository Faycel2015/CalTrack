//
//  AppFonts.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI

/// A centralized collection of font styles for the CalTrack application
public enum AppFonts {
    // MARK: - Title Styles
    public enum Title {
        public static func large() -> Font {
            .system(size: 24, weight: .bold, design: .rounded)
        }
        
        public static func medium() -> Font {
            .system(size: 20, weight: .semibold, design: .rounded)
        }
        
        public static func small() -> Font {
            .system(size: 18, weight: .medium, design: .rounded)
        }
    }
    
    // MARK: - Body Styles
    public enum Body {
        public static func large() -> Font {
            .system(size: 16, weight: .regular, design: .rounded)
        }
        
        public static func medium() -> Font {
            .system(size: 14, weight: .regular, design: .rounded)
        }
        
        public static func small() -> Font {
            .system(size: 12, weight: .regular, design: .rounded)
        }
    }
    
    // MARK: - Button Styles
    public enum Button {
        public static func primary() -> Font {
            .system(size: 16, weight: .semibold, design: .rounded)
        }
        
        public static func secondary() -> Font {
            .system(size: 14, weight: .medium, design: .rounded)
        }
    }
    
    // MARK: - Custom Font Loader (if using custom fonts)
    public static func registerCustomFonts() {
        // Example of how to register custom fonts
        // FontBook.registerFont(from: "CustomFont.ttf")
    }
}

// Optional extension for custom font registration if needed
extension Bundle {
    static func registerFont(withName name: String, fileExtension: String) -> Bool {
        guard let fontURL = Bundle.main.url(forResource: name, withExtension: fileExtension),
              let fontData = try? Data(contentsOf: fontURL) as CFData,
              let provider = CGDataProvider(data: fontData),
              let font = CGFont(provider) else {
            print("Failed to register font: \(name)")
            return false
        }
        
        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterGraphicsFont(font, &error)
        
        if !success {
            print("Error registering font: \(error.debugDescription)")
            return false
        }
        
        return true
    }
}
