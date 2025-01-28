import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import '../../../home/setting/setting_item.dart';
import '../../../utils/color.dart';
import '../../component/new_appbar.dart';
import 'PaymentTwoFactorAuthController.dart';

class PaymentTwoFactorAuthView extends GetView<PaymentTwoFactorAuthController> {
  const PaymentTwoFactorAuthView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PrimaryAppBar(
        bgColor: Colors.transparent,
        title: '支付二次验证',
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
                  title: '支付二次验证',
                  withArrow: false,
                  withBorder: false,
                  rightWidget: SizedBox(
                    height: 28,
                    width: 48,
                    child: Obx(() => CupertinoSwitch(
                      value: controller.paymentTwoFactorAuthSwitch.value,
                      activeColor: JXColors.green,
                      onChanged: (bool value) {
                        controller.setPaymentTwoFactorAuthSwitch(value);
                      },
                    )),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text('开启后，每笔支付前需要进行二次验证',
                style: jxTextStyle.textStyle13(
                  color: JXColors.black48
                ),
              ),
            ),
            const Flexible(child: SizedBox())
          ],
        ),
      ),
    );
  }
}
