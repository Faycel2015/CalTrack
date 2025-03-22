//
//  Logger.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import os.log

/// Comprehensive logging utility for CalTrack
public class Logger {
    /// Singleton instance
    public static let shared = Logger()
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Log levels for different types of logging
    public enum LogLevel {
        case debug
        case info
        case warning
        case error
        case critical
    }
    
    /// Logs a message with a specified log level
    /// - Parameters:
    ///   - message: Message to log
    ///   - level: Log level (default is info)
    ///   - file: Source file (automatically populated)
    ///   - function: Source function (automatically populated)
    ///   - line: Source line number (automatically populated)
    public func log(_ message: String,
                    level: LogLevel = .info,
                    file: String = #file,
                    function: String = #function,
                    line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let formattedMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        switch level {
        case .debug:
            os_log("%{public}@", log: .default, type: .debug, formattedMessage)
        case .info:
            os_log("%{public}@", log: .default, type: .info, formattedMessage)
        case .warning:
            os_log("%{public}@", log: .default, type: .default, formattedMessage)
        case .error:
            os_log("%{public}@", log: .default, type: .error, formattedMessage)
        case .critical:
            os_log("%{public}@", log: .default, type: .fault, formattedMessage)
        }
        
        // Optional: Add local file logging or remote logging
        writeToLocalFile(message: formattedMessage, level: level)
    }
    
    /// Logs an error with additional context
    /// - Parameters:
    ///   - error: Error to log
    ///   - context: Additional context about the error
    public func logError(_ error: Error, context: String? = nil) {
        let errorDescription = context != nil
            ? "\(context ?? ""): \(error.localizedDescription)"
            : error.localizedDescription
        
        log(errorDescription, level: .error)
    }
    
    /// Writes log messages to a local file
    /// - Parameters:
    ///   - message: Message to write
    ///   - level: Log level
    private func writeToLocalFile(message: String, level: LogLevel) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let logFileName = "CalTrack_\(getCurrentDateString()).log"
        let logFileURL = documentsDirectory.appendingPathComponent(logFileName)
        
        let logEntry = "[\(getCurrentTimestamp())] [\(level)] \(message)\n"
        
        do {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                let fileHandle = try FileHandle(forWritingTo: logFileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(logEntry.data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                try logEntry.write(to: logFileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Error writing to log file: \(error)")
        }
    }
    
    /// Gets current timestamp for logging
    /// - Returns: Formatted timestamp string
    private func getCurrentTimestamp() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return dateFormatter.string(from: Date())
    }
    
    /// Gets current date string for log filename
    /// - Returns: Formatted date string
    private func getCurrentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: Date())
    }
    
    /// Cleans up log files older than specified days
    /// - Parameter days: Number of days to keep log files
    public func cleanupLogFiles(olderThan days: Int = 7) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        do {
            let fileManager = FileManager.default
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: [.creationDateKey])
            
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())
            
            for fileURL in fileURLs where fileURL.pathExtension == "log" {
                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   let cutoffDate = cutoffDate,
                   creationDate < cutoffDate {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        } catch {
            log("Error cleaning up log files: \(error)", level: .error)
        }
    }
}

// MARK: - Convenience Extensions

/// Extends Error to provide more logging context
extension Error {
    /// Logs the error using the shared Logger
    func log(context: String? = nil) {
        Logger.shared.logError(self, context: context)
    }
}
