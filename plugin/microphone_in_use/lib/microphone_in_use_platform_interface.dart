import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'microphone_in_use_method_channel.dart';

abstract class MicrophoneInUsePlatform extends PlatformInterface {
  /// Constructs a MicrophoneInUsePlatform.
  MicrophoneInUsePlatform() : super(token: _token);

  static final Object _token = Object();

  static MicrophoneInUsePlatform _instance = MethodChannelMicrophoneInUse();

  /// The default instance of [MicrophoneInUsePlatform] to use.
  ///
  /// Defaults to [MethodChannelMicrophoneInUse].
  static MicrophoneInUsePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MicrophoneInUsePlatform] when
  /// they register themselves.
  static set instance(MicrophoneInUsePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> isMicrophoneInUse() async {
    throw UnimplementedError('isMicrophoneInUse() has not been implemented.');
  }
}
