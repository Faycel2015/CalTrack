//
//  AppFonts.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import SwiftUI
import CoreText

public enum AppFonts {
    // MARK: - Title Styles
    public enum Title {
        public static func large() -> Font {
            Font.custom("SF Pro Text Bold", size: 24)
        }

        public static func medium() -> Font {
            Font.custom("SF Pro Text Semibold", size: 20)
        }

        public static func small() -> Font {
            Font.custom("SF Pro Text Medium", size: 18)
        }
    }

    // MARK: - Body Styles
    public enum Body {
        public static func large() -> Font {
            Font.custom("SF Pro Text Regular", size: 16)
        }

        public static func medium() -> Font {
            Font.custom("SF Pro Text Regular", size: 14)
        }

        public static func small() -> Font {
            Font.custom("SF Pro Text Regular", size: 12)
        }
    }

    // MARK: - Button Styles
    public enum Button {
        public static func primary() -> Font {
            Font.custom("SF Pro Text Semibold", size: 16)
        }

        public static func secondary() -> Font {
            Font.custom("SF Pro Text Medium", size: 14)
        }
    }

    // MARK: - Register Custom Fonts
    public static func registerCustomFonts() {
        _ = Bundle.registerFont(withName: "SF-Pro-Text-Regular", fileExtension: "otf")
        _ = Bundle.registerFont(withName: "SF-Pro-Text-Medium", fileExtension: "otf")
        _ = Bundle.registerFont(withName: "SF-Pro-Text-Semibold", fileExtension: "otf")
        _ = Bundle.registerFont(withName: "SF-Pro-Text-Bold", fileExtension: "otf")
    }
}

extension Bundle {
    static func registerFont(withName name: String, fileExtension: String) -> Bool {
        guard let fontURL = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
            print("Font file not found: \(name).\(fileExtension)")
            return false
        }

        guard let fontData = try? Data(contentsOf: fontURL) as CFData else {
            print("Failed to load font data: \(name).\(fileExtension)")
            return false
        }

        var error: Unmanaged<CFError>?

        if #available(iOS 18.0, *) {
            guard CTFontManagerCreateFontDescriptorsFromData(fontData) is [CTFontDescriptor] else {
                print("Failed to create font descriptors")
                return false
            }

            let success = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)

            if !success {
                print("Error registering font: \(error?.takeRetainedValue().localizedDescription ?? "Unknown error")")
                return false
            }
        } else {
            guard let provider = CGDataProvider(data: fontData),
                  let font = CGFont(provider) else {
                print("Failed to create font")
                return false
            }

            let success = CTFontManagerRegisterGraphicsFont(font, &error)

            if !success {
                print("Error registering font: \(error?.takeRetainedValue().localizedDescription ?? "Unknown error")")
                return false
            }
        }

        return true
    }
}
