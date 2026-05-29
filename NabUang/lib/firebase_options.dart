import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS belum dikonfigurasi.');
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAUT7wiy1z9PlQQqk53734MFhyKlSySKjc',
    appId: '1:455419041525:web:8256cbd21f87f1a51897bc',
    messagingSenderId: '455419041525',
    projectId: 'nabuang-a973d',
    authDomain: 'nabuang-a973d.firebaseapp.com',
    storageBucket: 'nabuang-a973d.firebasestorage.app',
    measurementId: 'G-20SXYD3F8K',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAUT7wiy1z9PlQQqk53734MFhyKlSySKjc',
    appId: '1:455419041525:android:728c36d5e1eb88d81897bc',
    messagingSenderId: '455419041525',
    projectId: 'nabuang-a973d',
    storageBucket: 'nabuang-a973d.firebasestorage.app',
  );
}
