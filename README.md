# Nutrivision AI — AI Diet Monitoring App

Nutrivision AI is a cross-platform (Android/iOS) mobile app, built with
Flutter, that automates diet tracking using AI-powered food image
recognition, barcode scanning, and a conversational AI diet coach. It reduces
the manual effort of conventional calorie-tracking apps while providing
personalized nutrition feedback.

## Getting Started

### Prerequisites

- Flutter SDK 3.41 or newer (Dart 3.x) — run `flutter doctor` and resolve any
  reported issues before building
- Android Studio or VS Code with the Flutter and Dart plugins
- **Android:** Android SDK with a connected device or emulator running
  Android 8.0 (API 26) or higher
- **iOS (macOS only):** Xcode with a configured simulator or device

### Run the app

1. Install dependencies:

   ```
   flutter pub get
   ```

2. Start an emulator or connect a device, then confirm it is detected:

   ```
   flutter devices
   ```

3. Launch the app:

   ```
   flutter run
   ```

   To target a specific device, pass its id: `flutter run -d <device_id>`.
   Add `--release` to run the optimized build instead of debug.

### Build an Android APK

- **Single APK for all architectures** (largest file, installs on any device):

  ```
  flutter build apk --release
  ```

  Output: `build/app/outputs/flutter-apk/app-release.apk`

- **Per-architecture APKs** (recommended for sideloading — each phone only
  needs its own architecture, e.g. `arm64-v8a` for most modern devices):

  ```
  flutter build apk --release --split-per-abi
  ```

  Outputs `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, and
  `app-x86_64-release.apk` in the same folder.

- **Play Store app bundle** (Google delivers the matching architecture to each
  device):

  ```
  flutter build appbundle --release
  ```

  Output: `build/app/outputs/bundle/release/app-release.aab`

Install a freshly built APK on a connected device with:

```
flutter install --release
```