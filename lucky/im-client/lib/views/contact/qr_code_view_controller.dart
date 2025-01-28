import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/user_mgr.dart';
import 'package:jxim_client/object/add_friend_request_model.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/contact/qr_code_scanner_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class QRCodeViewController extends GetxController with WidgetsBindingObserver {
  User user = Get.arguments?["user"] ?? User();

  RxString nameCardData = ''.obs;
  RxString qrCodeData = ''.obs;
  String secretUrl = '';
  RxBool isShowNameCard = false.obs;
  RxBool isValidQrCode = false.obs;
  RxString durationText = '00:00'.obs;
  Timer? timer;

  QRCodeViewController();

  QRCodeViewController.create(User user) {
    this.user = user;
  }

  @override
  void onInit() {
    super.onInit();
    objectMgr.userMgr.on(UserMgr.eventFriendSecret, _onUpdateDuration);
    isShowNameCard.value = objectMgr.localStorageMgr.read(LocalStorageMgr.SHOW_NAME_CARD) ?? false;
    switchQrCode(isInitLoad: true);
  }

  @override
  void onClose() {
    objectMgr.userMgr.off(UserMgr.eventFriendSecret, _onUpdateDuration);
    timer?.cancel();
    super.onClose();
  }

  void _onUpdateDuration(Object? sender, Object? type, Object? data) async {
    if (data == null) return;
    final result = QRSocketModel.fromJson(data as Map<String, dynamic>);
    if (result.userId == objectMgr.userMgr.mainUser.uid){
      isValidQrCode.value = false;
      generateQrData(qrSocketModel: result);
    }
  }

  Future<void> downloadQR(Widget widget) async {
    if (objectMgr.loginMgr.isDesktop) {
      ImBottomToast(Routes.navigatorKey.currentContext!,
          title: localized(imageDownloading), icon: ImBottomNotifType.loading);
      final controller = ScreenshotController();
      final bytes = await controller.captureFromWidget(Material(child: widget));
      desktopDownloadMgr.desktopSaveTo(
          'MY-HeyTalk-QR.jpg', bytes, Routes.navigatorKey.currentContext!);
      ImBottomToast(Routes.navigatorKey.currentContext!,
          title: localized(imageSaved), icon: ImBottomNotifType.saved);
    } else {
      getNameCardFile(widget);
    }
  }

  getNameCardFile(Widget widget, {bool isShare = false}) async {
    final Permission permission = defaultTargetPlatform == TargetPlatform.iOS
        ? await Permission.photos
        : await Permission.storage;
    final PermissionStatus status = await permission.status;
    final bool rationale = await permission.shouldShowRequestRationale;
    if (status.isGranted) {
      ImBottomToast(Routes.navigatorKey.currentContext!,
          title: localized(imageDownloading),
          icon: ImBottomNotifType.loading);

      final controller = ScreenshotController();
      final bytes =
          await controller.captureFromWidget(Material(child: widget));

      String cachePath = await downloadMgr.getTmpCachePath("${objectMgr.userMgr.mainUser.uid}_namecard.jpg", sub: "namecard");
      File(cachePath).writeAsBytesSync(bytes);
      if (!isShare) {
        ImageGallerySaver.saveImage(bytes,
            quality: 100,
            name: 'image_${DateTime.now().microsecondsSinceEpoch}.png');
        ImBottomToast(Routes.navigatorKey.currentContext!,
            title: localized(imageSaved), icon: ImBottomNotifType.saved);
      }
      return cachePath;
    } else {
      if (rationale || status.isPermanentlyDenied)
        openAppSettings();
      else {
        await permission.request();
      }
    }
  }

  Future<void> routeToScanner() async {
    if (Get.isRegistered<QRCodeScannerController>()) {
      if (Get.isRegistered<ChatInfoController>()) {
        Get.until((route) => Get.currentRoute == RouteName.qrCodeScanner);
      } else {
        final controller = Get.find<QRCodeScannerController>();
        if (controller.mobileScannerController != null && !controller.mobileScannerController!.isStarting)
          controller.mobileScannerController?.start();
        Get.back();
      }
    } else {
      final PermissionStatus status = await Permission.camera.status;
      if (status.isGranted) {
        Get.toNamed(RouteName.qrCodeScanner);
      } else {
        final bool rationale =
            await Permission.camera.shouldShowRequestRationale;
        if (rationale || status.isPermanentlyDenied)
          openSettingPopup(Permissions().getPermissionName(Permission.camera));
        else {
          final PermissionStatus status = await Permission.camera.request();
          if (status.isGranted) Get.toNamed(RouteName.qrCodeScanner);
          if (status.isPermanentlyDenied) openSettingPopup(Permissions().getPermissionName(Permission.camera));
        }
      }
    }
  }

  Future<void> generateNameCardData() async {
    Map<String, dynamic> data = {};
    data['profile'] = user.accountId;
    nameCardData.value = jsonEncode(data);
  }

  Future<void> generateQrData({int? duration, QRSocketModel? qrSocketModel}) async {
    /// 1.Default set duration is 0
    /// 2.如果 duration != 0, 重新设置call API设置新的duration
    /// 3.如果 qrSocketModel ！= null,是由socket返回data
    if (!isValidQrCode.value) {
      int time = duration ?? QRCodeDurationType.defaultSet.value;
      secretUrl = await getSecretUrl(duration:time, qrSocketModel: qrSocketModel);
    }
    Map<String, dynamic> data = {};
    data['profile'] = user.accountId;
    data['secretUrl'] = secretUrl;
    qrCodeData.value = jsonEncode(data);
  }

  Future<String> getSecretUrl({int duration = 0, QRSocketModel? qrSocketModel}) async {
    int countdownDuration = 0;
    int expiryTime = 0;
    String? url = "";

    if (qrSocketModel != null){
      expiryTime = qrSocketModel.expiry ?? 0;
      url = qrSocketModel.secret;
    } else {
      GetFriendRequestModel addFriendRequestModel = await getFriendSecret(duration);
      expiryTime = addFriendRequestModel.expiry ?? 0;
      url = addFriendRequestModel.url;
    }

    countdownDuration = expiryTime - (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    isValidQrCode.value = true;

    if (duration != QRCodeDurationType.forever.value && (countdownDuration > 0)) {
      startTimer(countdownDuration);
    } else {
      startTimer(-1);
    }

    return url ?? "";
  }

  Future<void> switchQrCode({isInitLoad = false}) async {
    if (!isInitLoad) {
      isShowNameCard.value = !isShowNameCard.value;
    }
    objectMgr.localStorageMgr
        .write(LocalStorageMgr.SHOW_NAME_CARD, isShowNameCard.value);

    if (isShowNameCard.value) {
      if (nameCardData.value == '') {
        generateNameCardData();
      }
    } else {
      generateQrData();
    }
  }

  void setDuration(int duration) {
    isValidQrCode.value = false;
    objectMgr.localStorageMgr.write(LocalStorageMgr.QR_CODE_DURATION, duration);
    objectMgr.localStorageMgr.write(LocalStorageMgr.QR_CODE_TIME, null);
    objectMgr.localStorageMgr.write(LocalStorageMgr.QR_CODE_SECRET_URL, null);
    generateQrData(duration: duration);
  }

  void startTimer(int duration) {
    if (timer != null) {
      timer?.cancel();
    }

    if (duration == -1) {
      durationText.value = '';
    } else {
      int min = duration ~/ 60;
      int second = duration % 60;
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (min == 0 && second == 0) {
          timer.cancel();
          isValidQrCode.value = false;
        } else if (second == 0) {
          min--;
          second = 59;
        } else {
          second--;
        }
        durationText.value =
            '${(min.toString().length == 1) ? '0$min' : '$min'}:${(second.toString().length == 1) ? '0$second' : '$second'}';
      });
    }
  }

  void showDurationOptionPopup(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          actions: [
            Container(
              color: Colors.white,
              child: CupertinoActionSheetAction(
                onPressed: () {
                  setDuration(QRCodeDurationType.oneMin.value);
                  Navigator.pop(context);
                },
                child: Text(
                  '60 ${localized(seconds)}',
                  style: jxTextStyle.textStyle16(color: accentColor),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              child: CupertinoActionSheetAction(
                onPressed: () {
                  setDuration(QRCodeDurationType.fiveMin.value);
                  Navigator.pop(context);
                },
                child: Text(
                  '5 ${localized(minutes)}',
                  style: jxTextStyle.textStyle16(color: accentColor),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              child: CupertinoActionSheetAction(
                onPressed: () {
                  setDuration(QRCodeDurationType.sixtyMin.value);
                  Navigator.pop(context);
                },
                child: Text(
                  '60 ${localized(minutes)}',
                  style: jxTextStyle.textStyle16(color: accentColor),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              child: CupertinoActionSheetAction(
                onPressed: () {
                  setDuration(QRCodeDurationType.forever.value);
                  Navigator.pop(context);
                },
                child: Text(
                  localized(forever),
                  style: jxTextStyle.textStyle16(color: accentColor),
                ),
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localized(buttonCancel),
              style: jxTextStyle.textStyle16(color: accentColor),
            ),
          ),
        );
      },
    );
  }

  Future<void> shareContact(Widget widget) async {
    String filePath = await getNameCardFile(widget, isShare: true);
    if (File(filePath).existsSync()) {
      await Share.shareXFiles([XFile(filePath)]);
    }
  }
}
