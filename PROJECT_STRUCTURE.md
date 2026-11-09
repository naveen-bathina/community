# Legal Unity Network - Project Structure

Complete project structure as of 2026-11-01

```
legal_unity_network/
│
├── .agents/                        # Agent skills (existing)
├── .claude/                        # Claude Code configuration
├── .git/                           # Git repository
├── .idea/                          # IDE configuration
│
├── android/                        # Android platform code
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── kotlin/com/legalunity/legal_unity_network/
│   │   │   │   └── MainActivity.kt
│   │   │   └── AndroidManifest.xml
│   │   ├── build.gradle.kts       # Add google-services plugin here
│   │   └── google-services.json   # TODO: Download from Firebase Console
│   ├── build.gradle.kts
│   └── gradle/
│
├── ios/                            # iOS platform code
│   ├── Runner/
│   │   ├── Info.plist             # Add URL scheme for Google Sign-In
│   │   ├── GoogleService-Info.plist  # TODO: Download from Firebase Console
│   │   └── AppDelegate.swift
│   ├── Podfile                    # Update platform to ios 13.0
│   └── Runner.xcodeproj/
│
├── lib/                            # Flutter application code
│   ├── core/                      # Core infrastructure
│   │   ├── config/
│   │   │   └── firebase_config.dart
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   └── firebase_constants.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   └── utils/
│   │       ├── datetime_utils.dart
│   │       └── validation_utils.dart
│   │
│   ├── features/                  # Feature modules (clean architecture)
│   │   ├── auth/                  # Phone OTP & Google Sign-In
│   │   │   ├── data/              # TODO: Repositories, data sources
│   │   │   ├── domain/            # TODO: Entities, use cases
│   │   │   └── presentation/      # TODO: Screens, widgets, providers
│   │   │       ├── providers/
│   │   │       ├── screens/
│   │   │       └── widgets/
│   │   │
│   │   ├── profile/               # User profiles, search, filtering
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── chat/                  # 1-1 and group chat
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── admin/                 # Admin approvals, moderation
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── election/              # Elections, voting
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   └── notifications/         # In-app notifications
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   │
│   ├── shared/                    # Shared across features
│   │   ├── models/
│   │   │   └── user_model.dart    # ✅ Complete user model
│   │   ├── providers/             # TODO: Shared Riverpod providers
│   │   ├── services/              # TODO: Shared services
│   │   └── widgets/               # TODO: Reusable UI components
│   │
│   ├── firebase_options.dart      # TODO: Generate with flutterfire configure
│   └── main.dart                  # ✅ App entry point (needs Firebase init)
│
├── docs/                          # Documentation
│   └── adr/                       # Architecture Decision Records
│       ├── 0001-firebase-free-tier-architecture.md
│       ├── 0002-phone-otp-google-signin-auth.md
│       └── 0003-single-community-group-chat.md
│
├── test/                          # Unit and widget tests
│   └── widget_test.dart
│
├── web/                           # Web platform (not primary target)
├── linux/                         # Linux desktop (not primary target)
├── macos/                         # macOS desktop (not primary target)
├── windows/                       # Windows desktop (not primary target)
│
├── .gitignore                     # Git ignore rules
├── analysis_options.yaml          # Dart analyzer configuration
├── CONTEXT.md                     # ✅ Domain glossary
├── FIREBASE_SETUP.md              # ✅ Firebase setup instructions
├── firestore.rules                # ✅ Firestore security rules
├── firestore.indexes.json         # TODO: Create if needed
├── legal_unity_network.iml        # IntelliJ module file
├── pubspec.yaml                   # ✅ Flutter dependencies
├── README.md                      # ✅ Project overview and setup
├── skills-lock.json               # Skills configuration
└── storage.rules                  # ✅ Firebase Storage security rules
```

## ✅ Completed Setup Items

### Documentation
- [x] **CONTEXT.md** - Complete domain model with glossary
- [x] **README.md** - Project overview, architecture, setup instructions
- [x] **FIREBASE_SETUP.md** - Step-by-step Firebase configuration guide
- [x] **ADR 0001** - Firebase free tier architecture decision
- [x] **ADR 0002** - Authentication methods decision
- [x] **ADR 0003** - Single group chat decision

### Core Infrastructure
- [x] **Firebase configuration** - `lib/core/config/firebase_config.dart`
- [x] **App constants** - File size limits, pagination, validation rules
- [x] **Firebase constants** - Collection names, field names, enums
- [x] **App theme** - Material Design 3 with professional colors (light/dark)
- [x] **Validation utils** - Email, phone, name, message validators
- [x] **DateTime utils** - Formatting and relative time functions

### Data Models
- [x] **UserModel** - Complete with all profile fields, enums, serialization
- [x] **BarAdmission** - Nested model for legal credentials
- [x] **UserStatus** enum - pending, approved, rejected, banned
- [x] **UserRole** enum - member, admin, founding_admin
- [x] **AvailabilityStatus** enum - accepting_referrals, etc.

### Firebase Setup
- [x] **Firestore security rules** - Complete role-based access control
- [x] **Storage security rules** - File size and type validation
- [x] **Dependencies** - All Flutter packages installed via pubspec.yaml

### Project Structure
- [x] **Feature-first folder structure** - 6 feature modules created
- [x] **Clean architecture layers** - data/domain/presentation per feature
- [x] **Platform code** - Android and iOS native app scaffolding

## 🔨 TODO: Next Implementation Steps

### Phase 1: Firebase Integration (Week 1)
1. Run `flutterfire configure` to generate `firebase_options.dart`
2. Download and place Firebase config files (google-services.json, GoogleService-Info.plist)
3. Update `main.dart` to initialize Firebase on app startup
4. Deploy Firestore and Storage security rules
5. Test Firebase connection

### Phase 2: Authentication (Week 1-2)
1. Implement Phone OTP authentication flow
2. Implement Google Sign-In authentication flow
3. Create authentication state management with Riverpod
4. Build login/registration screens
5. Handle authentication errors and edge cases

### Phase 3: User Registration & Profiles (Week 2-3)
1. Build profile creation form (bar admission, practice areas, etc.)
2. Implement profile photo upload
3. Create user profile screen
4. Implement profile editing
5. Add profile validation

### Phase 4: Admin Approval System (Week 3)
1. Build admin dashboard screen
2. Implement pending users list
3. Add approve/reject functionality
4. Create audit logging for admin actions
5. Implement founding admin bootstrap logic

### Phase 5: Search & Discovery (Week 4)
1. Build member directory screen
2. Implement search functionality
3. Add filters (practice area, location, etc.)
4. Implement pagination/lazy loading
5. Create member detail view

### Phase 6: Chat System (Week 5-6)
1. Implement 1-1 conversation creation
2. Build chat message list UI
3. Add real-time message listeners
4. Implement file/image upload
5. Build group chat screen
6. Add message deletion and moderation

### Phase 7: Broadcasts & Notifications (Week 6-7)
1. Build broadcast creation screen (admin only)
2. Implement broadcast delivery
3. Create in-app notification system
4. Build notification list screen
5. Add notification badges

### Phase 8: Elections (Week 7-8)
1. Build election creation screen
2. Implement nomination flow
3. Create voting UI
4. Add manual vote counting for admins
5. Implement election results display

### Phase 9: Testing & Polish (Week 8-9)
1. Write unit tests for business logic
2. Write widget tests for key screens
3. Test Firebase security rules
4. Test offline functionality
5. Performance optimization
6. Error handling and edge cases

### Phase 10: Deployment (Week 9-10)
1. Generate app icons and splash screens
2. Configure app signing (Android keystore, iOS certificates)
3. Update app metadata (descriptions, screenshots)
4. Beta testing with TestFlight (iOS) and Internal Testing (Android)
5. Submit to App Store and Google Play

## 📊 Estimated Development Timeline

- **Total Estimated Time:** 8-12 weeks (for intermediate Flutter developer)
- **MVP Features:** Weeks 1-7
- **Testing & Polish:** Weeks 8-9
- **Deployment:** Weeks 9-10

## 🔑 Key Dependencies

```yaml
# State Management
flutter_riverpod: ^2.5.1
riverpod_annotation: ^2.3.5

# Firebase
firebase_core: ^3.6.0
firebase_auth: ^5.3.1
cloud_firestore: ^5.4.4
firebase_storage: ^12.3.4

# Authentication
google_sign_in: ^6.2.1

# UI & Utils
cached_network_image: ^3.4.1
image_picker: ^1.1.2
file_picker: ^8.1.2
url_launcher: ^6.3.1
intl: ^0.19.0
equatable: ^2.0.5
uuid: ^4.5.1
```

## 🎯 Development Priority

### Critical Path (Must have for MVP)
1. Authentication (Phone OTP + Google)
2. User registration with profile
3. Admin approval workflow
4. Member directory with search
5. 1-1 chat
6. Group chat
7. Basic notifications

### Important (Should have)
1. Admin moderation tools
2. Broadcast messages
3. Profile editing
4. File sharing in chat

### Nice to Have (Could have post-MVP)
1. Elections system
2. Advanced search filters
3. Push notifications (requires Blaze plan)
4. Multiple groups
5. Analytics dashboard

## 📱 Platform Targets

- **Primary:** iOS 13.0+ and Android API 23+ (Android 6.0+)
- **Secondary:** Web (limited support, not optimized)
- **Not Supported:** Desktop (Linux, macOS, Windows)

---

**Project structure generation complete! Ready for implementation. 🚀**

*Last updated: 2026-11-01*
