//
//  UserRepository.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftData

/// Repository class for handling User Profile data operations
class UserRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Fetch the current user profile
    /// - Returns: The user profile if one exists, nil otherwise
    func getCurrentUserProfile() throws -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try modelContext.fetch(descriptor)
        return profiles.first
    }
    
    /// Save a new user profile
    /// - Parameter profile: The user profile to save
    func saveUserProfile(_ profile: UserProfile) throws {
        // Check if a profile already exists
        if let existingProfile = try getCurrentUserProfile() {
            // Update existing profile
            updateUserProfile(existingProfile, with: profile)
        } else {
            // Insert new profile
            modelContext.insert(profile)
        }
        
        // Save changes
        try modelContext.save()
    }
    
    /// Update an existing user profile with new values
    /// - Parameters:
    ///   - existingProfile: The existing profile to update
    ///   - newProfile: The profile containing new values
    func updateUserProfile(_ existingProfile: UserProfile, with newProfile: UserProfile) {
        // Update basic information
        existingProfile.name = newProfile.name
        existingProfile.age = newProfile.age
        existingProfile.gender = newProfile.gender
        existingProfile.height = newProfile.height
        existingProfile.weight = newProfile.weight
        existingProfile.activityLevel = newProfile.activityLevel
        existingProfile.weightGoal = newProfile.weightGoal
        
        // Update macro preferences
        existingProfile.carbPercentage = newProfile.carbPercentage
        existingProfile.proteinPercentage = newProfile.proteinPercentage
        existingProfile.fatPercentage = newProfile.fatPercentage
        
        // Recalculate nutrition goals
        existingProfile.calculateNutritionGoals()
        
        // Update timestamp
        existingProfile.updatedAt = Date()
    }
    
    /// Update user weight
    /// - Parameter weight: The new weight value
    func updateWeight(_ weight: Double) throws {
        guard let profile = try getCurrentUserProfile() else {
            throw UserRepositoryError.profileNotFound
        }
        
        profile.weight = weight
        profile.updatedAt = Date()
        
        // Recalculate nutrition goals as weight affects BMR
        profile.calculateNutritionGoals()
        
        try modelContext.save()
    }
    
    /// Delete the user profile
    func deleteUserProfile() throws {
        guard let profile = try getCurrentUserProfile() else {
            throw UserRepositoryError.profileNotFound
        }
        
        modelContext.delete(profile)
        try modelContext.save()
    }
}

/// Errors that can occur during user profile operations
enum UserRepositoryError: Error {
    case profileNotFound
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    
    var errorDescription: String {
        switch self {
        case .profileNotFound:
            return "User profile not found"
        case .saveFailed(let error):
            return "Failed to save user profile: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch user profile: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete user profile: \(error.localizedDescription)"
        }
    }
}
