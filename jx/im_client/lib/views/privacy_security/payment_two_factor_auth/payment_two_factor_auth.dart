import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/custom_cupertino_switch.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/payment_two_factor_auth/payment_two_factor_auth_controller.dart';

class PaymentTwoFactorAuthView extends GetView<PaymentTwoFactorAuthController> {
  const PaymentTwoFactorAuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        leadingWidth: objectMgr.loginMgr.isDesktop ? 60 : null,
        title: localized(paymentTwoFactorAuth),
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
            GestureDetector(
              onTap: () {},
              child: Container(
                clipBehavior: Clip.hardEdge,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SettingItem(
                  paddingVerticalMobile: 8,
                  withEffect: false,
                  title: localized(paymentTwoFactorAuth),
                  withArrow: false,
                  withBorder: false,
                  rightWidget: Obx(
                    () => CustomCupertinoSwitch(
                      value: controller.paymentTwoFactorAuthSwitch.value,
                      callBack: controller.setPaymentTwoFactorAuthSwitch,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(localized(enableTwoFactorAuth),
                  style: jxTextStyle.normalSmallText(
                    color: colorTextLevelTwo,
                  )),
            ),
            const Flexible(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}
