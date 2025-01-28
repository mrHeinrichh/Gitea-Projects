import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';
import 'package:jxim_client/views/component/custom_cupertino_switch.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/auth_method/auth_method_controller.dart';

class AuthMethodView extends GetView<AuthMethodController> {
  const AuthMethodView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        leadingWidth: objectMgr.loginMgr.isDesktop ? 60 : null,
        title: localized(authenticationMethod),
        onPressedBackBtn:
            objectMgr.loginMgr.isDesktop ? () => Get.back(id: 3) : null,
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          top: 24.0,
          left: 16.0,
          right: 16.0,
          bottom: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(localized(authDescription),
                  style: jxTextStyle.normalSmallText(
                    color: colorTextLevelTwo,
                  )),
            ),

            /// phone auth setting
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColoredBox(
                color: Colors.white,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Column(
                        children: [
                          SettingItem(
                            paddingVerticalMobile: 9,
                            withEffect: false,
                            title: localized(authMobileVerification),
                            withArrow: false,
                            rightWidget: Obx(
                              () => CustomCupertinoSwitch(
                                value: controller.phoneNumAuthSwitch.value,
                                callBack: (bool value) {
                                  pdebug("Switch state changed to: $value");
                                  controller.setPhoneNumAuthSwitch(value);
                                },
                              ),
                            ),
                          ),
                          Obx(
                            () => SettingItem(
                              paddingVerticalMobile: 9,
                              onTap: () {
                                showCustomBottomAlertDialog(
                                  Get.context!,
                                  title: localized(areYouSureToChangeTheNumber),
                                  subtitle: localized(afterChangePhoneNumber),
                                  confirmText: localized(changeNewNumber),
                                  confirmTextColor: themeColor,
                                  cancelTextColor: themeColor,
                                  onConfirmListener: () {
                                    if (objectMgr.loginMgr.isDesktop) {
                                      Get.toNamed(
                                        RouteName.editPhoneNumber,
                                        id: 3,
                                      )?.then((value) {
                                        controller.refreshData();
                                        return true;
                                      });
                                    } else {
                                      Get.toNamed(
                                        RouteName.editPhoneNumber,
                                      )?.then((value) {
                                        controller.refreshData();
                                        return true;
                                      });
                                    }
                                  },
                                );
                              },
                              title: localized(authChangeNum),
                              rightTitle: controller.getPhoneStr,
                              rightTitleFontSize: 16,
                              withBorder: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            im.ImGap.vGap24,

            /// email auth setting
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColoredBox(
                color: Colors.white,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Column(
                        children: [
                          SettingItem(
                            paddingVerticalMobile: 9,
                            withEffect: false,
                            title: localized(authEmailVerification),
                            withArrow: false,
                            rightWidget: Obx(
                              () => CustomCupertinoSwitch(
                                value: controller.emailAuthSwitch.value,
                                callBack: (bool value) {
                                  pdebug("Switch state changed to: $value");
                                  controller.setEmailAuthSwitch(value);
                                },
                              ),
                            ),
                          ),
                          Obx(
                            () => SettingItem(
                              paddingVerticalMobile: 9,
                              onTap: () {
                                if (objectMgr.loginMgr.isDesktop) {
                                  Get.toNamed(
                                    RouteName.addEmail,
                                    id: 3,
                                  )?.then((value) {
                                    controller.refreshData();
                                    return true;
                                  });
                                } else {
                                  Get.toNamed(RouteName.addEmail)
                                      ?.then((value) {
                                    controller.refreshData();
                                    return true;
                                  });
                                }
                              },
                              title: localized(authChangeEmail),
                              rightTitle: controller.getEmailStr,
                              rightTitleFontSize: 16,
                              withBorder: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 24),
              child: Text(localized(authSafetyDescription),
                  style: jxTextStyle.normalSmallText(
                    color: colorTextLevelTwo,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
