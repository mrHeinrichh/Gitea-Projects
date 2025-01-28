import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';

import '../../object/user.dart';
import '../../utils/color.dart';
import '../../utils/loading/ball.dart';
import '../../utils/loading/ball_circle_loading.dart';
import '../../utils/loading/ball_style.dart';
import '../../utils/toast.dart';

class QRCodeWithoutScanButtonViewController extends GetxController {
  User user = Get.arguments["user"];
  String qrData = '';

  @override
  void onInit() {
    super.onInit();
    qrData = jsonEncode({"profile": user.accountId});
  }

  void downloadQR(Widget widget, BuildContext context) async {
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(builder: (context) {
      return Container(
        color: Colors.grey.withOpacity(0.3),
        height: MediaQuery.of(context).size.height,
        child: SizedBox(
          width: 50,
          height: 50,
          child: BallCircleLoading(
            radius: 25,
            ballStyle: BallStyle(
              size: 10,
              color: accentColor,
              ballType: BallType.solid,
              borderWidth: 1,
              borderColor: accentColor,
            ),
          ),
        ),
      );
    });
    await permissionHandling(overlayState, overlayEntry, widget);
    overlayEntry.remove();
  }

  Future<void> permissionHandling(OverlayState overlayState,
      OverlayEntry overlayEntry, Widget widget) async {
    final Permission permission = defaultTargetPlatform == TargetPlatform.iOS
        ? await Permission.photos
        : await Permission.storage;

    final PermissionStatus status = await permission.status;
    final bool rationale = await permission.shouldShowRequestRationale;
    if (status.isGranted) {
      overlayState.insert(overlayEntry);
      final controller = ScreenshotController();
      final bytes = await controller.captureFromWidget(Material(child: widget));
      await ImageGallerySaver.saveImage(bytes,
          quality: 100,
          name: 'image_${DateTime.now().microsecondsSinceEpoch}.png');
      Toast.showToast(localized(addressImageDownloaded));
    } else {
      if (rationale || status.isPermanentlyDenied)
        openAppSettings();
      else {
        await permission.request();
      }
    }
  }
}
