import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/debug_info.dart';

import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';
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
        title: localized(authenticationMethod),
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
              child: Text(
                localized(authDescription),
                style: jxTextStyle.textStyle13(color: colorTextSecondary),
              ),
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
                            rightWidget: SizedBox(
                              height: 28,
                              width: 48,
                              child: Obx(
                                () => CupertinoSwitch(
                                  value: controller.phoneNumAuthSwitch.value,
                                  activeColor: colorGreen,
                                  onChanged: (bool value) {
                                    pdebug("Switch state changed to: $value");
                                    controller.setPhoneNumAuthSwitch(value);
                                  },
                                ),
                              ),
                            ),
                          ),
                          Obx(
                            () => SettingItem(
                              paddingVerticalMobile: 9,
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (BuildContext context) {
                                    return CustomConfirmationPopup(
                                      title: localized(
                                        areYouSureToChangeTheNumber,
                                      ),
                                      subTitle:
                                          localized(afterChangePhoneNumber),
                                      confirmButtonText:
                                          localized(changeNewNumber),
                                      cancelButtonText: localized(buttonCancel),
                                      cancelButtonColor: themeColor,
                                      confirmCallback: () {
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
                                      cancelCallback: () =>
                                          Navigator.of(context).pop(),
                                    );
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
            ImGap.vGap24,

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
                            rightWidget: SizedBox(
                              height: 28,
                              width: 48,
                              child: Obx(
                                () => CupertinoSwitch(
                                  value: controller.emailAuthSwitch.value,
                                  activeColor: colorGreen,
                                  onChanged: (bool value) {
                                    pdebug("Switch state changed to: $value");
                                    controller.setEmailAuthSwitch(value);
                                  },
                                ),
                              ),
                            ),
                          ),
                          Obx(
                            () => SettingItem(
                              paddingVerticalMobile: 9,
                              onTap: () {
                                Get.toNamed(RouteName.addEmail)?.then((value) {
                                  controller.refreshData();
                                  return true;
                                });
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
              child: Text(
                localized(authSafetyDescription),
                style: jxTextStyle.textStyle13(color: colorTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
