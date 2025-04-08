//
//  AppServices.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation
import SwiftData

/// Service locator for app services and repositories
@MainActor
class AppServices {
    // MARK: - Singleton

    static let shared = AppServices()

    func getBarcodeService() -> BarcodeService {
        return BarcodeService()
    }

    private init() {
        setupServices()
    }

    // MARK: - Properties

    private(set) var modelContext: ModelContext?

    // Repositories
    private(set) var userRepository: UserRepository?
    private(set) var mealRepository: MealRepository?
    private(set) var foodRepository: FoodRepository?

    // Services
    private(set) var nutritionService: NutritionService?
    private(set) var mealService: MealService?

    // MARK: - Setup

    /// Initialize with a model context
    /// - Parameter modelContext: The SwiftData model context
    func initialize(with modelContext: ModelContext) {
        self.modelContext = modelContext
        setupServices()
    }

    private func setupServices() {
        guard let modelContext = modelContext else { return }

        // Initialize repositories
        userRepository = UserRepository(modelContext: modelContext)
        mealRepository = MealRepository(modelContext: modelContext)
        foodRepository = FoodRepository(modelContext: modelContext)

        // Initialize services with dependencies
        if let userRepository = userRepository, let mealRepository = mealRepository {
            nutritionService = NutritionService(
                userRepository: userRepository,
                mealRepository: mealRepository
            )
        }

        if let mealRepository = mealRepository, let foodRepository = foodRepository {
            mealService = MealService(
                mealRepository: mealRepository,
                foodRepository: foodRepository
            )
        }
    }

    // MARK: - Access Methods

    /// Get the user repository
    /// - Returns: User repository instance
    func getUserRepository() -> UserRepository {
        guard let repository = userRepository else {
            fatalError("UserRepository not initialized. Call initialize(with:) first.")
        }
        return repository
    }

    /// Get the meal repository
    /// - Returns: Meal repository instance
    func getMealRepository() -> MealRepository {
        guard let repository = mealRepository else {
            fatalError("MealRepository not initialized. Call initialize(with:) first.")
        }
        return repository
    }

    /// Get the food repository
    /// - Returns: Food repository instance
    func getFoodRepository() -> FoodRepository {
        guard let repository = foodRepository else {
            fatalError("FoodRepository not initialized. Call initialize(with:) first.")
        }
        return repository
    }

    /// Get the nutrition service
    /// - Returns: Nutrition service instance
    func getNutritionService() -> NutritionService {
        guard let service = nutritionService else {
            fatalError("NutritionService not initialized. Call initialize(with:) first.")
        }
        return service
    }

    /// Get the meal service
    /// - Returns: Meal service instance
    func getMealService() -> MealService {
        guard let service = mealService else {
            fatalError("MealService not initialized. Call initialize(with:) first.")
        }
        return service
    }

    /// Get the gemini service
    func getGeminiService() -> GeminiService {
        guard let nutritionService = nutritionService else {
            fatalError("NutritionService not initialized. Call initialize(with:) first.")
        }

        return GeminiService(
            apiKey: "AIzaSyCohNfolfRyfvZwLgiLe7Kx2sRGM1iuLL0",
            nutritionService: nutritionService
        )
    }
}

extension AppServices {
    func getUserProfileService() -> UserProfileService {
        guard let userRepository = userRepository else {
            fatalError("UserRepository not initialized. Call initialize(with:) first.")
        }

        return UserProfileService(userRepository: userRepository)
    }
}
