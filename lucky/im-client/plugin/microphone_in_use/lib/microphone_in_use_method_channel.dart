import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'microphone_in_use_platform_interface.dart';

/// An implementation of [MicrophoneInUsePlatform] that uses method channels.
class MethodChannelMicrophoneInUse extends MicrophoneInUsePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('microphone_in_use');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> isMicrophoneInUse() async {
    final isMicrophoneInUse = await methodChannel.invokeMethod<bool>('isMicrophoneInUse');
    return isMicrophoneInUse ?? false;
  }
}
