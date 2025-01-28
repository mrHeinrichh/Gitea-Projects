import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/app_version.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/install_utils.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:url_launcher/url_launcher_string.dart';

AppVersionUtils appVersionUtils = AppVersionUtils();

class AppVersionUtils {
  init() async {
    initCurrentAppVersion();
  }

  String currentAppVersion = "";
  CancelToken? _cancelToken;

  CancelToken? get cancelToken => _cancelToken;
  bool isBottomSheetOpen = false; //版本更新modal
  bool isDetailBottomSheetOpen = false; //版本更新详情modal
  bool isDownLoadBottomSheetOpen = false; //下载版本modal
  int uniId = 0;
  HeartBeatAppVersion? heartBeatAppVersion;
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  ///从API获取最新版本号
  Future<PlatformDetail?> getAppVersionByRemote() async {
    PlatformDetail? platformDetail = await Version().getAppVersion();
    return platformDetail;
  }

  ///推荐更新
  Future<bool> softUpdate({PlatformDetail? platformDetail}) async {
    bool status = false;
    String currentVersion = await PlatformUtils.getAppVersion();

    platformDetail ??= await getAppVersionByRemote();

    String apiVersion = platformDetail?.version ?? currentVersion;
    final comparison = currentVersion.compareVersion(apiVersion);

    /// comparison < 0 : currentVersion is less than apiVersion
    /// comparison > 0 : currentVersion is greater than apiVersion
    /// comparison == 0 : currentVersion is same as apiVersion

    if (comparison < 0) {
      status = true;
    }
    return status;
  }

  ///强制更新
  Future<bool> forceUpdate({PlatformDetail? platformDetail}) async {
    bool status = false;
    String currentVersion = await PlatformUtils.getAppVersion();

    platformDetail ??= await getAppVersionByRemote();

    String minVersion = platformDetail?.minVersion ?? currentVersion;
    final comparison = currentVersion.compareVersion(minVersion);

    /// comparison < 0 : currentVersion is less than minVersion
    /// comparison > 0 : currentVersion is greater than minVersion
    /// comparison == 0 : currentVersion is same as minVersion

    if (comparison < 0) {
      status = true;
    }
    return status;
  }

  ///跳转更新版本网址
  openDownloadLink(
    BuildContext context,
    PlatformDetail? data, {
    Function? didDownloaded,
  }) async {
    if (Platform.isAndroid) {
      downloadAndroid(data!.url, context, didDownloaded);
    } else if (notBlank(data?.url)) {
      if (await canLaunchUrlString(data!.url)) {
        await launchUrlString(data.url, mode: LaunchMode.externalApplication);
      } else {
        Toast.showToast(localized(toastLinkInvalid));
      }
    } else {
      Toast.showToast(localized(toastLinkInvalid));
    }
  }

  void downloadAndroid(
    String url,
    BuildContext context,
    Function? didDownloaded,
  ) async {
    if (url.split('/').isEmpty) {
      Toast.showToast(localized(failedToDownload));
      return;
    }

    /// 创建存储文件
    String filePath = "apk/${url.split("/").last}";
    String? savePath = downloadMgr.getSavePath(filePath);
    try {
      /// 显示外部通知
      showProgressNotification(flutterLocalNotificationsPlugin);

      final homeController = Get.find<HomeController>();

      _cancelToken = CancelToken();

      DownloadResult result = await downloadMgrV2.download(
        url,
        cancelToken: _cancelToken,
        onReceiveProgress: (int bytes, int totalBytes) {
          if (_cancelToken!.isCancelled) {
            homeController.apkDownloadProgress.value = 0;
            return;
          }
          double progress = bytes / totalBytes;
          homeController.apkDownloadProgress.value = progress;
          homeController.fileSize.value = bytes;
          homeController.totalFileSize.value = totalBytes;
        },
        timeout: const Duration(seconds: 1800),
      );
      savePath = result.localPath;

      // savePath = await downloadMgr.downloadFile(
      //   url,
      //   timeout: const Duration(seconds: 1800),
      //   cancelToken: _cancelToken,
      //   onReceiveProgress: (int bytes, int totalBytes) {
      //     if (_cancelToken!.isCancelled) {
      //       homeController.apkDownloadProgress.value = 0;
      //       return;
      //     }
      //     double progress = bytes / totalBytes;
      //     homeController.apkDownloadProgress.value = progress;
      //     homeController.fileSize.value = bytes;
      //     homeController.totalFileSize.value = totalBytes;
      //   },
      // );
      if (savePath != null) {
        final file = File(savePath);
        bool installSuccess = false;
        if (await checkMd5(savePath, file)) {
          InstallUtils().startInstallApk(savePath);
          installSuccess = true;
        } else {
          try {
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            pdebug("删除APK失败： ${e.toString()}");
          }
          installSuccess = false;
        }
        didDownloaded?.call();
        Get.back();
        if (!installSuccess) {
          imBottomToast(
            Get.context!,
            title: 'apk安装失败',
            icon: ImBottomNotifType.warning,
          );
        }
      } else {
        if (!(_cancelToken?.isCancelled ?? false)) {
          Get.back();
          Toast.showToast(localized(toastFileFailed));
        }
      }

      pdebug("localUrl==========> $savePath");
    } catch (e) {
      Toast.showToast(localized(failedToDownload));
      pdebug("APK下载失败： ${e.toString()}");
    }
  }

  Future<bool> checkMd5(String savePath, File file) async {
    HeartBeatAppVersion appVersion = await appVersionUtils.getLocalAppDetail();

    final fileBytes = await file.readAsBytes();
    final md5Hash = md5.convert(fileBytes);

    if (appVersion.hash == md5Hash.toString().toUpperCase()) {
      return true;
    } else {
      return false;
    }
  }

  showProgressNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin, {
    int progress = 0,
  }) async {
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initSettings);

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'jxApkVerDownload',
      'progress',
      channelDescription: 'progress description',
      channelShowBadge: false,
      importance: Importance.max,
      priority: Priority.max,
      onlyAlertOnce: true,
      indeterminate: true,
      progress: progress,
      showProgress: true,
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    flutterLocalNotificationsPlugin.show(
      uniId,
      null,
      localized(appUpdating),
      platformChannelSpecifics,
    );
  }

  cancelProgressNotification() {
    flutterLocalNotificationsPlugin.cancel(uniId);
  }

  String? getSystemPlatform() {
    if (Platform.isAndroid) {
      return SystemPlatform.android.value;
    } else if (Platform.isIOS) {
      return SystemPlatform.ios.value;
    } else if (Platform.isWindows) {
      return SystemPlatform.windows.value;
    } else if (Platform.isMacOS) {
      return SystemPlatform.mac.value;
    } else {
      return null;
    }
  }

  int? getOsType() {
    if (Platform.isAndroid) {
      return OsType.android.value;
    } else if (Platform.isIOS) {
      return OsType.ios.value;
    } else if (Platform.isWindows) {
      return OsType.windows.value;
    } else if (Platform.isMacOS) {
      return OsType.mac.value;
    } else {
      return null;
    }
  }

  String? getDownloadPlatform() {
    if (Platform.isAndroid) {
      return Config().androidPlatform;
    } else if (Platform.isIOS) {
      return Config().isTestFlight
          ? DownloadPlatform.testflight.value
          : DownloadPlatform.supersign.value;
    } else if (Platform.isWindows) {
      return DownloadPlatform.windows.value;
    } else if (Platform.isMacOS) {
      return DownloadPlatform.mac.value;
    } else {
      return null;
    }
  }

  Future<String> initCurrentAppVersion() async {
    if (!notBlank(currentAppVersion)) {
      currentAppVersion = await PlatformUtils.getAppVersion();
    }
    return currentAppVersion;
  }

  Future<HeartBeatAppVersion> getLocalAppDetail() async {
    final json = await objectMgr.localStorageMgr
            .read(LocalStorageMgr.APP_VERSION_DETAIL) ??
        '';
    Map<String, dynamic> map = notBlank(json) ? jsonDecode(json) : {};
    return HeartBeatAppVersion.fromJson(map);
  }

  bool checkCloseAppVersion() {
    String closeVersion =
        objectMgr.localStorageMgr.read(LocalStorageMgr.CLOSE_APP_VERSION) ?? '';

    final comparisonVersion = currentAppVersion
        .compareVersion(heartBeatAppVersion?.version ?? '0.0.0');

    if (comparisonVersion < 0 && heartBeatAppVersion?.version != closeVersion) {
      return true;
    } else {
      return false;
    }
  }
}

extension VersionExtension on String {
  int compareVersion(String version) {
    if (!notBlank(version)) {
      version = "0.0.0";
    }
    List<int> currentVersionList = split('.').map(int.parse).toList();
    List<int> compareVersionList = version.split('.').map(int.parse).toList();

    while (currentVersionList.length < 3) {
      currentVersionList.add(0);
    }
    while (compareVersionList.length < 3) {
      compareVersionList.add(0);
    }

    // Compare components
    for (int i = 0; i < 3; i++) {
      if (currentVersionList[i] < compareVersionList[i]) {
        return -1; // currentVersion is less than compareVersion
      } else if (currentVersionList[i] > compareVersionList[i]) {
        return 1; // currentVersion is greater than compareVersion
      }
    }

    return 0;
  }
}
