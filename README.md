# PantryPal 🥗

Your friendly kitchen companion that helps you manage your pantry, reduce food waste, and discover delicious recipes.

## Features

- 🏠 **Home Dashboard** - Overview of your pantry with quick stats and expiring items
- 📦 **Pantry Management** - Track all your food items with expiry dates
- 📷 **Barcode Scanner** - Quickly add items by scanning barcodes
- 🍳 **Recipe Discovery** - Find recipes based on what you have
- 👤 **User Profile** - Manage dietary preferences and settings

## Tech Stack

- **Flutter** - Cross-platform mobile framework
- **Firebase Auth** - User authentication
- **Cloud Firestore** - Database for user data
- **Riverpod** - State management (NotifierProvider)
- **GoRouter** - Declarative routing with auth guards
- **Google Fonts** - Beautiful typography (Nunito)

## Getting Started

### Prerequisites

- Flutter SDK (^3.5.0)
- Firebase project configured
- Dart SDK

### Firebase Setup

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)

2. Enable **Email/Password** authentication:
   - Go to Authentication > Sign-in method
   - Enable Email/Password provider

3. Create **Firestore Database**:
   - Go to Firestore Database
   - Create database in production or test mode

4. Add Firebase to your Flutter app:
   ```bash
   flutterfire configure --project=your-project-id
   ```

5. Update Firestore Security Rules:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

### Installation

```bash
cd erin/recipe-app/recipe-ap
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── router/app_router.dart
│   └── theme/app_theme.dart
└── features/
    ├── auth/
    │   ├── providers/auth_provider.dart
    │   ├── screens/login_screen.dart
    │   ├── screens/signup_screen.dart
    │   ├── services/auth_service.dart
    │   └── widgets/auth_text_field.dart
    ├── home/screens/home_screen.dart
    ├── onboarding/screens/onboarding_screen.dart
    ├── pantry/screens/pantry_screen.dart
    ├── profile/screens/profile_screen.dart
    ├── recipes/screens/recipes_screen.dart
    ├── scan/screens/scan_screen.dart
    └── shell/main_wrapper.dart
```

## License

MIT License

