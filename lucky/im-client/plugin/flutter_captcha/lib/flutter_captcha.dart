import 'package:flutter/services.dart';

import 'flutter_captcha_platform_interface.dart';

class FlutterCaptcha {
  final methodChannel = const MethodChannel('flutter_captcha');

  Future<String?> getPlatformVersion() {
    return FlutterCaptchaPlatform.instance.getPlatformVersion();
  }

  Future<void> showCaptcha(String phoneNo, String countryCode) {
    return FlutterCaptchaPlatform.instance.showCaptcha(phoneNo, countryCode);
  }

  Future<void> captchaListener({
    required Function onSuccess,
    required Function onFail,
  }) async {
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'getResult') {
        try {
          final data = await call.arguments;
          if (data == true) {
            onSuccess();
          } else {
            onFail();
          }
        } catch (e) {
          print('[Flutter_Captcha_Error]$e');
        }
      }
    });
  }
}
