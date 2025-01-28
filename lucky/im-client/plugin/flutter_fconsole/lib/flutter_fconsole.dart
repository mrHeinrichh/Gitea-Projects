
import 'flutter_fconsole_platform_interface.dart';

class FlutterFconsole {
  Future<String?> getPlatformVersion() {
    return FlutterFconsolePlatform.instance.getPlatformVersion();
  }
}
