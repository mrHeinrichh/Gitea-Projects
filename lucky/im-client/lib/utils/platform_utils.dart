import 'dart:io';
import 'dart:async';

import 'package:jxim_client/utils/utility.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 是否是生产环境
// const bool inProduction = bool.fromEnvironment("dart.vm.product");

class PlatformUtils {
  static late String appName;
  static late String deviceBrand;

  static Future<void> init() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      //安卓手机
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceBrand = '${androidInfo.brand}';
    } else if (Platform.isIOS) {
      //苹果手机
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceBrand = '${iosInfo.systemName} ${iosInfo.utsname.nodename}';
    } else if (Platform.isWindows) {
      //Windows电脑
      WindowsDeviceInfo windowInfo = await deviceInfo.windowsInfo;
      deviceBrand = '${windowInfo.computerName}';
    } else if (Platform.isMacOS) {
      //MacOS电脑
      MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
      deviceBrand = '${macInfo.model}';
    } else if (Platform.isLinux) {
      //Linux电脑
      LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      deviceBrand = '${linuxInfo.name}';
    }
  }

  static Future<String> getAppName() async{
    PackageInfo info = await PackageInfo.fromPlatform();
    return info.appName;
  }

  static Future<String> getPackageName() async{
    PackageInfo info = await PackageInfo.fromPlatform();
    return info.packageName;
  }

  static Future<String> getAppVersion() async{
    PackageInfo info = await PackageInfo.fromPlatform();
    return info.version;
  }

  static Future<String> getBuildNum() async{
    PackageInfo info = await PackageInfo.fromPlatform();
    return info.buildNumber;
  }

  static Future<String> getBrand() async{
    PackageInfo info = await PackageInfo.fromPlatform();
    return info.buildNumber;
  }

  static Future<String> getFullVersion() async {
    PackageInfo info = await PackageInfo.fromPlatform();
    return info.version + "+" + info.buildNumber;
  }

  /// 获取设备信息
  static Future getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      return await deviceInfo.androidInfo;
    } else if (Platform.isIOS) {
      return await deviceInfo.iosInfo;
    } else {
      return null;
    }
  }

  static Future getDeviceString() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo info = await deviceInfo.androidInfo;
      return '安卓 ${info.board} ${info.model} ${info.version.release} ${info.version.securityPatch}';
    } else if (Platform.isIOS) {
      IosDeviceInfo info = await deviceInfo.iosInfo;
      return 'IOS ${info.systemName} ${info.utsname} ${info.systemVersion}';
    } else if (Platform.isMacOS) {
      MacOsDeviceInfo info = await deviceInfo.macOsInfo;
      return 'MAC ${info.osRelease}';
    } else if (Platform.isWindows) {
      WindowsDeviceInfo info = await deviceInfo.windowsInfo;
      return 'Windows ${info.productName}';
    } else {
      return null;
    }
  }

  /// 获取设备唯一标识码
  static Future<String?> getDeviceIdentifier() async {
    // todo bpush token好像更不容易变化
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    // String? token = makeMD5("sdfsdfsdfk");

    if (Platform.isAndroid) {
      AndroidDeviceInfo info = await deviceInfoPlugin.androidInfo;
      return info.id;
    } else {
      IosDeviceInfo info = await deviceInfoPlugin.iosInfo;
      return info.identifierForVendor;
    }
  }

  /// 获取设备唯一标识码
  static Future<String?> getDeviceToken() async {
    // todo bpush token好像更不容易变化
    String? token = await getDeviceIdentifier();
    if (token != null) {
      token = "jxim_sing:" + token;
      token = makeMD5(token);
    }
    // pdebug("+++++++++++++:"+token!);
    return token;
  }

  /// 获取设备brand
  static Future<String?> getDeviceBrand() async {
    // todo bpush token好像更不容易变化
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      var info = await deviceInfoPlugin.androidInfo;
      return info.brand;
    }
    return null;
  }

  static String? deviceFingerprint;

  /// 获取设备唯一标识码
  static Future<String?> getDeviceFingerprint() async {
    // if (deviceFingerprint == null) {
    //   DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    //   String? fingerprint;
    //   if (Platform.isAndroid) {
    //     var info = await deviceInfoPlugin.androidInfo;
    //     fingerprint = info.fingerprint!;
    //   } else {
    //     var info = await deviceInfoPlugin.initIosUuid(appName);
    //     fingerprint = (info.systemName ?? "") +
    //         "/" +
    //         (info.systemVersion ?? "") +
    //         "/" +
    //         (info.utsname.machine ?? "") +
    //         "/" +
    //         (info.utsname.version ?? "");
    //   }
    //   deviceFingerprint = fingerprint;
    // }
    return "deviceFingerprint";
  }
}
