//
//  GeminiService.swift
//  CalTrack
//
//  Created by FayTek on 3/20/25.
//

import Foundation

/// Service for AI-powered meal suggestions and nutrition analysis using Google's Gemini API
class GeminiService {
    // MARK: - Properties
    
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private let model = "gemini-2.0-flash"
    private let urlSession: URLSession
    
    // Dependencies
    private let nutritionService: NutritionService
    
    // MARK: - Initializer
    
    init(apiKey: String, nutritionService: NutritionService, urlSession: URLSession = .shared) {
        self.apiKey = apiKey
        self.nutritionService = nutritionService
        self.urlSession = urlSession
    }
    
    // MARK: - Public Methods
    
    /// Generate meal suggestions based on remaining macros and preferences
    /// - Parameters:
    ///   - remainingMacros: Tuple containing remaining macros
    ///   - preferences: User dietary preferences
    ///   - mealType: Type of meal to suggest
    /// - Returns: Array of meal suggestions
    func generateMealSuggestions(
        remainingMacros: (calories: Double, carbs: Double, protein: Double, fat: Double),
        preferences: DietaryPreferences,
        mealType: MealType
    ) async throws -> [MealSuggestion] {
        // Build prompt for AI
        let prompt = buildMealSuggestionPrompt(
            remainingMacros: remainingMacros,
            preferences: preferences,
            mealType: mealType
        )
        
        // Send request to Gemini API
        let response = try await sendPromptToGemini(prompt)
        
        // Parse response into meal suggestions
        return try parseMealSuggestionsResponse(response)
    }
    
    /// Analyze a food item from image or description
    /// - Parameter input: Food input (image data or description)
    /// - Returns: Analyzed food item with nutritional information
    func analyzeFoodItem(input: FoodInput) async throws -> FoodItem {
        // Build prompt for AI
        let prompt = buildFoodAnalysisPrompt(input: input)
        
        // Send request to Gemini API
        let response = try await sendPromptToGemini(prompt)
        
        // Parse response into food item
        return try parseFoodItemResponse(response)
    }
    
    /// Answer nutrition questions using AI
    /// - Parameter question: User's nutrition question
    /// - Returns: AI response to the question
    func answerNutritionQuestion(question: String) async throws -> String {
        // Build prompt
        let prompt = "Answer this nutrition question professionally and accurately based on scientific evidence: \(question)"
        
        // Send request to Gemini API
        let response = try await sendPromptToGemini(prompt)
        
        // Return the response text
        return response
    }
    
    /// Generate a personalized meal plan
    /// - Parameters:
    ///   - nutritionGoals: User's nutrition goals
    ///   - preferences: Dietary preferences
    ///   - days: Number of days to generate
    /// - Returns: Generated meal plan
    func generateMealPlan(
        nutritionGoals: NutritionGoals,
        preferences: DietaryPreferences,
        days: Int = 7
    ) async throws -> MealPlan {
        // Build prompt for AI
        let prompt = buildMealPlanPrompt(
            nutritionGoals: nutritionGoals,
            preferences: preferences,
            days: days
        )
        
        // Send request to Gemini API
        let response = try await sendPromptToGemini(prompt)
        
        // Parse response into meal plan
        return try parseMealPlanResponse(response, days: days)
    }
    
    // MARK: - Private Methods
    
    /// Send a prompt to the Gemini API
    /// - Parameter prompt: The text prompt to send
    /// - Returns: Response from the API
    private func sendPromptToGemini(_ prompt: String) async throws -> String {
        // Construct URL
        let endpoint = "\(baseURL)/models/\(model):generateContent"
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw GeminiServiceError.invalidURL
        }
        
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        guard let url = urlComponents.url else {
            throw GeminiServiceError.invalidURL
        }
        
        // Construct request body
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "topK": 32,
                "topP": 0.95,
                "maxOutputTokens": 1024
            ]
        ]
        
        // Convert request body to data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw GeminiServiceError.invalidRequestData
        }
        
        // Create and configure request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Send request
        let (data, response) = try await urlSession.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiServiceError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw GeminiServiceError.requestFailed(statusCode: httpResponse.statusCode, message: String(data: data, encoding: .utf8) ?? "Unknown error")
        }
        
        // Parse response
        guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = jsonResponse["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiServiceError.invalidResponseFormat
        }
        
        return text
    }
    
    /// Build prompt for meal suggestions
    private func buildMealSuggestionPrompt(
        remainingMacros: (calories: Double, carbs: Double, protein: Double, fat: Double),
        preferences: DietaryPreferences,
        mealType: MealType
    ) -> String {
        return """
        I need suggestions for a \(mealType.rawValue.lowercased()) that fits these nutritional requirements:
        
        Calories: Around \(Int(remainingMacros.calories))
        Carbohydrates: Around \(Int(remainingMacros.carbs))g
        Protein: Around \(Int(remainingMacros.protein))g
        Fat: Around \(Int(remainingMacros.fat))g
        
        Dietary restrictions: \(preferences.restrictions.joined(separator: ", "))
        Food preferences: \(preferences.preferredFoods.joined(separator: ", "))
        Disliked foods: \(preferences.dislikedFoods.joined(separator: ", "))
        
        Please provide 3 meal options with:
        1. Meal name
        2. List of ingredients with quantities
        3. Exact nutritional breakdown (calories, carbs, protein, fat)
        4. Brief preparation instructions
        
        Format the response as structured data only, without any additional explanations.
        """
    }
    
    /// Build prompt for food analysis
    private func buildFoodAnalysisPrompt(input: FoodInput) -> String {
        switch input {
        case .text(let description):
            return """
            Analyze this food item and provide detailed nutritional information per standard serving:
            
            Food item: \(description)
            
            Please provide:
            1. Standard serving size
            2. Calories per serving
            3. Macronutrients (carbs, protein, fat) in grams
            4. Additional nutrients if available (fiber, sugar, sodium, etc.)
            
            Format the response as structured data only, without explanations.
            """
            
        case .image(let description):
            return """
            Based on this description of a food image, provide detailed nutritional information per standard serving:
            
            Image description: \(description)
            
            Please provide:
            1. Standard serving size
            2. Calories per serving
            3. Macronutrients (carbs, protein, fat) in grams
            4. Additional nutrients if available (fiber, sugar, sodium, etc.)
            
            Format the response as structured data only, without explanations.
            """
        }
    }
    
    /// Build prompt for meal plan generation
    private func buildMealPlanPrompt(
        nutritionGoals: NutritionGoals,
        preferences: DietaryPreferences,
        days: Int
    ) -> String {
        return """
        Create a \(days)-day meal plan optimized for these nutritional goals:
        
        Daily calories: \(Int(nutritionGoals.dailyCalories))
        Carbohydrates: \(Int(nutritionGoals.dailyCarbs))g (\(Int(nutritionGoals.carbPercentage * 100))%)
        Protein: \(Int(nutritionGoals.dailyProtein))g (\(Int(nutritionGoals.proteinPercentage * 100))%)
        Fat: \(Int(nutritionGoals.dailyFat))g (\(Int(nutritionGoals.fatPercentage * 100))%)
        
        Dietary restrictions: \(preferences.restrictions.joined(separator: ", "))
        Food preferences: \(preferences.preferredFoods.joined(separator: ", "))
        Disliked foods: \(preferences.dislikedFoods.joined(separator: ", "))
        
        For each day, include:
        1. Breakfast, lunch, dinner, and 1-2 snacks
        2. Nutritional breakdown for each meal (calories, carbs, protein, fat)
        3. Total daily nutritional summary
        
        Format the response as structured data only, without any additional explanations.
        """
    }
    
    /// Parse meal suggestions from API response
    private func parseMealSuggestionsResponse(_ response: String) throws -> [MealSuggestion] {
        // In a real implementation, this would parse the structured response from Gemini
        // For this example, we'll return mock data
        
        // Simulate parsing error if response doesn't contain expected keywords
        if !response.contains("meal") && !response.contains("food") && !response.contains("calories") {
            throw GeminiServiceError.responseParsingFailed("Response does not contain meal suggestions")
        }
        
        // Mock meal suggestions
        return [
            MealSuggestion(
                name: "Grilled Chicken Salad",
                ingredients: [
                    "100g chicken breast",
                    "2 cups mixed greens",
                    "1 tbsp olive oil",
                    "1/4 avocado"
                ],
                nutrition: (calories: 350, carbs: 10, protein: 40, fat: 15),
                instructions: "Grill chicken, chop vegetables, toss with olive oil"
            ),
            MealSuggestion(
                name: "Protein Smoothie Bowl",
                ingredients: [
                    "1 scoop protein powder",
                    "1 banana",
                    "1/2 cup Greek yogurt",
                    "1 tbsp almond butter"
                ],
                nutrition: (calories: 320, carbs: 35, protein: 25, fat: 10),
                instructions: "Blend all ingredients, top with fruits and nuts"
            ),
            MealSuggestion(
                name: "Quinoa Veggie Bowl",
                ingredients: [
                    "1/2 cup cooked quinoa",
                    "1/2 cup black beans",
                    "1/4 cup corn",
                    "1/4 avocado"
                ],
                nutrition: (calories: 380, carbs: 50, protein: 15, fat: 12),
                instructions: "Mix all ingredients, season with lime and cilantro"
            )
        ]
    }
    
    /// Parse food item from API response
    private func parseFoodItemResponse(_ response: String) throws -> FoodItem {
        // In a real implementation, this would parse the structured response from Gemini
        // For this example, we'll return a mock food item
        
        // Simulate parsing error if response doesn't contain expected keywords
        if !response.contains("serving") && !response.contains("calories") && !response.contains("protein") {
            throw GeminiServiceError.responseParsingFailed("Response does not contain food nutritional information")
        }
        
        // Create mock food item
        return FoodItem(
            name: "Analyzed Food",
            servingSize: "1 cup (100g)",
            servingQuantity: 1.0,
            calories: 250,
            carbs: 30,
            protein: 15,
            fat: 8,
            sugar: 5,
            fiber: 3,
            sodium: 200,
            isCustom: true
        )
    }
    
    /// Parse meal plan from API response
    private func parseMealPlanResponse(_ response: String, days: Int) throws -> MealPlan {
        // In a real implementation, this would parse the structured response from Gemini
        // For this example, we'll return a mock meal plan
        
        // Simulate parsing error if response doesn't contain expected keywords
        if !response.contains("meal") && !response.contains("day") && !response.contains("breakfast") {
            throw GeminiServiceError.responseParsingFailed("Response does not contain meal plan data")
        }
        
        // Create mock meal plan days
        var mealPlanDays: [MealPlanDay] = []
        
        for dayIndex in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: dayIndex, to: Date()) ?? Date()
            
            let meals = [
                MealPlanItem(
                    name: "Breakfast Option",
                    ingredients: ["Oatmeal", "Berries", "Protein powder"],
                    nutrition: (calories: 350, carbs: 45, protein: 25, fat: 8),
                    mealType: .breakfast
                ),
                MealPlanItem(
                    name: "Lunch Option",
                    ingredients: ["Chicken breast", "Quinoa", "Vegetables"],
                    nutrition: (calories: 450, carbs: 40, protein: 35, fat: 15),
                    mealType: .lunch
                ),
                MealPlanItem(
                    name: "Dinner Option",
                    ingredients: ["Salmon", "Sweet potato", "Broccoli"],
                    nutrition: (calories: 500, carbs: 30, protein: 40, fat: 20),
                    mealType: .dinner
                ),
                MealPlanItem(
                    name: "Snack Option",
                    ingredients: ["Greek yogurt", "Honey", "Nuts"],
                    nutrition: (calories: 200, carbs: 15, protein: 15, fat: 10),
                    mealType: .snack
                )
            ]
            
            let dayTotals = (
                calories: meals.reduce(0) { $0 + $1.nutrition.calories },
                carbs: meals.reduce(0) { $0 + $1.nutrition.carbs },
                protein: meals.reduce(0) { $0 + $1.nutrition.protein },
                fat: meals.reduce(0) { $0 + $1.nutrition.fat }
            )
            
            let mealPlanDay = MealPlanDay(
                date: date,
                meals: meals,
                totalNutrition: dayTotals
            )
            
            mealPlanDays.append(mealPlanDay)
        }
        
        return MealPlan(
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: days - 1, to: Date()) ?? Date(),
            days: mealPlanDays
        )
    }
}

// MARK: - Input Types

/// Input for food analysis
enum FoodInput {
    case text(String)
    case image(String) // Description of the image (in a real app, this would be image data)
}

// MARK: - Data Models

/// User's dietary preferences
struct DietaryPreferences {
    var restrictions: [String] // e.g., "vegetarian", "gluten-free", "dairy-free"
    var preferredFoods: [String]
    var dislikedFoods: [String]
    
    static let empty = DietaryPreferences(
        restrictions: [],
        preferredFoods: [],
        dislikedFoods: []
    )
}

/// Nutrition goals for meal planning
struct NutritionGoals {
    var dailyCalories: Double
    var dailyCarbs: Double
    var dailyProtein: Double
    var dailyFat: Double
    var carbPercentage: Double
    var proteinPercentage: Double
    var fatPercentage: Double
}

/// Meal suggestion from AI
struct MealSuggestion {
    var name: String
    var ingredients: [String]
    var nutrition: (calories: Double, carbs: Double, protein: Double, fat: Double)
    var instructions: String
}

/// Meal plan generated by AI
struct MealPlan {
    var startDate: Date
    var endDate: Date
    var days: [MealPlanDay]
}

/// Single day in a meal plan
struct MealPlanDay {
    var date: Date
    var meals: [MealPlanItem]
    var totalNutrition: (calories: Double, carbs: Double, protein: Double, fat: Double)
}

/// Single meal in a meal plan
struct MealPlanItem {
    var name: String
    var ingredients: [String]
    var nutrition: (calories: Double, carbs: Double, protein: Double, fat: Double)
    var mealType: MealType
}

// MARK: - Errors

/// Errors that can occur during Gemini API operations
enum GeminiServiceError: Error {
    case invalidURL
    case invalidRequestData
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)
    case invalidResponseFormat
    case responseParsingFailed(String)
    case apiKeyMissing
    
    var errorDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidRequestData:
            return "Failed to create request data"
        case .invalidResponse:
            return "Received invalid response from server"
        case .requestFailed(let statusCode, let message):
            return "Request failed with status code \(statusCode): \(message)"
        case .invalidResponseFormat:
            return "Response was not in the expected format"
        case .responseParsingFailed(let reason):
            return "Failed to parse response: \(reason)"
        case .apiKeyMissing:
            return "API key is missing"
        }
    }
}
