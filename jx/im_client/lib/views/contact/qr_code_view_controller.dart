import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/friends.dart';
import 'package:jxim_client/im/chat_info/chat_info_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/local_storage_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/user_mgr.dart';
import 'package:jxim_client/object/add_friend_request_model.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/share_link_util.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/contact/qr_code_scanner_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';

class QRCodeViewController extends GetxController {
  User user = Get.arguments?["user"] ?? User();

  RxString nameCardData = ''.obs;
  RxString qrCodeData = ''.obs;
  String secretUrl = '';
  RxBool isShowNameCard = true.obs;
  RxBool isValidQrCode = false.obs;
  RxString durationText = '00:00'.obs;
  Timer? timer;
  bool isGenerating = false;

  QRCodeViewController();

  QRCodeViewController.create(this.user);

  @override
  void onInit() {
    super.onInit();
    objectMgr.userMgr.on(UserMgr.eventFriendSecret, _onUpdateDuration);
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
    if (result.userId == objectMgr.userMgr.mainUser.uid) {
      isValidQrCode.value = false;
      generateQrData(qrSocketModel: result);
    }
  }

  Future<void> downloadQR(Widget widget, int uid,
      {bool isShare = false}) async {
    if (objectMgr.loginMgr.isDesktop) {
      final controller = ScreenshotController();
      final bytes = await controller.captureFromWidget(Material(child: widget));
      desktopDownloadMgr.desktopSaveTo(
        'MY-HeyTalk-QR.jpg',
        bytes,
        navigatorKey.currentContext!,
      );
      imBottomToast(
        navigatorKey.currentContext!,
        title: localized(imageSaved),
        icon: ImBottomNotifType.qrSaved,
      );
    } else {
      getNameCardFile(widget, uid, isShare: isShare);
    }
  }

  getNameCardFile(Widget widget, int uid, {bool isShare = false}) async {
    await saveImageWidgetToGallery(
        imageWidget: widget,
        cachePath: "${uid}_namecard.jpg",
        subDir: "namecard",
        isShare: isShare);
  }

  Future<void> routeToScanner() async {
    if (Get.isRegistered<QRCodeScannerController>()) {
      if (Get.isRegistered<ChatInfoController>()) {
        Get.until((route) => Get.currentRoute == RouteName.qrCodeScanner);
      } else {
        final controller = Get.find<QRCodeScannerController>();
        if (controller.mobileScannerController != null &&
            !controller.mobileScannerController!.isStarting) {
          controller.mobileScannerController?.start();
        }
        Get.back();
      }
    } else {
      bool ps = await Permissions.request([Permission.camera]);
      if (!ps) return;
      Get.toNamed(RouteName.qrCodeScanner);
    }
  }

  static Future<void> routeToScannerStatic() async {
    if (Get.isRegistered<QRCodeScannerController>()) {
      if (Get.isRegistered<ChatInfoController>()) {
        Get.until((route) => Get.currentRoute == RouteName.qrCodeScanner);
      } else {
        final controller = Get.find<QRCodeScannerController>();
        if (controller.mobileScannerController != null &&
            !controller.mobileScannerController!.isStarting) {
          controller.mobileScannerController?.start();
        }
        Get.back();
      }
    } else {
      bool ps = await Permissions.request([Permission.camera]);
      if (!ps) return;
      Get.toNamed(RouteName.qrCodeScanner);
    }
  }

  Future<void> generateNameCardData() async {
    String link = ShareLinkUtil.generateFriendShareLink(user.uid,
        accountId: user.accountId);
    nameCardData.value = link;
  }

  Future<void> generateQrData({
    int? duration,
    QRSocketModel? qrSocketModel,
  }) async {
    /// 1.Default set duration is 0
    /// 2.如果 duration != 0, 重新设置call API设置新的duration
    /// 3.如果 qrSocketModel ！= null,是由socket返回data
    if (user.accountId.isEmpty) {
      user = await objectMgr.userMgr.loadUser();
    }
    if (!isValidQrCode.value) {
      int time = duration ?? QRCodeDurationType.defaultSet.value;
      secretUrl =
          await getSecretUrl(duration: time, qrSocketModel: qrSocketModel);
    }

    Map<String, dynamic> data = {};
    data['profile'] = user.accountId;
    data['secretUrl'] = secretUrl;
    qrCodeData.value = jsonEncode(data);
  }

  shareQRToAnotherApp(widget, int uid) async {
    if (!isGenerating) {
      isGenerating = true;
      await saveImageWidgetToGallery(
          imageWidget: widget,
          cachePath: "${uid}_namecard.jpg",
          subDir: "namecard",
          isShare: true);
      objectMgr.chatMgr.handleShareData();
      isGenerating = false;
    }
  }

  Future<String> getSecretUrl({
    int duration = 0,
    QRSocketModel? qrSocketModel,
  }) async {
    int countdownDuration = 0;
    int expiryTime = 0;
    String? url = "";

    if (qrSocketModel != null) {
      expiryTime = qrSocketModel.expiry ?? 0;
      url = qrSocketModel.secret;
    } else {
      GetFriendRequestModel addFriendRequestModel =
          await getFriendSecret(duration);
      expiryTime = addFriendRequestModel.expiry ?? 0;
      url = addFriendRequestModel.url;
    }

    countdownDuration =
        expiryTime - (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    isValidQrCode.value = true;

    if (duration != QRCodeDurationType.forever.value &&
        (countdownDuration > 0)) {
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

    if (isShowNameCard.value) {
      if (nameCardData.value == '') {
        generateNameCardData();
      }
    } else {
      generateQrData();
    }
  }

  void setDuration(int duration) async {
    timer?.cancel();
    isValidQrCode.value = false;
    objectMgr.localStorageMgr.write(LocalStorageMgr.QR_CODE_DURATION, duration);
    objectMgr.localStorageMgr.write(LocalStorageMgr.QR_CODE_TIME, null);
    objectMgr.localStorageMgr.write(LocalStorageMgr.QR_CODE_SECRET_URL, null);
    await generateQrData(duration: duration);
  }

  void startTimer(int duration) {
    timer?.cancel();

    int min = duration ~/ 60;
    int second = duration % 60;

    durationText.value =
        '${min.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';

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
            '${min.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
      });
    }
  }

  void showDurationOptionPopup(BuildContext context) {
    showCustomBottomAlertDialog(context, withHeader: false, items: [
      buildAlertItem(
        onClick: () {
          setDuration(QRCodeDurationType.oneMin.value);
          Navigator.pop(context);
        },
        text: '60 ${localized(seconds)}',
      ),
      buildAlertItem(
        onClick: () {
          setDuration(QRCodeDurationType.fiveMin.value);
          Navigator.pop(context);
        },
        text: '5 ${localized(minutes)}',
      ),
      buildAlertItem(
        onClick: () {
          setDuration(QRCodeDurationType.sixtyMin.value);
          Navigator.pop(context);
        },
        text: '60 ${localized(minutes)}',
      ),
      buildAlertItem(
        onClick: () {
          setDuration(QRCodeDurationType.forever.value);
          Navigator.pop(context);
        },
        text: localized(forever),
      ),
    ]);
  }

  Widget buildAlertItem({
    required String text,
    required VoidCallback onClick,
  }) {
    return GestureDetector(
      onTap: onClick,
      behavior: HitTestBehavior.translucent,
      child: OverlayEffect(
        child: Container(
          height: 56,
          width: double.infinity,
          alignment: Alignment.center,
          child: Text(
            text,
            style: jxTextStyle.textStyle20(color: themeColor),
          ),
        ),
      ),
    );
  }

  Future<void> shareContact(Widget widget) async {
    await saveImageWidgetToGallery(
        imageWidget: widget,
        cachePath: "${user.uid}_namecard.jpg",
        subDir: "namecard",
        isShare: true);
  }
}
