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
    apiKey: 'AIzaSyAFX2VbXydCRZEyaq8XZEaHCdkcX__XEUk',
    appId: '1:281960272701:web:253f385eaeec775bb0eb54',
    messagingSenderId: '281960272701',
    projectId: 'j-talk-eb0aa',
    authDomain: 'j-talk-eb0aa.firebaseapp.com',
    storageBucket: 'j-talk-eb0aa.appspot.com',
    measurementId: 'G-7DCW2J84YR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAFX2VbXydCRZEyaq8XZEaHCdkcX__XEUk',
    appId: '1:281960272701:android:58847b5efa40bf41b0eb54',
    messagingSenderId: '281960272701',
    projectId: 'j-talk-eb0aa',
    storageBucket: 'j-talk-eb0aa.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAFX2VbXydCRZEyaq8XZEaHCdkcX__XEUk',
    appId: '1:281960272701:ios:7bd70923d3f268a3b0eb54',
    messagingSenderId: '281960272701',
    projectId: 'j-talk-eb0aa',
    storageBucket: 'j-talk-eb0aa.appspot.com',
    iosBundleId: 'com.jiangxia.im',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAFX2VbXydCRZEyaq8XZEaHCdkcX__XEUk',
    appId: '1:281960272701:ios:1b0a5588db5a8dc4b0eb54',
    messagingSenderId: '281960272701',
    projectId: 'j-talk-eb0aa',
    storageBucket: 'j-talk-eb0aa.appspot.com',
    iosBundleId: 'com.jiangxia.jximClient',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAFX2VbXydCRZEyaq8XZEaHCdkcX__XEUk',
    appId: '1:281960272701:web:127c8ffb2c27d491b0eb54',
    messagingSenderId: '281960272701',
    projectId: 'j-talk-eb0aa',
    authDomain: 'j-talk-eb0aa.firebaseapp.com',
    storageBucket: 'j-talk-eb0aa.appspot.com',
    measurementId: 'G-HDMNHCMHTE',
  );
}
