import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:jxim_client/main.dart';

import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';

class KeyboardHeightManager {
  KeyboardHeightManager._internal();

  factory KeyboardHeightManager() => _instance;
  static final KeyboardHeightManager _instance =
      KeyboardHeightManager._internal();

  Future<void> init() async {
    // try {
    //   final model = await getDeviceModel();
    //   final height = objectMgr.localStorageMgr
    //       .read<double?>(LocalStorageMgr.KEYBOARD_HEIGHT);
    //   if (height != null) {
    //     // 本地有就上传
    //     if (model != null) {
    //       updateStore(model, keyboardHeight.toString());
    //     }
    //     return;
    //   }
    //   // 本地没有从服务器获取
    //   if (model != null) {
    //     final data = await getStore(model);
    //     debugPrint(
    //         '[KeyboardHeightManager]: Get KeyboardHeight height ${data.value}');
    //     if (data.value.isNotEmpty) {
    //       keyboardHeight.value = double.tryParse(data.value) ?? 0.0;
    //     }
    //   }
    // } catch (e) {
    //   debugPrint(
    //       '[KeyboardHeightManager]: KeyboardHeightManager init error $e');
    // }
  }

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
