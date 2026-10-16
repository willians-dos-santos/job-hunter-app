import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Generated based on project configuration in `google-services.json`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBQCinBdnrxCZ3dQvwtseKBHneLAmQZW98',
    appId: '1:496848303361:android:1f254fac2c119e8bec5700',
    messagingSenderId: '496848303361',
    projectId: 'job-hunter-ats-475ca',
    storageBucket: 'job-hunter-ats-475ca.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBQCinBdnrxCZ3dQvwtseKBHneLAmQZW98',
    appId: '1:496848303361:ios:1f254fac2c119e8bec5700',
    messagingSenderId: '496848303361',
    projectId: 'job-hunter-ats-475ca',
    storageBucket: 'job-hunter-ats-475ca.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBQCinBdnrxCZ3dQvwtseKBHneLAmQZW98',
    appId: '1:496848303361:web:1f254fac2c119e8bec5700',
    messagingSenderId: '496848303361',
    projectId: 'job-hunter-ats-475ca',
    storageBucket: 'job-hunter-ats-475ca.firebasestorage.app',
  );
}
