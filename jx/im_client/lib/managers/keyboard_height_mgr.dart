import 'dart:io';

import 'package:jxim_client/utils/platform_utils.dart';

class KeyboardHeightManager {
  KeyboardHeightManager._internal();

  factory KeyboardHeightManager() => _instance;
  static final KeyboardHeightManager _instance =
      KeyboardHeightManager._internal();

  Future<void> init() async {}

  Future<String?> getDeviceModel() async {
    final deviceInfo = await PlatformUtils.getDeviceInfo();
    if (Platform.isAndroid) {
      return deviceInfo.model;
    } else if (Platform.isIOS) {
      return deviceInfo.utsname.machine;
    }
    return null;
  }
}
