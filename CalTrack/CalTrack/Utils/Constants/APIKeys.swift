//
//  APIKeys.swift
//  CalTrack
//
//  Created by FayTek on 4/9/25.
//

import Foundation

/// Manages API keys and sensitive configuration values
struct APIConfig {
    /// Singleton instance
    static let shared = APIConfig()
    
    /// Google Gemini API key
    var geminiAPIKey: String {
        // 1. Try to get key from environment variables (for CI/CD and development)
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // 2. Try to get from configuration plist (for local development or included in the app bundle)
        if let plistKey = getKeyFromConfigFile(for: "GeminiAPIKey"), !plistKey.isEmpty {
            return plistKey
        }
        
        // 3. Try to get from UserDefaults (for setting via Settings bundle or app preferences)
        if let userDefaultsKey = UserDefaults.standard.string(forKey: "GeminiAPIKey"), !userDefaultsKey.isEmpty {
            return userDefaultsKey
        }
        
        // 4. For development only - return dummy key
        #if DEBUG
        // This dummy key will only be used in DEBUG builds
        return "DUMMY_KEY_FOR_DEVELOPMENT_ONLY"
        #else
        // In production, we should have a key from one of the above sources
        fatalError("Gemini API key not found in environment, config file, or UserDefaults")
        #endif
    }
    
    // MARK: - Private Methods
    
    /// Get a key from the configuration file
    /// - Parameter key: The key to retrieve
    /// - Returns: The key value or nil if not found
    private func getKeyFromConfigFile(for key: String) -> String? {
        // Look for a configuration plist that isn't committed to source control
        guard let configPath = Bundle.main.path(forResource: "ApiConfig", ofType: "plist"),
              let configDict = NSDictionary(contentsOfFile: configPath) as? [String: Any] else {
            return nil
        }
        
        return configDict[key] as? String
    }
    
    /// Saves an API key to UserDefaults
    /// - Parameters:
    ///   - key: API key to save
    ///   - keyIdentifier: Identifier for the key in UserDefaults
    func saveAPIKey(_ key: String, forIdentifier keyIdentifier: String) {
        UserDefaults.standard.set(key, forKey: keyIdentifier)
    }
}
