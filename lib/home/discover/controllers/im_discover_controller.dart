import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/moment_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/contact/qr_code_view_controller.dart';

class IMDiscoverController extends GetxController {
  final showReel = false.obs;
  RxInt showMomentStrongNotification = 0.obs;
  Rx<MomentNotificationLastInfo?> notificationLastInfo =
      Rx<MomentNotificationLastInfo?>(null);

  @override
  onInit() {
    super.onInit();
    objectMgr.momentMgr.on(
      MomentMgr.MOMENT_NOTIFICATION_UPDATE,
      _onMomentNotificationUpdate,
    );

    initMomentNotification();
    updateExperiment();
  }

  @override
  void onClose() {
    objectMgr.momentMgr.off(
      MomentMgr.MOMENT_NOTIFICATION_UPDATE,
      _onMomentNotificationUpdate,
    );

    super.onClose();
  }

  //当网络恢复/app重新激活时，获取所有好友以及好友列表信息
  Future<void> reloadData() async {
    if (Get.isRegistered<IMDiscoverController>()) {
      Get.find<IMDiscoverController>().getPrivacy();
    }
  }

  getPrivacy() async {
    final res = await SettingServices().getPrivacySetting();
    await objectMgr.localStorageMgr.write('show_reel', res['show_reel']);
    await objectMgr.localStorageMgr.write('show_wallet', res['show_wallet']);
    updateExperiment();
  }

  updateExperiment() {
    int shouldShowReel = objectMgr.localStorageMgr.read('show_reel') ?? 0;
    showReel.value = shouldShowReel == 1;
  }

  Future<void> onSettingOptionTap(BuildContext context, String? type) async {
    switch (type) {
      case 'channel':
        Get.toNamed(RouteName.reel);
        break;
      case 'moment':
        Get.toNamed(RouteName.moment);
        break;
      case 'scan':
        if (objectMgr.callMgr.getCurrentState() == CallState.Idle) {
          QRCodeViewController.routeToScannerStatic();
        } else {
          Toast.showToast(localized(toastEndCallFirst));
        }
        break;
      default:
    }
  }

  void initMomentNotification() {
    notificationLastInfo.value = objectMgr.momentMgr.notificationLastInfo;
    showMomentStrongNotification.value =
        objectMgr.momentMgr.notificationStrongCount;
  }

  void _onMomentNotificationUpdate(_, __, ___) {
    Future.delayed(Duration.zero, () {
      notificationLastInfo.value = objectMgr.momentMgr.notificationLastInfo;
      showMomentStrongNotification.value =
          objectMgr.momentMgr.notificationStrongCount;
    });
  }
}
