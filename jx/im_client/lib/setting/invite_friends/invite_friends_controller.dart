import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/install_info.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/paths/app_path.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class InviteFriendsController extends GetxController {
  final isValidityPeriod = false.obs;
  final validityPeriodInviteCode = ''.obs;
  int inviteCodeExpiry = 0;
  final isLoading = false.obs;
  final downloadLink = '${Config().officialUrl}downloads/'.obs;

  String get inviteCodeExpiryDay {
    int secondsInADay = 86400; // 1 天等于 86400 秒 (24 * 60 * 60)
    final day =
        (inviteCodeExpiry - DateTime.now().millisecondsSinceEpoch / 1000) /
            secondsInADay;
    return ((day > 0 && day < 1) ? 1 : day).toStringAsFixed(0);
  }

  @override
  void onInit() {
    super.onInit();
    getDownloadLink();
  }

  Future<void> getDownloadLink() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      InstallInfo installInfo = await getDownloadUrl();
      downloadLink.value = installInfo.url;
      if (downloadLink.value.startsWith("https://")) {
        downloadLink.value = downloadLink.value.replaceFirst("https://", "");
      }
      validityPeriodInviteCode.value = installInfo.inviteCode;
      inviteCodeExpiry = installInfo.inviteCodeExpiry;
    } on AppException catch (e) {
      Toast.showToast(e.getMessage());
    }
    isLoading.value = false;
  }

  Future<void> downloadAppQR(Widget widget, {bool isShare = false}) async {
    final controller = ScreenshotController();
    try {
      final bytes = await controller.captureFromWidget(widget);

      if (isShare) {
        // Save the image temporarily for sharing
        final appCacheRootPath = AppPath.appCacheRootPath;
        final String filePath = '$appCacheRootPath/mainland_invite_qr_code.jpg';
        File(filePath).writeAsBytesSync(bytes);

        // Share the file
        await Share.shareXFiles(
          [XFile(filePath)],
          text: localized(
            invitationWithLink,
            params: [Config().appName, downloadLink.value],
          ),
        );
        return;
      }

      if (kIsWeb) {
        throw UnimplementedError('Saving images on web is not supported yet.');
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Save the image to the gallery on mobile platforms
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
        // For desktop platforms: Save the image to the documents directory
        final appDocumentLangRootPath = AppPath.appDocumentLangRootPath;

        final String filePath =
            '$appDocumentLangRootPath/image_${DateTime.now().microsecondsSinceEpoch}.png';
        File(filePath).writeAsBytesSync(bytes);
        imBottomToast(
          navigatorKey.currentContext!,
          title: localized(imageSaved),
          icon: ImBottomNotifType.qrSaved,
        );
      }
    } catch (e) {
      Toast.showToast('Error: ${e.toString()}');
    }
  }

  void copyText({bool needVibrate = false}) {
    if (needVibrate) {
      vibrate();
    }
    copyToClipboard(validityPeriodInviteCode.value);
  }
}
