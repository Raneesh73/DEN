<p align="center">
  <img src="assets/screenshots/banner.png" alt="DEN – Private Circle" width="100%"/>
</p>

<h1 align="center">DEN – Private Circle</h1>

<p align="center">
  <strong>Real-time location sharing for your trusted group. Stay connected. Stay safe.</strong>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter"/></a>
  <a href="https://firebase.google.com"><img src="https://img.shields.io/badge/Firebase-Configured-FFCA28?logo=firebase&logoColor=black" alt="Firebase"/></a>
  <a href="https://riverpod.dev"><img src="https://img.shields.io/badge/Riverpod-2.x-00C4B4" alt="Riverpod"/></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart"/></a>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Web-brightgreen" alt="Platform"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License"/>
</p>

---

## 📱 Screenshots

<p align="center">
  <img src="assets/screenshots/login_screen.png" alt="Login Screen" width="22%"/>
  &nbsp;
  <img src="assets/screenshots/circle_screen.png" alt="Den Management" width="22%"/>
  &nbsp;
  <img src="assets/screenshots/map_dashboard.png" alt="Live Map" width="22%"/>
  &nbsp;
  <img src="assets/screenshots/sos_united.png" alt="SOS & Den United" width="22%"/>
</p>

---

## ✨ Features

| Feature | Description |
|---|---|
| 🗺️ **Live Map Dashboard** | Full-screen Google Maps with custom dark theme, real-time member markers, and smooth camera tracking |
| 👥 **Den (Private Circle) System** | Create private groups or join existing ones via 6-character invite codes |
| 🔐 **Firebase Authentication** | Secure email/password auth with persistent session handling and graceful retry logic |
| 📍 **Real-Time Location Sync** | Background GPS via Geolocator streams live coordinates to Firestore for all members |
| 🚨 **SOS Alert System** | One-tap emergency alert broadcasts your live location to every member instantly |
| 🎉 **Den United Celebration** | Detects when all members converge and triggers a full-screen animated celebration |
| 🌙 **Premium Cyberpunk UI** | Glassmorphism cards, neon accents, animated backgrounds, and smooth micro-animations |
| ⚡ **Riverpod Architecture** | Fully reactive state with StreamProviders and zero unnecessary widget rebuilds |

---

## 🛠️ Tech Stack

```
Frontend         Flutter 3.x + Dart 3.x
State            Riverpod 2.x (StreamProvider, StateNotifierProvider, Provider)
Backend          Firebase (Authentication + Cloud Firestore + FCM)
Maps             Google Maps Flutter SDK + Maps JavaScript API (Web)
Location         Geolocator 14.x (foreground + background tracking)
UI               flutter_animate, google_fonts (Outfit), glassmorphism
Platform         Android (APK) + Web (Flutter Web)
```

---

## 🏗️ Architecture

DEN follows a **layered, feature-first architecture** with a clean separation between data, business logic, and UI.

```
┌─────────────────────────────────────────────────────┐
│                    UI LAYER                         │
│  LoginScreen  RegisterScreen  DenScreen  MapScreen  │
└───────────────────────┬─────────────────────────────┘
                        │ watches
┌───────────────────────▼─────────────────────────────┐
│                  PROVIDER LAYER (Riverpod)           │
│  authStateProvider  userProfileProvider              │
│  denMembersProvider  mapControllerProvider           │
│  denInviteCodeProvider  denUnitedProvider            │
└───────────────────────┬─────────────────────────────┘
                        │ calls
┌───────────────────────▼─────────────────────────────┐
│                  SERVICE LAYER                       │
│  FirebaseAuthService  FirestoreService               │
│  LocationService                                     │
└───────────────────────┬─────────────────────────────┘
                        │ reads/writes
┌───────────────────────▼─────────────────────────────┐
│                  DATA LAYER                          │
│  Firebase Auth  Cloud Firestore  Geolocator          │
└─────────────────────────────────────────────────────┘
```

### Real-Time Data Flow

```
Device GPS → Geolocator → mapControllerProvider
                               │
                               ▼
                    FirestoreService.updateLocation()
                               │
                               ▼
                    Firestore: users/{uid} [lat, lng updated]
                               │
                    (Firestore snapshot triggers)
                               ▼
                    denMembersProvider (StreamProvider)
                               │
                               ▼
                    MapScreen rebuilds markers → Live Map updates
```

---

## 📁 Project Structure

```
DEN/
├── android/
│   └── app/
│       ├── build.gradle.kts          # Desugaring + Firebase plugins
│       ├── google-services.json      # 🔒 Excluded from git
│       └── src/main/AndroidManifest.xml  # Permissions + Maps API key
│
├── web/
│   └── index.html                    # Maps JS API + PWA metadata
│
├── assets/
│   └── screenshots/                  # Portfolio screenshots
│
├── lib/
│   ├── main.dart                     # Entry + SplashScreen (Firebase init)
│   ├── app.dart                      # Root MaterialApp + auth routing
│   ├── firebase_options.dart         # 🔒 Excluded from git
│   │
│   ├── core/
│   │   ├── app_colors.dart           # Design token system (neon palette)
│   │   ├── app_theme.dart            # ThemeData (dark glassmorphism)
│   │   └── spacing_constants.dart    # Layout spacing scale
│   │
│   ├── models/
│   │   ├── user_model.dart           # User: uid, name, denId, lat, lng
│   │   └── den_model.dart            # Den: id, name, createdBy, inviteCode
│   │
│   ├── services/
│   │   ├── firebase_auth_service.dart  # Auth: signIn, signUp, signOut
│   │   └── firestore_service.dart      # Firestore: CRUD + streams
│   │
│   ├── providers/
│   │   ├── auth_provider.dart        # authState, userProfile, AuthController
│   │   ├── den_provider.dart         # denMembers, inviteCode, denUnited
│   │   └── map_provider.dart         # location tracking, SOS
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── den/
│   │   │   └── den_screen.dart       # Create / join Den
│   │   ├── map/
│   │   │   └── map_screen.dart       # Live map + member list + SOS
│   │   └── settings/
│   │       └── settings_screen.dart
│   │
│   ├── widgets/
│   │   └── glass_widgets.dart        # GlassCard, GlassButton
│   │
│   └── utils/
│       └── haversine.dart            # Great-circle distance formula
│
├── test/
│   └── widget_test.dart              # Smoke test
│
├── .gitignore                        # Excludes all Firebase credentials
└── README.md
```

---

## 🔥 Firestore Data Model

```
users/{uid}
  ├── uid          : String
  ├── name         : String
  ├── email        : String
  ├── denId        : String?    # null if not in a Den yet
  ├── latitude     : double?    # Live GPS coordinate
  ├── longitude    : double?    # Live GPS coordinate
  └── lastUpdated  : Timestamp  # For staleness detection

dens/{denId}
  ├── id           : String
  ├── name         : String
  ├── createdBy    : String     # User UID
  ├── createdAt    : Timestamp
  └── inviteCode   : String     # 6-char alphanumeric (e.g. "X7K9PQ")
```

**Realtime Syncing Strategy:**
- `streamUser(uid)` → `users/{uid}` snapshot stream → profile updates instantly
- `streamDenMembers(denId)` → queries all `users` where `denId == X` → live map markers update on every GPS write
- Location writes happen every ~5 seconds via a periodic timer in `mapControllerProvider`

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `≥ 3.11.x` ([Install](https://docs.flutter.dev/get-started/install))
- Firebase account + project ([Console](https://console.firebase.google.com))
- Google Maps API Key ([Get one](https://developers.google.com/maps/documentation/android-sdk/get-api-key))

### 1. Clone

```bash
git clone https://github.com/YOUR_USERNAME/den.git
cd den
flutter pub get
```

### 2. Configure Firebase

> **These files are git-ignored for security. Generate your own.**

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure (generates firebase_options.dart + google-services.json)
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```

Enable these services in Firebase Console:
- ✅ Authentication (Email/Password provider)
- ✅ Cloud Firestore (start in test mode initially)
- ✅ Cloud Messaging (for future push notifications)

### 3. Configure Google Maps

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

**Web** (`web/index.html`):
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE"></script>
```

### 4. Run

```bash
# Android device/emulator
flutter run

# Web (browser)
flutter run -d chrome

# Web (headless server)
flutter run -d web-server --web-port 8080
```

---

## 📦 Production Builds

### Android APK

```bash
flutter build apk --release
# ✅ Output: build/app/outputs/flutter-apk/app-release.apk (~51.9 MB)
```

**Install on device:**
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```
Or transfer the APK file directly and enable "Install Unknown Apps" in settings.

### Flutter Web

```bash
flutter build web --release
# ✅ Output: build/web/ (static files — deploy anywhere)
```

---

## 🌐 Web Deployment

### Firebase Hosting (Recommended)

```bash
npm install -g firebase-tools
firebase login
firebase init hosting
# Set public directory to: build/web
# Configure as SPA: Yes

flutter build web --release
firebase deploy
```

### Vercel / Netlify

1. Run `flutter build web --release`
2. Drag & drop the `build/web/` folder to [vercel.com](https://vercel.com) or [netlify.com](https://netlify.com)
3. Done — instant deployment.

---

## 🔒 Security & Production Notes

> **⚠️ Before making the repo public:**

| Action | How |
|---|---|
| Restrict Maps API Key | [Google Cloud Console](https://console.cloud.google.com) → APIs → Credentials → restrict to your domain/package |
| Deploy Firestore Rules | Firebase Console → Firestore → Rules → restrict reads/writes to `denId` |
| Generate Release Keystore | `keytool -genkey -v -keystore release.jks` for Play Store submission |

**Recommended Firestore Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null &&
        (request.auth.uid == userId ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.denId ==
         resource.data.denId);
      allow write: if request.auth.uid == userId;
    }
    match /dens/{denId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

---

## 🗺️ Roadmap

- [ ] **Push Notifications** — FCM alerts when SOS is triggered
- [ ] **Custom Avatars** — Profile photo upload via Firebase Storage
- [ ] **Location History** — Breadcrumb trail for the last N hours
- [ ] **Geofencing** — Alerts when a member enters/exits a defined zone
- [ ] **iOS Support** — Full Apple Maps + Geolocator support
- [ ] **Den Chat** — Real-time messaging within the private circle
- [ ] **Offline Mode** — Firestore persistence for spotty connections

---

## 🧪 Quality Metrics

| Check | Result |
|---|---|
| `flutter analyze` | ✅ **0 issues** |
| Android APK Build | ✅ **51.9 MB** |
| Web Build | ✅ **Optimized + tree-shaken** |
| Firebase Init | ✅ **With timeout + retry** |
| Null Safety | ✅ **Sound null safety** |
| Debug Banner | ✅ **Removed for production** |

---

## 📄 License

MIT © 2025 — Built with ❤️ using Flutter & Firebase.

---

<p align="center">
  <em>Built as a portfolio project demonstrating production-grade Flutter + Firebase architecture.</em>
</p>
