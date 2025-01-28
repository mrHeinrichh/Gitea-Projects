import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/device_utils.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:platform_device_id/platform_device_id.dart';

/// 是否是生产环境
// const bool inProduction = bool.fromEnvironment("dart.vm.product");

class PlatformUtils {
  static late String appName;
  static late String deviceBrand;
  static late String deviceId;
  static late String deviceToken; ////当此值变化时，token会被清除掉
  static late String deviceName;
  static late int osType;

  static Future<void> init() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      //安卓手机
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceName = '${androidInfo.brand} ${androidInfo.model}';
      deviceBrand = androidInfo.brand;
      deviceId = androidInfo.id;
      osType = 1;
    } else if (Platform.isIOS) {
      //苹果手机
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceBrand = '${iosInfo.systemName} ${iosInfo.utsname.nodename}';
      deviceId = '${iosInfo.identifierForVendor}';
      deviceName = getIOSDeviceName(iosInfo.utsname.machine);
      osType = 2;
    } else if (Platform.isWindows) {
      //Windows电脑
      WindowsDeviceInfo windowInfo = await deviceInfo.windowsInfo;
      deviceName = windowInfo.computerName;
      deviceBrand = windowInfo.computerName;
      deviceId = windowInfo.deviceId;
      osType = 3;
    } else if (Platform.isMacOS) {
      //MacOS电脑
      MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
      deviceName = getMacDeviceName(macInfo.model);
      deviceBrand = macInfo.model;
      deviceId = '${macInfo.systemGUID}';
      osType = 4;
    } else if (Platform.isLinux) {
      //Linux电脑
      LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      deviceName = linuxInfo.name;
      deviceBrand = linuxInfo.name;
      deviceId = '${linuxInfo.machineId}';
      osType = 5;
    } else {
      deviceBrand = '';
      deviceName = '';
      deviceId = '';
      osType = 6;
    }
    String? my_deviceToken;
// Platform messages may fail, so we use a try/catch PlatformException.
    try {
      my_deviceToken = await PlatformDeviceId.getDeviceId;
    } catch (e, s) {
      pdebug('获取my_deviceId失败', error: e, stackTrace: s);
      my_deviceToken = '';
    }
    if (my_deviceToken!.isNotEmpty) {
      deviceToken = my_deviceToken;
    }

    String? my_deviceId;
// Platform messages may fail, so we use a try/catch PlatformException.
    try {
      my_deviceId = makeMD5(await FlutterUdid.consistentUdid + deviceName);
    } catch (e, s) {
      pdebug('获取my_deviceToken失败', error: e, stackTrace: s);
      my_deviceId = '';
    }
    if (my_deviceId.isNotEmpty) {
      deviceId = my_deviceId;
    }

    pdebug(' deviceName: $deviceName '
        ' deviceBrand:$deviceBrand '
        ' deviceToken:$deviceToken '
        ' deviceId:$deviceId '
        ' osType:$osType');
  }

  static Future<String> getAppName() async {
    PackageInfo info = await PackageInfo.fromPlatform();
    return info.appName;
  }

  static Future<String> getPackageName() async {
    PackageInfo info = await PackageInfo.fromPlatform();
    return info.packageName;
  }

  static Future<String> getAppVersion() async {
    PackageInfo info = await PackageInfo.fromPlatform();
    return info.version;
  }

  static Future<String> getBuildNum() async {
    PackageInfo info = await PackageInfo.fromPlatform();
    return info.buildNumber;
  }

  static Future<String> getBrand() async {
    PackageInfo info = await PackageInfo.fromPlatform();
    return info.buildNumber;
  }

  static Future<String> getFullVersion() async {
    PackageInfo info = await PackageInfo.fromPlatform();
    return "${info.version}+${info.buildNumber}";
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
    String? token = await getDeviceIdentifier();
    if (token != null) {
      token = "jxim_sing:$token";
      token = makeMD5(token);
    }
    // pdebug("+++++++++++++:"+token!);
    return token;
  }

  /// 获取设备brand
  static Future<String?> getDeviceBrand() async {
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
