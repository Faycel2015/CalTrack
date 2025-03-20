# CalTrack - Calorie Tracking App

**CalTrack** is an iOS app built using **SwiftUI** and **SwiftData** to help users monitor their daily calorie intake, track macronutrient consumption, and set weight goals. The app features user profile creation, meal logging, macro tracking, and AI-powered food suggestions, all within an intuitive, minimalist design.

## Features

- **User Profile & Goals**
  - Onboarding flow for collecting user data (height, weight, age, gender, activity level).
  - Calculation of **BMR (Basal Metabolic Rate)** and **TDEE (Total Daily Energy Expenditure)**.
  - Set weight goals: **Maintain**, **Lose**, or **Gain** weight.
  
- **Nutrition Tracking**
  - Log meals and categorize them into **Breakfast**, **Lunch**, **Dinner**, and **Snacks**.
  - Track calories, protein, carbs, and fat for each meal.
  - Visualize daily macro progress with **animated circular progress indicators**.
  - View **weekly trends** using bar charts.

- **AI Integration**
  - **Gemini API** integration for meal suggestions and natural language nutrition queries.
  - **Barcode scanning** using AVFoundation for food identification.
  - **Image recognition** for identifying foods via CoreML.

- **User Interface**
  - Minimalist, card-based design with smooth transitions and animations.
  - Custom circular progress indicators for tracking macro intake.
  - Fully accessible, supporting **Dynamic Type** and **VoiceOver**.

## Technologies Used

- **SwiftUI** for UI development.
- **SwiftData** for local data persistence and storage.
- **Gemini API** for nutrition-based recommendations.
- **AVFoundation** for barcode scanning integration.
- **CoreML** for image recognition (optional feature).

## Setup & Installation

### Prerequisites

Ensure you have the following installed:
- **Xcode 16.2** or higher.
- **SwiftUI 6** support.
- An **Apple Developer** account (for real device testing and deployment).

### Clone the Repository

To get started with the project, clone this repository:

```bash
git clone https://github.com/Faycel2015/CalTrack.git
