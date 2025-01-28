import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/debug_info.dart';

import '../../../home/setting/setting_item.dart';
import '../../../main.dart';
import '../../../routes.dart';
import '../../../utils/color.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/localization/app_localizations.dart';
import '../../../utils/theme/text_styles.dart';
import '../../component/custom_confirmation_popup.dart';
import '../../component/new_appbar.dart';
import 'authMethodController.dart';

class AuthMethodView extends GetView<AuthMethodController> {
  const AuthMethodView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PrimaryAppBar(
        bgColor: Colors.transparent,
        title: '验证方式',
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
                '手机号验证默认开启，至少开启一种验证方式',
                style: jxTextStyle.textStyle13(color: JXColors.black48),
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
                            title: '手机号验证',
                            withArrow: false,
                            rightWidget: SizedBox(
                              height: 28,
                              width: 48,
                              child: Obx(() => CupertinoSwitch(
                                    value: controller.phoneNumAuthSwitch.value,
                                    activeColor: JXColors.green,
                                    onChanged: (bool value) {
                                      pdebug("Switch state changed to: $value");
                                      controller.setPhoneNumAuthSwitch(value);
                                    },
                                  )),
                            ),
                          ),
                          Obx(() => SettingItem(
                                paddingVerticalMobile: 9,
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    builder: (BuildContext context) {
                                      return CustomConfirmationPopup(
                                        title: localized(
                                            areYouSureToChangeTheNumber),
                                        subTitle:
                                            localized(afterChangePhoneNumber),
                                        confirmButtonText:
                                            localized(changeNewNumber),
                                        cancelButtonText:
                                            localized(buttonCancel),
                                        cancelButtonColor: accentColor,
                                        confirmCallback: () {
                                          if (objectMgr.loginMgr.isDesktop) {
                                            Get.toNamed(
                                                    RouteName.editPhoneNumber,
                                                    id: 3)
                                                ?.then((value) {
                                              controller.refreshData();
                                              return true;
                                            });
                                          } else {
                                            Get.toNamed(
                                                    RouteName.editPhoneNumber)
                                                ?.then((value) {
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
                                title: '更改号码',
                                rightTitle: controller.getPhoneStr,
                                rightTitleFontSize: 16,
                                withBorder: false,
                              )),
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
                            title: '邮箱验证',
                            withArrow: false,
                            rightWidget: SizedBox(
                              height: 28,
                              width: 48,
                              child: Obx(() => CupertinoSwitch(
                                    value: controller.emailAuthSwitch.value,
                                    activeColor: JXColors.green,
                                    onChanged: (bool value) {
                                      pdebug("Switch state changed to: $value");
                                      controller.setEmailAuthSwitch(value);
                                    },
                                  )),
                            ),
                          ),
                          Obx(() => SettingItem(
                                paddingVerticalMobile: 9,
                                onTap: () {
                                  Get.toNamed(RouteName.addEmail)
                                      ?.then((value) {
                                    controller.refreshData();
                                    return true;
                                  });
                                },
                                title: '更改邮箱',
                                rightTitle: controller.getEmailStr,
                                rightTitleFontSize: 16,
                                withBorder: false,
                              )),
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
                '为了您的财产安全，当超出每日转账限额或存在安全隐患时，需要进行二次验证。',
                style: jxTextStyle.textStyle13(color: JXColors.black48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
