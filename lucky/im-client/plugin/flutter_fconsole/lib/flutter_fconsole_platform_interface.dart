import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_fconsole_method_channel.dart';

abstract class FlutterFconsolePlatform extends PlatformInterface {
  /// Constructs a FlutterFconsolePlatform.
  FlutterFconsolePlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterFconsolePlatform _instance = MethodChannelFlutterFconsole();

  /// The default instance of [FlutterFconsolePlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterFconsole].
  static FlutterFconsolePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterFconsolePlatform] when
  /// they register themselves.
  static set instance(FlutterFconsolePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
