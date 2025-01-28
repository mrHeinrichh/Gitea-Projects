import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_fconsole_platform_interface.dart';

/// An implementation of [FlutterFconsolePlatform] that uses method channels.
class MethodChannelFlutterFconsole extends FlutterFconsolePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_fconsole');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
