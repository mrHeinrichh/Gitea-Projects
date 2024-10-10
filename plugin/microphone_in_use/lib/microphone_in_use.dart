
import 'microphone_in_use_platform_interface.dart';

class MicrophoneInUse {
  Future<String?> getPlatformVersion() {
    return MicrophoneInUsePlatform.instance.getPlatformVersion();
  }

  static Future<bool> isMicrophoneInUse() async {
    return MicrophoneInUsePlatform.instance.isMicrophoneInUse();
  }
}
