import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/install_info.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';

class ShareController extends GetxController {
  var installedApp = {};
  bool isWhatsappInstalled = true;
  bool isTelegramInstalled = true;
  final downloadLink = '${Config().officialUrl}downloads/'.obs;
  final isLoading = false.obs;

  final int? groupChatId;

  ShareController({this.groupChatId}) : super();

  @override
  onInit() {
    super.onInit();
    getDownloadLink();
  }

  getDownloadLink() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      InstallInfo installInfo = await getDownloadUrl(chatId: groupChatId);
      downloadLink.value = installInfo.url;
      if (downloadLink.value.startsWith("https://")) {
        downloadLink.value = downloadLink.value.replaceFirst("https://", "");
      }
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
    isLoading.value = false;
  }

  Future<void> downloadAppQR(Widget widget, {bool isShare = false}) async {
    final Permission permission = defaultTargetPlatform == TargetPlatform.iOS
        ? Permission.photos
        : Permission.storage;

    final PermissionStatus status = await permission.status;
    final bool rationale = await permission.shouldShowRequestRationale;
    if (status.isGranted) {
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(imageDownloading),
        icon: ImBottomNotifType.loading,
      );

      final controller = ScreenshotController();
      final bytes = await controller.captureFromWidget(Material(child: widget));

      if (isShare) {
        String cachePath = await downloadMgr.getTmpCachePath("app_qr_code.jpg");
        File(cachePath).writeAsBytesSync(bytes);
        await Share.shareXFiles(
          [XFile(cachePath)],
          text: localized(
            invitationWithLink,
            params: [Config().appName, downloadLink.value],
          ),
        );
        return;
      }

      await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: 'image_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(imageSaved),
        icon: ImBottomNotifType.qrSaved,
      );
    } else {
      if (rationale || status.isPermanentlyDenied) {
        openAppSettings();
      } else {
        await permission.request();
      }
    }
  }
}
