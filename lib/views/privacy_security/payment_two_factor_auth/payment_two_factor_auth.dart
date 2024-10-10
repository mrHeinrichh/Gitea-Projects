import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/payment_two_factor_auth/payment_two_factor_auth_controller.dart';

import 'package:jxim_client/utils/lang_util.dart';

class PaymentTwoFactorAuthView extends GetView<PaymentTwoFactorAuthController> {
  const PaymentTwoFactorAuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(paymentTwoFactorAuth),
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
                  rightWidget: SizedBox(
                    height: 28,
                    width: 48,
                    child: Obx(
                      () => CupertinoSwitch(
                        value: controller.paymentTwoFactorAuthSwitch.value,
                        activeColor: colorGreen,
                        onChanged: (bool value) {
                          controller.setPaymentTwoFactorAuthSwitch(value);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                localized(enableTwoFactorAuth),
                style: jxTextStyle.textStyle13(
                  color: colorTextSecondary,
                ),
              ),
            ),
            const Flexible(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}
