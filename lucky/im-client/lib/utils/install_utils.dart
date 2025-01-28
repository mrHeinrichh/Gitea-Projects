import 'package:flutter/services.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';

class InstallUtils {
  final _methodChannel = const MethodChannel("jxim/install");

  static final InstallUtils _instance = InstallUtils._internal();
  factory InstallUtils() {
    return _instance;
  }

  InstallUtils._internal() {
    _methodChannel.setMethodCallHandler(handleNativeCallback);
  }

  Future<void> startInstallApk(String filePath) async {
    Map<String, String> params = {'filePath': filePath};
    final data = await _methodChannel.invokeMethod('startInstallApk', params);
    if(data != "Success"){
      Toast.showToast(localized(installSuccess));
    }
  }

  Future<void> handleNativeCallback(MethodCall call) async {
    if (call.method == 'registerJPush') {

    }
  }

}
