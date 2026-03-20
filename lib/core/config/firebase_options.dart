// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS:     return ios;
      default: throw UnsupportedError('Unsupported platform');
    }
  }
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDnsV6mwRd8ONmGIREmmIJt0V8c3o_VjmY',
    appId: '1:517819561284:web:28e044933e416b16c01311',
    messagingSenderId: '517819561284',
    projectId: 'azoyun-569b2',
    authDomain: 'azoyun-569b2.firebaseapp.com',
    databaseURL: 'https://azoyun-569b2-default-rtdb.firebaseio.com',
    storageBucket: 'azoyun-569b2.firebasestorage.app',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD4g57Y9pdan7U8I9sO2Jhgtz7yyCcGKp8',
    appId: '1:517819561284:android:d8f5631f7e8d72e1c01311',
    messagingSenderId: '517819561284',
    projectId: 'azoyun-569b2',
    databaseURL: 'https://azoyun-569b2-default-rtdb.firebaseio.com',
    storageBucket: 'azoyun-569b2.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCb-brF3v0wyZ4aHu3yjdrQI6jBoNTay2c',
    appId: '1:517819561284:ios:1790d41295fb5868c01311',
    messagingSenderId: '517819561284',
    projectId: 'azoyun-569b2',
    databaseURL: 'https://azoyun-569b2-default-rtdb.firebaseio.com',
    storageBucket: 'azoyun-569b2.firebasestorage.app',
    iosBundleId: 'com.ferdidrgn.azgame',
  );
}
