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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyDcFCgBGDis3DhvZI3mKrHnED8v0axdJ6Y',
    appId: '1:1039351191739:web:d6d2f781d1574726c1719e',
    messagingSenderId: '1039351191739',
    projectId: 'series-my88',
    authDomain: 'series-my88.firebaseapp.com',
    storageBucket: 'series-my88.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAlZpGt0mybOIwZDn3-Gqz6SwEuHTf7W3k',
    appId: '1:1039351191739:android:b67724017d6bc772c1719e',
    messagingSenderId: '1039351191739',
    projectId: 'series-my88',
    storageBucket: 'series-my88.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCM_cOmy3CkvqRJ6aqO9Obt7QM91ABfb20',
    appId: '1:1039351191739:ios:d9203d29c229b63ec1719e',
    messagingSenderId: '1039351191739',
    projectId: 'series-my88',
    storageBucket: 'series-my88.firebasestorage.app',
    iosClientId:
        '1039351191739-4jns636cjh2egn2rk6qjgrv705q0n6cb.apps.googleusercontent.com',
    iosBundleId: 'com.example.series',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCM_cOmy3CkvqRJ6aqO9Obt7QM91ABfb20',
    appId: '1:1039351191739:ios:d9203d29c229b63ec1719e',
    messagingSenderId: '1039351191739',
    projectId: 'series-my88',
    storageBucket: 'series-my88.firebasestorage.app',
    iosClientId:
        '1039351191739-4jns636cjh2egn2rk6qjgrv705q0n6cb.apps.googleusercontent.com',
    iosBundleId: 'com.example.series',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDcFCgBGDis3DhvZI3mKrHnED8v0axdJ6Y',
    appId: '1:1039351191739:web:5134e31c1f6ad93fc1719e',
    messagingSenderId: '1039351191739',
    projectId: 'series-my88',
    authDomain: 'series-my88.firebaseapp.com',
    storageBucket: 'series-my88.firebasestorage.app',
  );
}
