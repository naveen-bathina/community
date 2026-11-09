# Legal Unity Network

A mobile application for legal professionals to network, share information, and coordinate referrals.

## Project Overview

**Platform:** Flutter mobile app (iOS & Android)  
**Backend:** Firebase (Authentication, Firestore, Storage)  
**State Management:** Riverpod  
**Design System:** Material Design 3

## Documentation

- **[CONTEXT.md](CONTEXT.md)** - Domain glossary and terminology
- **[docs/adr/](docs/adr/)** - Architecture Decision Records

## Project Structure

This project follows a **feature-first** architecture pattern:

```
lib/
├── core/                           # Core application infrastructure
│   ├── config/                     # App and Firebase configuration
│   │   └── firebase_config.dart
│   ├── constants/                  # App-wide constants
│   │   ├── app_constants.dart
│   │   └── firebase_constants.dart
│   ├── theme/                      # Material Design 3 theming
│   │   └── app_theme.dart
│   └── utils/                      # Utility functions
│       ├── validation_utils.dart
│       └── datetime_utils.dart
│
├── features/                       # Feature modules (domain-driven)
│   ├── auth/                       # Authentication (Phone OTP, Google Sign-In)
│   │   ├── data/                   # Data sources, repositories
│   │   ├── domain/                 # Business logic, entities
│   │   └── presentation/           # UI, state management
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   ├── profile/                    # User profiles, search, filtering
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── chat/                       # 1-1 and group chat
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── admin/                      # Admin dashboard, approvals, moderation
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── election/                   # Admin elections, voting
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── notifications/              # In-app notifications
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── shared/                         # Shared across features
    ├── models/                     # Common data models
    │   └── user_model.dart
    ├── widgets/                    # Reusable UI components
    ├── providers/                  # Shared Riverpod providers
    └── services/                   # Shared services
```

## Firebase Architecture

### Collections Structure

```
Firestore Database:
├── users/                          # User profiles and metadata
│   └── {userId}
├── conversations/                  # 1-1 chat metadata
│   └── {conversationId}
│       └── messages/               # Subcollection
│           └── {messageId}
├── groupChat/                      # Community-wide group chat messages
│   └── {messageId}
├── broadcasts/                     # Admin broadcast messages
│   └── {broadcastId}
├── elections/                      # Election cycles
│   └── {electionId}
│       ├── nominations/            # Subcollection
│       │   └── {nominationId}
│       └── votes/                  # Subcollection
│           └── {voteId}
├── adminActions/                   # Audit log of admin activities
│   └── {actionId}
└── notifications/                  # User notifications
    └── {notificationId}

Firebase Storage:
├── profile_photos/                 # User profile pictures (max 500KB)
│   └── {userId}.jpg
└── chat_attachments/               # Chat file uploads (max 5MB)
    └── {messageId}/{filename}
```

### Security Rules

Security rules enforce:
- Authenticated users only (`request.auth != null`)
- Approved members can read other approved profiles
- Users can only write their own data (except admins)
- Admins can moderate, approve, and manage users
- Chat participants can read/write their conversations

## Setup Instructions

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart 3.9.2 or higher
- Firebase account
- iOS: Xcode and CocoaPods (for iOS development)
- Android: Android Studio and Android SDK

### Step 1: Clone and Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Generate Riverpod code (after adding providers)
dart run build_runner build
```

### Step 2: Firebase Setup

1. **Create Firebase Project:**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create a new project: "Legal Unity Network"
   - Enable Google Analytics (optional)

2. **Add Apps to Firebase:**
   - Add Android app: `com.legalunity.legal_unity_network`
   - Add iOS app: `com.legalunity.legalUnityNetwork`

3. **Download Configuration Files:**
   - Android: Download `google-services.json` → `android/app/google-services.json`
   - iOS: Download `GoogleService-Info.plist` → `ios/Runner/GoogleService-Info.plist`

4. **Enable Firebase Services:**
   - **Authentication:**
     - Enable Phone authentication
     - Enable Google Sign-In
   - **Cloud Firestore:**
     - Create database in production mode
     - Deploy security rules (see `firestore.rules`)
   - **Firebase Storage:**
     - Enable storage
     - Deploy storage rules (see `storage.rules`)

5. **Configure Firebase CLI:**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Login to Firebase
   firebase login
   
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase for Flutter
   flutterfire configure
   ```

### Step 3: Platform-Specific Configuration

#### Android Configuration

1. Update `android/build.gradle.kts`:
   ```kotlin
   dependencies {
       classpath("com.google.gms:google-services:4.4.0")
   }
   ```

2. Update `android/app/build.gradle.kts`:
   ```kotlin
   plugins {
       id("com.google.gms.google-services")
   }
   ```

3. Update minimum SDK version in `android/app/build.gradle.kts`:
   ```kotlin
   minSdk = 23  // Required for Firebase
   ```

#### iOS Configuration

1. Update `ios/Podfile`:
   ```ruby
   platform :ios, '13.0'  # Required for Firebase
   ```

2. Run pod install:
   ```bash
   cd ios
   pod install
   cd ..
   ```

3. Enable Google Sign-In in Xcode:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Add URL scheme from `GoogleService-Info.plist` (REVERSED_CLIENT_ID)

### Step 4: Run the App

```bash
# Check for issues
flutter doctor

# Run on connected device or emulator
flutter run

# Build for release
flutter build apk      # Android
flutter build ios      # iOS (requires Mac)
```

## Development Guidelines

### State Management with Riverpod

- Use `@riverpod` annotation for code generation
- Prefer `AsyncNotifier` for complex async state
- Use `ref.watch()` to listen to providers
- Use `ref.read()` for one-time reads

### Firebase Best Practices

- Always check `request.auth != null` in security rules
- Use `serverTimestamp()` for consistent timestamps
- Enable offline persistence (enabled by default)
- Batch writes when possible to save quota

### Code Organization

- Keep features isolated (minimal cross-feature dependencies)
- Share common models via `shared/models/`
- Put reusable widgets in `shared/widgets/`
- Keep business logic in `domain/` layer

### Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## Firebase Free Tier Limits

The app is designed to run on Firebase Spark (free) tier:

- **Firestore:** 50K reads/day, 20K writes/day
- **Storage:** 5GB total, 1GB/day download
- **Authentication:** 10K phone verifications/month
- **No Cloud Functions** (using manual admin workflows)

**Estimated capacity:** 150-200 daily active users before needing Blaze upgrade.

## Key Features

### MVP Features (v1.0)
- ✅ Phone OTP & Google Sign-In authentication
- ✅ Admin approval workflow for new members
- ✅ Professional profile creation and viewing
- ✅ Search and filter members by practice area, location, etc.
- ✅ 1-1 chat with file sharing (text, images, files, links)
- ✅ Community-wide group chat
- ✅ Admin moderation (approve users, moderate chat, broadcasts)
- ✅ Admin elections (nominations, voting, results)
- ✅ In-app notifications
- ✅ Offline support (view cached data)

### Future Enhancements (Post-MVP)
- Push notifications (requires Blaze plan + Cloud Functions)
- Multiple topic-based groups
- Advanced search filters
- Member-to-member recommendations
- CLE event calendar
- Analytics dashboard for admins

## Contributing

This is a private project. For questions or issues, contact the project maintainer.

## License

Proprietary - All rights reserved.

---

**Built with Flutter 🚀 | Powered by Firebase 🔥**
