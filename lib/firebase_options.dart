// File generated manually to support Android and Web platforms.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAnlgey9i30a85OBpqERC8QUOMOIlvGVcA',
    appId: '1:1086245508574:web:8f4b613f04ed6ce32e794f',
    messagingSenderId: '1086245508574',
    projectId: 'schat-aa86b',
    authDomain: 'schat-aa86b.firebaseapp.com',
    storageBucket: 'schat-aa86b.firebasestorage.app',
    measurementId: 'G-MBW35BFDMD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDrn-7ZT0MB5uRM8hmM__Hr7AAGI9tR5WE',
    appId: '1:1086245508574:android:f51bf2605ce4c50d2e794f',
    messagingSenderId: '1086245508574',
    projectId: 'schat-aa86b',
    storageBucket: 'schat-aa86b.firebasestorage.app',
  );
}
