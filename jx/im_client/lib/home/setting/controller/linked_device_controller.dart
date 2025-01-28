import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/account.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/managers/login_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/device_list_model.dart';
import 'package:jxim_client/object/selection_option_model.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:permission_handler/permission_handler.dart';

class LinkedDeviceController extends GetxController {
  DeviceModel? currentDeviceModel = DeviceModel();
  RxList<DeviceModel> deviceHistoryList = RxList();
  final otherDeviceList = [].obs;
  String appName = '';
  final inactivePeriod = localized(timeSixMonths).obs;
  final isEdit = false.obs;
  final isSingleDevice = 0.obs;
  final enableEditLogOut =  false.obs;

  Rxn<DeviceModel>? selectedDeviceModel = Rxn<DeviceModel>();

  final List<SelectionOptionModel> optionList = [
    SelectionOptionModel(
      title: localized(timeOneWeek),
    ),
    SelectionOptionModel(
      title: localized(timeOneMonth),
    ),
    SelectionOptionModel(
      title: localized(timeThreeMonths),
    ),
    SelectionOptionModel(
      title: localized(timeSixMonths),
    ),
  ];

  @override
  Future<void> onInit() async {
    super.onInit();
    await getAppName();
    await getDeviceList();
    objectMgr.loginMgr.on(LoginMgr.eventLinkDevice, _onGetLinkDeviceInfo);
    getSettingService();
  }

  getSettingService() async {
    isSingleDevice.value =
        objectMgr.localStorageMgr.read("only_allowed_single_device") ?? 0;

    var response = await SettingServices().getPrivacySetting();
    int dayOfSession = response["other_device_inactivity_period"];
    switch (dayOfSession) {
      case 7:
        inactivePeriod(localized(timeOneWeek));
        break;
      case 30:
        inactivePeriod(localized(timeOneMonth));
        break;
      case 90:
        inactivePeriod(localized(timeThreeMonths));
        break;
      case 180:
        inactivePeriod(localized(timeSixMonths));
        break;
    }
    objectMgr.localStorageMgr.write("device_inactivity_period", dayOfSession);

    isSingleDevice.value = response["only_allowed_single_device"];
    objectMgr.localStorageMgr
        .write("only_allowed_single_device", isSingleDevice.value);
  }

  @override
  void onClose() {
    objectMgr.loginMgr.off(LoginMgr.eventLinkDevice, _onGetLinkDeviceInfo);
    super.onClose();
  }

  Future<void> getAppName() async {
    appName = await PlatformUtils.getAppName();
  }

  Future<void> getDeviceList() async {
    final res = await deviceList();

    if (res['current_device'] != null) {
      currentDeviceModel = DeviceModel.fromJson(res['current_device']);
      update();
    }

    otherDeviceList.clear();
    if (res['other_devices'] != null) {
      final tempList = res['other_devices']
          .map((json) => DeviceModel.fromJson(json))
          .toList();
      otherDeviceList.addAll(tempList);
      for (var p0 in otherDeviceList) {
        if (p0.udid == selectedDeviceModel?.value?.udid) {
          selectedDeviceModel?.value = p0;
          update([p0.udid.toString()]);
        }
      }
      if (currentDeviceModel!.udid == selectedDeviceModel?.value?.udid) {
        selectedDeviceModel?.value = currentDeviceModel;
        update([currentDeviceModel!.udid.toString()]);
      }
    }
  }

  Future<void> getDeviceHistory() async {
    final data = await deviceHistory();
    deviceHistoryList.value = data.deviceHistoryList!;
  }

  String getLastActiveStatus(int? lastActive) {
    return FormatTime.formatTimeFun(lastActive);
  }

  Future<void> linkWithDesktop() async {
    FocusManager.instance.primaryFocus?.unfocus();
    bool ps = await Permissions.request([Permission.camera]);
    if (!ps) return;
    Get.toNamed(RouteName.qrCodeScanner);
  }

  Future<String> logoutDevice(BuildContext context, int? udid) async {
    String message = localized(deviceLogoutUnsuccessfully);
    List<int>? deviceIdList = [];

    if (udid == null) {
      deviceIdList =
          otherDeviceList.map((element) => element.udid).cast<int>().toList();
    } else {
      deviceIdList.add(udid);
    }

    try {
      final data = await removeDevices(deviceIdList);
      if (data.success()) {
        objectMgr.loginMgr.event(
          objectMgr.loginMgr,
          LoginMgr.eventLinkDevice,
          data: true,
        );
        Toast.showToast(localized(deviceLogoutSuccessfully));
      }
    } on AppException catch (e) {
      message = e.getMessage();
    }
    return message;
  }

  void _onGetLinkDeviceInfo(Object sender, Object type, Object? data) async {
    if (data is bool) {
      if (data) {
        getDeviceList();
        // getDeviceHistory();
      }
    }
  }

  updateTerminateSessionTime(int index) async {
    int dayOfSession = 0;
    if (index == 0) {
      inactivePeriod(localized(timeOneWeek));
      dayOfSession = 7;
    } else if (index == 1) {
      inactivePeriod(localized(timeOneMonth));
      dayOfSession = 30;
    } else if (index == 2) {
      inactivePeriod(localized(timeThreeMonths));
      dayOfSession = 90;
    } else {
      inactivePeriod(localized(timeSixMonths));
      dayOfSession = 180;
    }
    final success = await SettingServices()
        .updatePrivacySetting("device_inactivity_period", dayOfSession);
    if (success) {
      objectMgr.localStorageMgr.write("device_inactivity_period", dayOfSession);
      Toast.showToast(localized(psPrivacySettingSuccess));
      if (objectMgr.loginMgr.isDesktop) Get.back(id: 3);
    } else {
      Toast.showToast(localized(psPrivacySettingFailed));
    }
  }

  void switchDeviceCallNotification(
      DeviceModel device, BuildContext context) async {
    int newStatus = device.enableVoip == 1 ? 0 : 1;
    final res = await updateVoipSession(
        device.udid as int, newStatus, device.platform == 'desktop');
    if (res.success()) {
      device.enableVoip = newStatus;
      update([device.udid.toString()]);
      if (device.udid == currentDeviceModel!.udid) {
        objectMgr.callMgr.voipEnabled = newStatus == 1 ? true : false;
      }
    } else {
      Toast.showToast(localized(editFailed));
    }
  }

  void updateSingleDevice(bool value) {
    if (value) {
      isSingleDevice.value = 0;
      setSingleDevice();
    } else {
      int? mobileCount =
          otherDeviceList.where((item) => item.platform == 'app').length;
      int? desktopCount =
          otherDeviceList.where((item) => item.platform == 'desktop').length;

      if (currentDeviceModel?.platform == 'app') {
        mobileCount += 1;
      } else if (currentDeviceModel?.platform == 'desktop') {
        desktopCount += 1;
      }

      if (mobileCount <= 1 && desktopCount <= 1) {
        isSingleDevice.value = 1;
        setSingleDevice();
      } else {
        showCustomBottomAlertDialog(
          Get.context!,
          subtitle: localized(multiDeviceLogin),
          confirmText: localized(turnOffMultiDeviceLogin),
          confirmTextColor: colorRed,
          cancelTextColor: themeColor,
          onConfirmListener: () {
            isSingleDevice.value = 1;
            setSingleDevice();
          },
        );
      }
    }
  }

  Future<void> setSingleDevice() async {
    final success = await SettingServices().updateSingleDevicePrivacy(
        "only_allowed_single_device", isSingleDevice.value);
    if (success) {
      objectMgr.localStorageMgr
          .write("only_allowed_single_device", isSingleDevice.value);
      getDeviceList();
    }
  }
}
