import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/api/setting_services.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/custom_scrollable_list_view.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/privacy_security_controller.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class PrivacySecurityView extends GetView<PrivacySecurityController> {
  const PrivacySecurityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: objectMgr.loginMgr.isDesktop
          ? null
          : PrimaryAppBar(
              title: localized(privacySecurity),
            ),
      body: Column(
        children: [
          if (objectMgr.loginMgr.isDesktop)
            Container(
              height: 52,
              padding: const EdgeInsets.only(left: 10),
              decoration: const BoxDecoration(
                color: colorBackground,
                border: Border(
                  bottom: BorderSide(
                    color: colorBorder,
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
                              color: themeColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              localized(buttonBack),
                              style: TextStyle(
                                fontSize: 13,
                                color: themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    localized(notifSound),
                    style: const TextStyle(
                      fontSize: 16,
                      color: colorTextPrimary,
                    ),
                  ),
                  const SizedBox(),
                ],
              ),
            ),
          Expanded(
            child: CustomScrollableListView(
                children: [

                  /// Security Settings
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(localized(psSecuritySettings)),
                      Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            objectMgr.loginMgr.isDesktop ? 8 : 8.w,
                          ),
                        ),
                        child: Column(
                          children: [
                            SettingItem(
                              onTap: () => Toast.showToast(
                                localized(homeToBeContinue),
                              ),
                              title: localized(psChatPasscode),
                              rightTitle: localized(plOff),
                            ),
                            SettingItem(
                              onTap: () => Toast.showToast(
                                localized(homeToBeContinue),
                              ),
                              title: '2FA',
                              rightTitle: localized(plOff),
                              withBorder: true,
                            ),
                            SettingItem(
                              onTap: () => controller.navigateToEncryptionSetupPage(),
                              title: localized(managePrivateKeyTitle),
                              // rightTitle: localized(plOff),
                              withBorder: false
                            ),
                            // SettingItem(
                            //   onTap: () => controller.navigateToFriendVerifyPage(),
                            //   title: '好友辅助验证',
                            //   // rightTitle: localized(plOff),
                            //   withBorder: false,
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  /// Payment Security Settings
                  if (isWalletEnable())
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(localized(paymentSecuritySetting)),
                        Container(
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              objectMgr.loginMgr.isDesktop ? 8 : 8.w,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (isWalletEnable())
                                Obx(
                                  () => SettingItem(
                                    onTap: () => controller.handleView(),
                                    title: localized(paymentPassword),
                                    rightTitle: controller
                                        .passcodeStatus.value.toTitle,
                                    rightTitleFlex: 0,
                                  ),
                                ),
                              Obx(
                                () => SettingItem(
                                  onTap: () {
                                    controller.goToPaymentTwoFactorAuthView();
                                  },
                                  title: localized(paymentTwoFactorAuth),
                                  rightTitle: controller
                                          .isPayTwoFactorAuthEnable.value
                                      ? localized(plOn)
                                      : localized(plOff),
                                ),
                              ),
                              SettingItem(
                                onTap: () {
                                  Get.toNamed(
                                    RouteName.limitSecondaryAuthView,
                                  );
                                },
                                title: localized(limitSecondaryAuth),
                              ),
                              Obx(
                                () => SettingItem(
                                  onTap: () {
                                    controller.goToAuthMethodView();
                                  },
                                  title: localized(authenticationMethod),
                                  rightTitle: controller.getAuthType(),
                                  withBorder: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  /// 添加moment 可见时长选项
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildTitle(localized(momentPrivacyTitle)),
                      Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: objectMgr.loginMgr.isDesktop
                              ? BorderRadius.circular(8)
                              : BorderRadius.circular(8).w,
                        ),
                        child: Obx(
                          () => SettingItem(
                            onTap: () {
                              Get.toNamed(
                                RouteName.momentAvailableDaysSetting,
                              );
                            },
                            title: localized(momentPrivacyAvailableDaysTitle),
                            rightTitle: controller
                                .momentSelectionOptionModelList[
                                    controller.momentSelectionIdx.value]
                                .title!,
                            withBorder: false,
                          ),
                        ),
                      ),
                    ],
                  ),

                  /// Profile Privacy
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(localized(psProfilePrivacy)),
                      Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: objectMgr.loginMgr.isDesktop
                              ? BorderRadius.circular(8)
                              : BorderRadius.circular(8).w,
                        ),
                        child: Column(
                          children: [
                            Obx(
                              () => SettingItem(
                                onTap: () {
                                  controller
                                          .privacySecuritySettingPage.value =
                                      PrivacySecuritySettingPage.profilePic;
                                  if (objectMgr.loginMgr.isDesktop) {
                                    Get.toNamed(
                                      RouteName.privacySecuritySetting,
                                      id: 3,
                                    );
                                  } else {
                                    Get.toNamed(
                                      RouteName.privacySecuritySetting,
                                    );
                                  }
                                },
                                title: localized(psProfilePicture),
                                rightTitle: controller
                                    .profileSelectionOptionModelList[3 -
                                        controller
                                            .privacyProfilePic.value.code]
                                    .title!,
                              ),
                            ),
                            Obx(
                              () => SettingItem(
                                onTap: () {
                                  controller
                                          .privacySecuritySettingPage.value =
                                      PrivacySecuritySettingPage.phoneNum;
                                  if (objectMgr.loginMgr.isDesktop) {
                                    Get.toNamed(
                                      RouteName.privacySecuritySetting,
                                      id: 3,
                                    );
                                  } else {
                                    Get.toNamed(
                                      RouteName.privacySecuritySetting,
                                    );
                                  }
                                },
                                title: localized(psPhoneNumber),
                                rightTitle: controller
                                    .profileSelectionOptionModelList[3 -
                                        controller.privacyPhoneNum.value.code]
                                    .title!,
                              ),
                            ),
                            Obx(
                              () => SettingItem(
                                onTap: () {
                                  controller
                                          .privacySecuritySettingPage.value =
                                      PrivacySecuritySettingPage.username;
                                  if (objectMgr.loginMgr.isDesktop) {
                                    Get.toNamed(
                                      RouteName.privacySecuritySetting,
                                      id: 3,
                                    );
                                  } else {
                                    Get.toNamed(
                                      RouteName.privacySecuritySetting,
                                    );
                                  }
                                },
                                title: localized(psUsername),
                                rightTitle: controller
                                    .profileSelectionOptionModelList[3 -
                                        controller.privacyUsername.value.code]
                                    .title!,
                              ),
                            ),
                            Obx(
                              () => SettingItem(
                                onTap: () {
                                  controller
                                          .privacySecuritySettingPage.value =
                                      PrivacySecuritySettingPage.lastSeen;
                                  if (objectMgr.loginMgr.isDesktop) {
                                    Get.toNamed(
                                      RouteName.privacySecuritySetting,
                                      id: 3,
                                    );
                                  } else {
                                    Get.toNamed(
                                      RouteName.privacySecuritySetting,
                                    );
                                  }
                                },
                                title: localized(psLastSeen),
                                rightTitle: controller
                                    .profileSelectionOptionModelList[3 -
                                        controller.privacyLastSeen.value.code]
                                    .title!,
                                withBorder: true,
                              ),
                            ),
                            Obx(
                              () => SettingItem(
                                onTap: () {
                                  controller
                                          .privacySecuritySettingPage.value =
                                      PrivacySecuritySettingPage.emailAddress;
                                  if (objectMgr.loginMgr.isDesktop) {
                                    Get.toNamed(
                                      RouteName.privacySecuritySetting,
                                      id: 3,
                                    );
                                  } else {
                                    Get.toNamed(
                                      RouteName.privacySecuritySetting,
                                    );
                                  }
                                },
                                title: localized(emailAddress),
                                rightTitle: controller
                                    .profileSelectionOptionModelList[3 -
                                        controller
                                            .privacyEmailAddress.value.code]
                                    .title!,
                                withBorder: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  /// Friend Request Privacy
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(localized(psFriendRequestPrivacy)),
                      Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: objectMgr.loginMgr.isDesktop
                              ? BorderRadius.circular(8)
                              : BorderRadius.circular(8).w,
                        ),
                        child: Column(
                          children: [
                            Obx(
                              () => SettingItem(
                                onTap: () {
                                  controller
                                          .privacySecuritySettingPage.value =
                                      PrivacySecuritySettingPage
                                          .usernameSearch;
                                  if (objectMgr.loginMgr.isDesktop) {
                                    Get.toNamed(
                                      RouteName.privacySecuritySetting,
                                      id: 3,
                                    );
                                  } else {
                                    Get.toNamed(
                                      RouteName.privacySecuritySetting,
                                    );
                                  }
                                },
                                title: localized(psUsernameSearch),
                                rightTitle: controller
                                    .friendRequestSelectionOptionModelList[
                                        controller.privacySearchByUsername
                                                    .value.code ==
                                                Privacy.everybody.code
                                            ? 0
                                            : 1]
                                    .title!,
                              ),
                            ),
                            Obx(
                              () => SettingItem(
                                onTap: () {
                                  controller
                                          .privacySecuritySettingPage.value =
                                      PrivacySecuritySettingPage
                                          .phoneNumSearch;
                                  if (objectMgr.loginMgr.isDesktop) {
                                    Get.toNamed(
                                      RouteName.privacySecuritySetting,
                                      id: 3,
                                    );
                                  } else {
                                    Get.toNamed(
                                      RouteName.privacySecuritySetting,
                                    );
                                  }
                                },
                                title: localized(psPhoneNumberSearch),
                                rightTitle: controller
                                    .friendRequestSelectionOptionModelList[
                                        controller.privacySearchByPhoneNum
                                                    .value.code ==
                                                Privacy.everybody.code
                                            ? 0
                                            : 1]
                                    .title!,
                                rightTitleFlex: 0,
                                withBorder: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  /// block list
                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: colorWhite,
                      borderRadius: BorderRadius.circular(8).w,
                    ),
                    child: SettingItem(
                      onTap: () {
                        Get.toNamed(RouteName.blockList);
                      },
                      title: localized(blockList),
                      withBorder: false,
                    ),
                  ),

                  // /// Account Deletion
                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SettingItem(
                      withBorder: false,
                      onTap: () => Get.toNamed(RouteName.deleteAccountView),
                      title: localized(accountDeletion),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Container(
      margin: objectMgr.loginMgr.isDesktop
          ? const EdgeInsets.only(left: 16, bottom: 8)
          : const EdgeInsets.only(left: 16, bottom: 8).w,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: colorTextSecondary,
        ),
      ),
    );
  }
}
