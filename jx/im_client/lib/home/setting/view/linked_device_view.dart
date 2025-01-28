import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/home/setting/controller/linked_device_controller.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/connectivity_mgr.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/component/custom_cupertino_switch.dart';
import 'package:jxim_client/views/component/custom_tile.dart';
import 'package:jxim_client/views/component/seletion_bottom_sheet.dart';
import 'package:jxim_client/views_desktop/component/desktop_dialog.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LinkedDeviceView extends GetView<LinkedDeviceController> {
  const LinkedDeviceView({super.key});

  @override
  Widget build(BuildContext context) {
    final boxDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    );

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: objectMgr.loginMgr.isDesktop
          ? PrimaryAppBar(
              title: localized(deviceManagementTitle),
              onPressedBackBtn: () {
                Get.back(id: 3);
                Get.find<SettingController>().desktopSettingCurrentRoute = '';
                Get.find<SettingController>().selectedIndex.value = 101010;
              },
              trailing: controller.enableEditLogOut.value
                  ? [
                      CustomTextButton(
                        localized(buttonEdit),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        isDisabled: controller.isEdit.value,
                        onClick: () {
                          controller.isEdit(!controller.isEdit.value);
                        },
                      )
                    ]
                  : null,
            )
          : PrimaryAppBar(title: localized(deviceManagementTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16)
                  .copyWith(bottom: 24),
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
                              style: jxTextStyle.normalText(),
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
                                  localized(desktopVersion,
                                      params: [Config().appName]),
                                  style:
                                      jxTextStyle.normalText(color: themeColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: localized(linkWithDesktop),
                          isBold: true,
                          callBack: () {
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
                        ),
                      ]
                    ],
                  ),
                ),

                if (!objectMgr.loginMgr.isDesktop)
                  Visibility(
                    visible: Config().enableSingleDevice,
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      margin: const EdgeInsets.only(top: 24),
                      decoration: boxDecoration,
                      child: SettingItem(
                        title: localized(sameTypeDeviceLogin),
                        withBorder: false,
                        withArrow: false,
                        withEffect: false,
                        rightWidget: Obx(
                          () => CustomCupertinoSwitch(
                            value: controller.isSingleDevice.value == 0,
                            callBack: controller.updateSingleDevice,
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding:
                      const EdgeInsets.only(top: 4.0, left: 16, bottom: 24),
                  child: Text(
                    localized(onlySingleMobileSingleDesktop),
                    style: jxTextStyle.normalSmallText(
                      color: colorTextLevelTwo,
                    ),
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
                              clipBehavior: Clip.hardEdge,
                              decoration: boxDecoration,
                              child: CustomTile(
                                onTap: () => deviceDialog(
                                    controller.currentDeviceModel, context,
                                    isCurrent: true),
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
                      visible: controller.otherDeviceList.isNotEmpty,
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
                                children: [
                                  Column(
                                    children: [
                                      CustomTile(
                                        onTap: () => showLogoutDevicePopup(
                                            context,
                                            isLogoutAll: true),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 16),
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
                                                localized(logoutAllOtherDevice),
                                                style: jxTextStyle.headerText(
                                                  color: colorRed,
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                      separateDivider(indent: 56.0),
                                    ],
                                  ),
                                  ...List.generate(
                                      controller.otherDeviceList.length,
                                      (index) {
                                    final data =
                                        controller.otherDeviceList[index];

                                    Widget child = CustomTile(
                                      withBorder: (index !=
                                          controller.otherDeviceList.length -
                                              1),
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
                                                backgroundColor: colorRed,
                                                foregroundColor: colorWhite,
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
                                    return child;
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),

                _buildTitle(localized(autoTerminateSessions)),
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: boxDecoration,
                  child: CustomTile(
                    height: 44,
                    onTap: () {
                      showInactivePopup(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8.5),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 5,
                              child: Text(localized(ifInactiveFor),
                                  style: jxTextStyle.headerText())),
                          Obx(() {
                            return Expanded(
                              flex: 5,
                              child: Text(controller.inactivePeriod.value,
                                  style: jxTextStyle.headerText(
                                      color: colorTextSecondary),
                                  textAlign: TextAlign.end),
                            );
                          }),
                          const SizedBox(width: 2),
                          SvgPicture.asset(
                            'assets/svgs/right_arrow_thick.svg',
                            color: colorTextSupporting,
                            width: 16,
                            height: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12)
              ],
            ),
          ),
        ],
      ),
    );
  }

  deviceDialog(data, context, {bool isCurrent = false}) {
    controller.selectedDeviceModel?.value = data;
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
        barrierColor: colorOverlay40,
        backgroundColor: colorBackground,
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
                    style: jxTextStyle.titleText(),
                  ),
                  Text(
                    controller.getLastActiveStatus(data.lastActive),
                    style: jxTextStyle.headerText(color: colorTextSecondary),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: colorSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.only(top: 8, bottom: 8, left: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(localized(appVersion),
                                style: jxTextStyle.headerText()),
                            Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Text(
                                  "${controller.appName} ${data.appVersion ?? '-'}",
                                  style: jxTextStyle.headerText(
                                      color: colorTextSecondary)),
                            )
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: separateDivider(indent: 0.0),
                        ),
                        Visibility(
                          visible: Config().enableDeviceLink,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(localized(ipAddress),
                                  style: jxTextStyle.headerText()),
                              Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: Text(data.ip ?? "-",
                                    style: jxTextStyle.headerText(
                                        color: colorTextSecondary)),
                              )
                            ],
                          ),
                        ),
                        Visibility(
                          visible: Config().enableDeviceLink,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: separateDivider(indent: 0.0),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(localized(location),
                                style: jxTextStyle.headerText()),
                            Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Text(data.city ?? "-",
                                  style: jxTextStyle.headerText(
                                      color: colorTextSecondary)),
                            )
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
                      color: colorSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: CustomTile(
                      onTap: () => controller.switchDeviceCallNotification(
                          data, context),
                      // borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10.5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localized(receiveCallPermission),
                              style: jxTextStyle.headerText(),
                            ),
                            GetBuilder<LinkedDeviceController>(
                              id: data.udid.toString(),
                              builder: (logic) {
                                return CustomCupertinoSwitch(
                                  value: controller.selectedDeviceModel?.value
                                          ?.enableVoip ==
                                      1,
                                  callBack: (_) =>
                                      controller.switchDeviceCallNotification(
                                          data, context),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: !isCurrent,
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: colorSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      width: double.infinity,
                      child: CustomTile(
                        onTap: () {
                          Get.back();
                          showLogoutDevicePopup(context, udid: data.udid);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Text(localized(logoutThisDevice),
                              style: jxTextStyle.headerText(
                                  fontWeight: MFontWeight.bold5.value,
                                  color: colorRed)),
                        ),
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
                  style: jxTextStyle.headerText(
                      fontWeight: MFontWeight.bold5.value)),
              Text('${controller.appName} $appVersion',
                style: jxTextStyle.normalSmallText(
                      color: objectMgr.loginMgr.isDesktop
                          ? colorTextPrimary.withOpacity(0.54)
                          : null)),
              Text(
                '$country · $time',
                style: jxTextStyle.normalSmallText(color: colorTextSecondary),
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
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    decoration: BoxDecoration(
                        color: colorBackground6,
                        borderRadius: BorderRadius.circular(30)),
                    child: const Center(
                      child: Text(
                        'Logout',
                        style:
                            TextStyle(fontSize: 12, color: Color(0x99121212)),
                      ),
                    ),
                  ),
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
      child: Text(title,
          style: jxTextStyle.normalSmallText(
            color: colorTextLevelTwo,
          )),
    );
  }

  showLogoutDevicePopup(BuildContext context,
      {bool isLogoutAll = false, int udid = 0}) {
    if (!objectMgr.loginMgr.isDesktop) {
      showCustomBottomAlertDialog(
        context,
        subtitle: localized(
            isLogoutAll ? confirmLogoutAllDevices : confirmLogoutFromTheDevice),
        canPopConfirm: false,
        confirmText:
            localized(isLogoutAll ? logoutAllOtherDevice : mySettingLogout),
        onConfirmListener: () async {
          await controller.logoutDevice(context, isLogoutAll ? null : udid);
        },
      );
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return DesktopDialog(
                dialogSize: const Size(350, 100),
                child: DesktopDialogWithButton(
                  title: localized(isLogoutAll
                      ? confirmLogoutAllDevices
                      : confirmLogoutFromTheDevice),
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
      barrierColor: colorOverlay40,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SelectionBottomSheet(
          context: context,
          onTapCancel:
              objectMgr.loginMgr.isDesktop ? () => Get.back(id: 3) : null,
          selectionOptionModelList: controller.optionList,
          callback: (index) {
            controller.updateTerminateSessionTime(index);
          },
        );
      },
    );
  }
}
