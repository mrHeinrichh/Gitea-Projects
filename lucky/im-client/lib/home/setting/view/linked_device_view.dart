import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/home/setting/controller/linked_device_controller.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../main.dart';
import '../../../managers/call_mgr.dart';
import '../../../views/component/click_effect_button.dart';
import '../../../views/component/custom_tile.dart';
import '../../../views/component/seletion_bottom_sheet.dart';
import '../../../views_desktop/component/DesktopDialog.dart';
import '../setting_controller.dart';

class LinkedDeviceView extends GetView<LinkedDeviceController> {
  const LinkedDeviceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: objectMgr.loginMgr.isDesktop
          ? null
          : PrimaryAppBar(
              title: localized(deviceManagementTitle),
            ),
      body: Column(
        children: [
          if (objectMgr.loginMgr.isDesktop)
            Container(
              height: 52,
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: const Border(
                  bottom: BorderSide(
                    color: JXColors.outlineColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                /// 普通界面
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  OpacityEffect(
                    child: GestureDetector(
                      onTap: () {
                        Get.back(id: 3);
                        Get.find<SettingController>()
                            .desktopSettingCurrentRoute = '';
                        Get.find<SettingController>().selectedIndex.value =
                            101010;
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/svgs/Back.svg',
                              width: 18,
                              height: 18,
                              color: JXColors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              localized(buttonBack),
                              style: const TextStyle(
                                fontSize: 13,
                                color: JXColors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    localized(deviceManagementTitle),
                    style: const TextStyle(
                      fontSize: 16,
                      color: JXColors.black,
                    ),
                  ),
                  Visibility(
                    visible: true,
                    child: OpacityEffect(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          controller.isEdit(!controller.isEdit.value);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            localized(buttonEdit),
                            style: jxTextStyle.textStyle15(color: accentColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                children: [
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/linkedDevicePicture.png',
                          width: 148,
                          height: 148,
                        ),
                        if (!objectMgr.loginMgr.isDesktop) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                localized(scanQRToLogIn),
                                style: jxTextStyle.textStyle14(),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () async {
                                  if (await canLaunchUrlString(
                                      "${Config().officialUrl}downloads/")) {
                                    await launchUrlString(
                                        "${Config().officialUrl}downloads/");
                                  }
                                },
                                child: OpacityEffect(
                                  child: Text(
                                    localized(desktopVersion,params: [Config().appName]),
                                    style: jxTextStyle.textStyle14(
                                        color: accentColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                backgroundColor: accentColor,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                splashFactory: NoSplash.splashFactory,
                                animationDuration:
                                    const Duration(milliseconds: 1),
                              ),
                              onPressed: () {
                                if (objectMgr.callMgr.getCurrentState() !=
                                    CallState.Idle) {
                                  Toast.showToast(
                                      localized(deviceLogoutSuccessfully));
                                  return;
                                }
                                if (connectivityMgr.connectivityResult ==
                                    ConnectivityResult.none) {
                                  Toast.showToast(localized(
                                      connectionFailedPleaseCheckTheNetwork));
                                  return;
                                }
                                controller.linkWithDesktop();
                              },
                              child: Text(
                                localized(linkWithDesktop),
                                style: jxTextStyle.textStyleBold16(
                                  color: JXColors.white,
                                  fontWeight:MFontWeight.bold6.value,
                                ).copyWith(height: 1.2),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),

                  /// Current Device Info
                  GetBuilder<LinkedDeviceController>(
                    init: controller,
                    builder: (_) {
                      return Visibility(
                        visible: (controller.currentDeviceModel?.udid != null),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTitle(localized(currentDevices)),
                              Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12)),
                                child: CustomTile(
                                  child: _deviceListItem(
                                    controller.currentDeviceModel?.deviceName ??
                                        '-',
                                    controller.currentDeviceModel?.appVersion ??
                                        '-',
                                    controller.currentDeviceModel?.city ?? '-',
                                    controller.getLastActiveStatus(controller
                                        .currentDeviceModel?.lastActive),
                                    controller.currentDeviceModel?.platform ==
                                        'app',
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => deviceDialog(
                                      controller.currentDeviceModel, context,
                                      isCurrent: true),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  /// Other Device Info
                  Obx(() => Visibility(
                        visible: controller.otherDeviceList.length > 0,
                        child: SlidableAutoCloseBehavior(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTitle(localized(otherDevices)),
                              Container(
                                clipBehavior: Clip.hardEdge,
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: List.generate(
                                      controller.otherDeviceList.length,
                                      (index) {
                                    final data =
                                        controller.otherDeviceList[index];

                                    Widget child = CustomTile(
                                      onTap: () => deviceDialog(data, context),
                                      child: _deviceListItem(
                                          data.deviceName ?? '-',
                                          data.appVersion ?? '-',
                                          data.city ?? '-',
                                          controller.getLastActiveStatus(
                                              data.lastActive),
                                          data?.platform == 'app',
                                          isShowLogout: true, onTap: () {
                                        showLogoutDevicePopup(context,
                                            udid: data.udid);
                                      }),
                                    );

                                    if (!objectMgr.loginMgr.isDesktop) {
                                      child = Slidable(
                                          endActionPane: ActionPane(
                                            motion: const DrawerMotion(),
                                            extentRatio: 0.2,
                                            children: [
                                              CustomSlidableAction(
                                                onPressed: (context) {
                                                  showLogoutDevicePopup(context,
                                                      udid: data.udid);
                                                },
                                                backgroundColor: JXColors.red,
                                                foregroundColor:
                                                    JXColors.cIconPrimaryColor,
                                                padding: EdgeInsets.zero,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    SvgPicture.asset(
                                                      'assets/svgs/close_round_icon.svg',
                                                      width: 20,
                                                      height: 20,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      localized(logoutText),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: jxTextStyle
                                                          .slidableTextStyle(),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                          child: child);
                                    }

                                    if (index ==
                                        controller.otherDeviceList.length - 1) {
                                      return Column(
                                        children: [
                                          child,
                                          SeparateDivider(indent: 56.0),
                                          CustomTile(
                                            onTap: () => showLogoutDevicePopup(
                                                context,
                                                isLogoutAll: true),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 16),
                                              child: Row(
                                                children: [
                                                  SvgPicture.asset(
                                                    'assets/svgs/delete_chat.svg',
                                                    width: 24,
                                                    height: 24,
                                                    color: Colors.red,
                                                  ),
                                                  const SizedBox(
                                                    width: 16,
                                                  ),
                                                  Text(
                                                    localized(
                                                        logoutAllOtherDevice),
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.red),
                                                  )
                                                ],
                                              ),
                                            ),
                                            borderRadius:
                                                const BorderRadius.only(
                                              bottomLeft: Radius.circular(12),
                                              bottomRight: Radius.circular(12),
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    return child;
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),

                  _buildTitle(localized(autoTerminateSessions)),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                    child: CustomTile(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8.5),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 5,
                                child: Text(localized(ifInactiveFor),
                                    style: jxTextStyle.textStyle16())),
                            Obx(() {
                              return Expanded(
                                flex: 5,
                                child: Text(controller.inactivePeriod.value,
                                    style: jxTextStyle.textStyle14(
                                        color: JXColors.secondaryTextBlack),
                                    textAlign: TextAlign.end),
                              );
                            }),
                            const SizedBox(width: 2),
                            SvgPicture.asset(
                              'assets/svgs/right_arrow_thick.svg',
                              color: JXColors.secondaryTextBlack,
                              width: 16,
                              height: 16,
                            ),
                          ],
                        ),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        showInactivePopup(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  deviceDialog(data, context, {bool isCurrent = false}) {
    controller.selectedDeviceModel?.value = data;
    showModalBottomSheet(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        backgroundColor: const Color(0xFFF6F6F6),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SvgPicture.asset(
                    data.platform == 'app'
                        ? 'assets/svgs/mobile_icon.svg'
                        : 'assets/svgs/desktop_icon.svg',
                    width: 60,
                    height: 60,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.deviceName,
                    style: jxTextStyle.textStyle24(),
                  ),
                  Text(
                    controller.getLastActiveStatus(data.lastActive),
                    style: jxTextStyle.textStyle14(
                        color: JXColors.secondaryTextBlack),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(localized(appVersion),
                                style: jxTextStyle.textStyle16()),
                            Text(
                                "${controller.appName} ${data.appVersion ?? '-'}",
                                style: jxTextStyle.textStyle14(
                                    color: JXColors.secondaryTextBlack))
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: SeparateDivider(indent: 0.0),
                        ),
                        Visibility(
                          visible: Config().enableDeviceLink,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(localized(ipAddress),
                                  style: jxTextStyle.textStyle16()),
                              Text(data.ip ?? "-",
                                  style: jxTextStyle.textStyle14(
                                      color: JXColors.secondaryTextBlack))
                            ],
                          ),
                        ),
                        Visibility(
                          visible: Config().enableDeviceLink,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: SeparateDivider(indent: 0.0),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(localized(location),
                                style: jxTextStyle.textStyle16()),
                            Text(data.city ?? "-",
                                style: jxTextStyle.textStyle14(
                                    color: JXColors.secondaryTextBlack))
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildTitle(localized(devicePermission)),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: CustomTile(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10.5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localized(receiveCallPermission),
                              style: jxTextStyle.textStyle16(),
                            ),
                            GetBuilder<LinkedDeviceController>(
                                id: data.udid.toString(),
                                builder: (logic) {
                                  return FlutterSwitch(
                                    value: controller.selectedDeviceModel?.value
                                            ?.enableVoip ==
                                        1,
                                    onToggle: (_) =>
                                        controller.switchDeviceCallNotification(
                                            data, context),
                                    activeColor: accentColor,
                                    width: 50.0,
                                    height: 24.0,
                                    toggleSize: 20,
                                  );
                                })
                          ],
                        ),
                      ),
                      onTap: () => controller.switchDeviceCallNotification(
                          data, context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Visibility(
                    visible: !isCurrent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      width: double.infinity,
                      child: CustomTile(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Text(localized(logoutThisDevice),
                              style: jxTextStyle.textStyleBold14(
                                  color: Colors.red)),
                        ),
                        onTap: () {
                          Get.back();
                          showLogoutDevicePopup(context, udid: data.udid);
                        },
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _deviceListItem(String name, String appVersion, String country,
      String time, bool isMobile,
      {bool isHistory = false, bool isShowLogout = false, Function()? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SvgPicture.asset(
            isMobile
                ? isHistory
                    ? 'assets/svgs/mobile_icon_history.svg'
                    : 'assets/svgs/mobile_icon.svg'
                : isHistory
                    ? 'assets/svgs/desktop_icon_history.svg'
                    : 'assets/svgs/desktop_icon.svg',
            width: 28,
            height: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style:
                      jxTextStyle.textStyleBold16(fontWeight:MFontWeight.bold6.value)),
              Text('${controller.appName} $appVersion',
                  style: jxTextStyle.textStyle14()),
              Text(
                '$country · $time',
                style:
                    jxTextStyle.textStyle14(color: JXColors.secondaryTextBlack),
              )
            ],
          ),
          const Spacer(),
          Obx(
            () => Visibility(
              visible: controller.isEdit.value && isShowLogout,
              child: OpacityEffect(
                child: GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 12),
                      decoration: BoxDecoration(
                          color: JXColors.outlineColor,
                          borderRadius: BorderRadius.circular(30)),
                      child: const Center(
                          child: Text(
                        'Logout',
                        style:
                            TextStyle(fontSize: 12, color: Color(0x99121212)),
                      ))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: JXColors.secondaryTextBlack,
        ),
      ),
    );
  }

  showLogoutDevicePopup(BuildContext context,
      {bool isLogoutAll = false, int udid = 0}) {
    if (!objectMgr.loginMgr.isDesktop) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return CustomConfirmationPopup(
            title:
                '${localized(isLogoutAll ? confirmLogoutAllDevices : confirmLogoutFromTheDevice)}',
            confirmButtonText:
                localized(isLogoutAll ? logoutAllOtherDevice : mySettingLogout),
            cancelButtonText: localized(buttonCancel),
            confirmCallback: () async {
              await controller.logoutDevice(context, isLogoutAll ? null : udid);
            },
            cancelCallback: () => Navigator.of(context).pop(),
          );
        },
      );
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return DesktopDialog(
                dialogSize: const Size(350, 100),
                child: DesktopDialogWithButton(
                  title:
                      '${localized(isLogoutAll ? confirmLogoutAllDevices : confirmLogoutFromTheDevice)}',
                  buttonLeftText: localized(cancel),
                  buttonLeftOnPress: () {
                    Get.back();
                  },
                  buttonRightText:
                      localized(isLogoutAll ? buttonConfirm : mySettingLogout),
                  buttonRightOnPress: () async {
                    await controller.logoutDevice(
                        context, isLogoutAll ? null : udid);
                    Get.back();
                  },
                ));
          });
    }
  }

  void showInactivePopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SelectionBottomSheet(
          context: context,
          selectionOptionModelList: controller.optionList,
          callback: (index) {
            controller.updateTerminateSessionTime(index);
          },
        );
      },
    );
  }
}
