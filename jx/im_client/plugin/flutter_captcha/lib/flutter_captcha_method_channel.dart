import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_captcha_platform_interface.dart';

/// An implementation of [FlutterCaptchaPlatform] that uses method channels.
class MethodChannelFlutterCaptcha extends FlutterCaptchaPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_captcha');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> showCaptcha(String phoneNo, String countryCode) async {
    await methodChannel.invokeMethod('verify', <String, dynamic>{
      'phoneNo': phoneNo,
      'countryCode': countryCode,
    });
  }
}
