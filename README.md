# NIMO - Personal Expense Tracker

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A simple, intuitive, and beautiful expense tracking application built with Flutter and Firebase Firestore. Keep track of your daily expenses, categorize them, and gain insights into your spending habits.

## ✨ Features

- 📱 **Cross-Platform** - Works on iOS, Android, and web
- 💰 **Expense Management** - Add, view, update, and delete expenses
- 🗂 **Categories** - Organize expenses into categories (Food, Transportation, Shopping, etc.)
- 📅 **Monthly View** - View and filter expenses by month
- 📊 **Expense Analytics** - See total expenses and category-wise breakdown
- 📱 **Responsive Design** - Optimized for all screen sizes
- 🔄 **Real-time Sync** - Data syncs across all your devices using Firebase
- 🔒 **Secure** - User authentication and data encryption

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (comes with Flutter)
- Firebase project
- Android Studio / Xcode (for running on emulator/simulator)
- Physical device (optional but recommended for testing)
- Git (for version control)

### Clone the Repository

```bash
git clone https://github.com/yourusername/expense_tracker.git
cd expense_tracker
```

### Install Dependencies

```bash
flutter pub get
```

## 🔧 Firebase Setup

1. **Create a Firebase Project**
   - Go to the [Firebase Console](https://console.firebase.google.com/)
   - Click "Add project" and follow the setup wizard
   - Enable Google Analytics (recommended)

2. **Set up Authentication**
   - In the Firebase Console, go to Authentication
   - Click "Get Started" and enable "Email/Password" sign-in method

3. **Set up Firestore Database**
   - Go to Firestore Database in the Firebase Console
   - Click "Create database" in production mode
   - Choose a location close to your users
   - Set security rules to start in test mode

4. **Add Firebase to Your App**
   - In the Firebase Console, click the Android/iOS icon to add your app
   - Follow the setup instructions to download the config files
   - Place the config files in the appropriate directories:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`

5. **Configure Firebase Options**
   - Run the following command to generate Firebase options:
     ```bash
     flutterfire configure
     ```
   - This will create the necessary configuration files automatically

## 🏗 Project Structure

```
lib/
├── models/                   # Data models
│   ├── category.dart
│   ├── debt.dart
│   ├── expense.dart
│   ├── expense_frequency.dart
│   ├── income.dart
│   └── split_expense.dart
│
├── screens/                  # App screens
│   ├── add_debt_screen.dart
│   ├── add_expense_screen.dart
│   ├── add_income_screen.dart
│   ├── analytics_screen.dart
│   ├── auth_screen.dart
│   ├── auth_wrapper.dart
│   ├── dashboard_screen.dart
│   ├── debt_detail_screen.dart
│   ├── debt_management_screen.dart
│   ├── debts_list_screen.dart
│   ├── debts_list_screen_fixed.dart
│   ├── expense_list_screen.dart
│   ├── home_screen.dart
│   ├── income_list_screen.dart
│   └── manage_categories_screen.dart
│
├── services/                 # Business logic and services
│   ├── auth_service.dart
│   ├── balance_service.dart
│   ├── budget_service.dart
│   ├── category_service.dart
│   ├── debt_service.dart
│   ├── expense_service.dart
│   └── income_service.dart
│
├── theme/                    # App theming
│   └── app_theme.dart
│
├── utils/                    # Utility functions and helpers
│
├── widgets/                  # Reusable UI components
│   ├── currency_selector.dart
│   ├── expense_list.dart
│   ├── month_selector.dart
│   └── total_expense_card.dart
│
├── firebase_options.dart     # Firebase configuration
└── main.dart                 # App entry point
```

## 📦 Dependencies

This project uses several packages to make development easier:

### Core
- `flutter/foundation` - Flutter's foundation library
- `flutter/material` - Material Design widgets
- `provider` - State management

### Firebase
- `firebase_core` - Firebase Core for Flutter
- `cloud_firestore` - Cloud Firestore for database
- `firebase_auth` - Firebase Authentication
- `firebase_analytics` - Firebase Analytics

### UI/UX
- `intl` - Internationalization and localization
- `flutter_slidable` - Swipe-to-delete functionality
- `shared_preferences` - Local storage for user preferences
- `flutter_svg` - SVG image support

### Development
- `flutter_test` - For widget testing
- `mockito` - For mocking in tests
- `flutter_lints` - Linting rules

- `firebase_core`: Firebase Core for Flutter
- `cloud_firestore`: Cloud Firestore for database
- `firebase_auth`: Firebase Authentication
- `intl`: Internationalization and localization
- `provider`: State management
- `uuid`: For generating unique IDs
- `flutter_slidable`: For swipe-to-delete functionality
- `shared_preferences`: For local storage (if needed)

## 🧪 Running Tests

To run tests, execute the following command:

```bash
flutter test
```

For test coverage:

```bash
flutter test --coverage
```

## 🐛 Troubleshooting

### Common Issues

1. **Firebase not initialized**
   - Make sure you've run `flutterfire configure`
   - Verify your Firebase config files are in the correct location

2. **Dependency issues**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Build errors**
   - Ensure you have the latest Flutter version
   - Run `flutter doctor` to check for any issues

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

## 📬 Contact

Your Name - [@your_twitter](https://twitter.com/your_twitter) - your.email@example.com

Project Link: [https://github.com/yourusername/expense_tracker](https://github.com/yourusername/expense_tracker)

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [Best-README-Template](https://github.com/othneildrew/Best-README-Template)
