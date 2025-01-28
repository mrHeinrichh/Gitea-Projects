import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/im_toast/overlay_extension.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:screenshot/screenshot.dart';

class EncryptionQrCodeController extends GetxController {
  late User user;
  RxString qrCodeData = ''.obs;

  @override
  void onInit() {
    super.onInit();
    user = objectMgr.userMgr.mainUser;
    objectMgr.encryptionMgr.triggerQrCodeDownload();
    generateQrCode();
  }

  void generateQrCode() {
    String privateKey = objectMgr.localStorageMgr
            .read(LocalStorageMgr.ENCRYPTION_PRIVATE_KEY) ??
        '';

    if (user != null && privateKey.isNotEmpty) {
      Map<String, dynamic> data = {};
      data['uid'] = user.uid;
      data['privateKey'] = privateKey;
      qrCodeData.value = jsonEncode(data);
    }
  }

  void downloadQrCode(Widget widget) {
    int uid = objectMgr.userMgr.mainUser.uid;
    Toast.showLoadingPopup(
      Get.context!,
      DialogType.loading,
      localized(downloading),
    );
    downloadQR(widget, uid);
  }

  Future<void> downloadQR(Widget widget, int uid) async {
    if (objectMgr.loginMgr.isDesktop) {
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
      dismissAllToast();
    } else {
      getEncryptionCardFile(widget, uid);
    }
  }

  getEncryptionCardFile(Widget widget, int uid) async {
    var string = await saveImageWidgetToGallery(
        imageWidget: widget,
        cachePath: "${uid}_encryptionCard.jpg",
        subDir: "encryptionCard");
    dismissAllToast();
    return string;
  }
}
