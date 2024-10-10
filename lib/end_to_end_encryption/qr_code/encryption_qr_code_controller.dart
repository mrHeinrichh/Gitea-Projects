import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';

class EncryptionQrCodeController extends GetxController {
  late User user;
  RxString qrCodeData = ''.obs;

  @override
  void onInit() {
    super.onInit();
    user = objectMgr.userMgr.mainUser;

    generateQrCode();
  }

  void generateQrCode() {
    String privateKey = objectMgr.localStorageMgr.read(LocalStorageMgr.ENCRYPTION_PRIVATE_KEY) ?? '';

    if (user != null && privateKey.isNotEmpty) {
      Map<String, dynamic> data = {};
      data['uid'] = user.uid;
      data['privateKey'] = privateKey;
      qrCodeData.value = jsonEncode(data);
    }
  }

  void downloadQrCode(Widget widget) {
    int uid = objectMgr.userMgr.mainUser.uid;
    downloadQR(widget, uid);
  }


  Future<void> downloadQR(Widget widget, int uid) async {
    if (objectMgr.loginMgr.isDesktop) {
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(imageDownloading),
        icon: ImBottomNotifType.loading,
      );
      final controller = ScreenshotController();
      final bytes = await controller.captureFromWidget(Material(child: widget));
      desktopDownloadMgr.desktopSaveTo(
        'MY-HeyTalk-EncryptionCardQR.jpg',
        bytes,
        navigatorKey.currentContext!,
      );
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(imageSaved),
        icon: ImBottomNotifType.qrSaved,
      );
    } else {
      getEncryptionCardFile(widget, uid);
    }
  }

  getEncryptionCardFile(Widget widget, int uid) async {
    PermissionStatus status = PermissionStatus.granted;
    if(defaultTargetPlatform == TargetPlatform.iOS){
      status = await Permission.photos.request();
    }
    if (status.isGranted) {
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(imageDownloading),
        icon: ImBottomNotifType.loading,
      );
      String cachePath = await downloadMgr.getTmpCachePath(
        "${uid}_encryptionCard.jpg",
        sub: "encryptionCard",
        create: false,
      );

      final controller = ScreenshotController();
      final bytes =
      await controller.captureFromWidget(Material(child: widget));
      File(cachePath).createSync(recursive: true);
      File(cachePath).writeAsBytesSync(bytes);
      ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: 'image_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(imageSaved),
        icon: ImBottomNotifType.qrSaved,
      );

      return cachePath;
    } else if(defaultTargetPlatform == TargetPlatform.iOS){
      final rationale = await Permission.photos.shouldShowRequestRationale;
      if (rationale || status.isPermanentlyDenied) {
        openAppSettings();
      } else {
        await Permission.photos.request();
      }
    }
  }

}