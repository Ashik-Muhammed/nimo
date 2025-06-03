# 💰 NIMO - Personal Finance Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)](https://firebase.google.com/)

NIMO is a comprehensive personal finance management application built with Flutter and Firebase. It helps you track your expenses, manage debts, analyze spending patterns, and gain better control over your personal finances. With a clean, intuitive interface and powerful features, NIMO makes financial management simple and effective.

![NIMO App Preview](https://via.placeholder.com/800x400.png?text=NIMO+App+Preview)
*Screenshots coming soon*

## ✨ Key Features

### 💸 Expense Tracking
- Add, edit, and delete expenses with ease
- Categorize expenses for better organization
- Add notes and receipts to transactions
- Recurring expense support

### 📊 Financial Insights
- Interactive charts and graphs
- Monthly/Yearly expense reports
- Category-wise spending analysis
- Custom date range filtering

### 🤝 Debt Management
- Track money you owe and are owed
- Set due dates and payment reminders
- Track payment history
- Split expenses with friends

### 📱 Modern & Intuitive UI
- Clean, material design interface
- Dark/Light theme support
- Responsive layout for all devices
- Quick add floating action button

### 🔄 Cloud Sync & Backup
- Real-time data synchronization
- Secure cloud backup
- Multi-device support
- Offline functionality

### 🔒 Security & Privacy
- End-to-end encryption
- Biometric authentication
- Secure cloud storage
- Data export options

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (latest stable version recommended)
- Dart SDK (comes with Flutter)
- Firebase account
- Android Studio / Xcode (for emulators/simulators)
- Git (for version control)
- Physical device (recommended for testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Ashik-Muhammed/nimo.git
   cd nimo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add a new Android/iOS app in Firebase Console
   - Download the configuration files and place them in the correct directories:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`

4. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Advanced Setup

### Firebase Configuration

1. **Authentication Setup**
   - Enable Email/Password authentication in Firebase Console
   - (Optional) Set up Google Sign-In or other providers
   - Configure password reset email templates

2. **Cloud Firestore Rules**
   Set up appropriate security rules in Firebase Console:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

3. **Firebase Storage**
   - Set up Firebase Storage for receipt images
   - Configure storage security rules
   - (Optional) Set up Cloud Functions for additional processing

### Environment Variables
Create a `.env` file in the root directory with your configuration:
```env
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-bucket.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your-sender-id
FIREBASE_APP_ID=your-app-id
FIREBASE_MEASUREMENT_ID=G-XXXXXXXXXX
```

Add `.env` to your `.gitignore` file to keep sensitive information secure.

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


Project Link: [https://github.com/Ashik-Muhammed/nimo](https://github.com/Ashik-Muhammed/nimo)

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [Best-README-Template](https://github.com/othneildrew/Best-README-Template)
