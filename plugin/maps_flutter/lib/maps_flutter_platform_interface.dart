import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'maps_flutter_method_channel.dart';

abstract class MapsFlutterPlatform extends PlatformInterface {
  /// Constructs a MapsFlutterPlatform.
  MapsFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static MapsFlutterPlatform _instance = MethodChannelMapsFlutter();

  /// The default instance of [MapsFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelMapsFlutter].
  static MapsFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MapsFlutterPlatform] when
  /// they register themselves.
  static set instance(MapsFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
