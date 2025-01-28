import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../utils/color.dart';
import '../../../utils/loading/ball.dart';
import '../../../utils/loading/ball_circle_loading.dart';
import '../../../utils/loading/ball_style.dart';
import '../../../utils/toast.dart';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:jxim_client/utils/permissions.dart';
import '../../../utils/utility.dart';

class QRScannerController extends GetxController {
  MobileScannerController mobileScannerController = MobileScannerController();
  String uuid = "";
  RxBool isScannable = true.obs;
  RxBool torchOn = false.obs;

  onInit() async {
    super.onInit();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  dispose() {
    super.dispose();
    mobileScannerController.dispose();
  }

  void scanQR(String? result) async {
    if (result != null) {
      await mobileScannerController.stop();
      Get.back(result: result);
    }
  }

  void toggleTorch() {
    mobileScannerController.toggleTorch();
    torchOn.value = !torchOn.value;
  }

  getImage(BuildContext context) async {
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) {
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
      },
    );
    if (torchOn.value) {
      toggleTorch();
    }
    if (Platform.isAndroid) {
      var storagePermission =
          await Permissions.request([Permission.storage], context: context);
      if (!storagePermission) {
        return;
      }
      var mediaPermission = await Permissions.request(
          [Permission.accessMediaLocation],
          context: context);
      if (!mediaPermission) {
        return;
      }
    } else {
      var photosPermission =
          await Permissions.request([Permission.photos], context: context);
      if (!photosPermission) {
        return;
      }
    }

    final XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    overlayState.insert(overlayEntry);

    if (pickedFile != null) {
      final result = await decodeQRCode(pickedFile.path);
      overlayEntry.remove();
      if (result != null) {
        //Todo
        scanQR(result);
      } else
        Toast.showToast(localized(scanInvalidQRCode));
    } else {
      overlayEntry.remove();
    }
  }
}
