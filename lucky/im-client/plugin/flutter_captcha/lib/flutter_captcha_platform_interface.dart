import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_captcha_method_channel.dart';

abstract class FlutterCaptchaPlatform extends PlatformInterface {
  /// Constructs a FlutterCaptchaPlatform.
  FlutterCaptchaPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterCaptchaPlatform _instance = MethodChannelFlutterCaptcha();

  /// The default instance of [FlutterCaptchaPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterCaptcha].
  static FlutterCaptchaPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterCaptchaPlatform] when
  /// they register themselves.
  static set instance(FlutterCaptchaPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> showCaptcha(String phoneNo, String countryCode) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
