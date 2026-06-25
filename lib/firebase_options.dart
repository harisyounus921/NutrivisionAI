// File generated from Firebase config files.
// Re-run flutterfire configure if the Firebase project changes.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase web options are not configured.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase is only configured for Android and iOS.',
        );
      default:
        throw UnsupportedError('Firebase is not configured for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyArOXGACKjLOOdmg6XR3fG49-HIKEseuas',
    appId: '1:123265212903:android:e5205d9f2c1621b4dbdd42',
    messagingSenderId: '123265212903',
    projectId: 'stylst-921',
    storageBucket: 'stylst-921.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAVlqSzWxCtB_2qa_DAAZFwKmpgZOJAmyQ',
    appId: '1:123265212903:ios:34493aea24675bb8dbdd42',
    messagingSenderId: '123265212903',
    projectId: 'stylst-921',
    storageBucket: 'stylst-921.firebasestorage.app',
    iosBundleId: 'com.haris.mealnudge',
  );
}
