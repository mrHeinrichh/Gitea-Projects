import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/opera_bag_widget/red_packet/red_packet_controller.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';

import '../../../../views/login/components/otp_box.dart';
import '../../../../views/wallet/components/number_pad.dart';

class RedPacketPasscodeModalBottomSheet extends GetWidget<RedPacketController> {
  const RedPacketPasscodeModalBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 1, color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 1, child: Container()),
                Expanded(
                  flex: 3,
                  child: Text(
                    localized(enterWalletPin),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: const Icon(
                        Icons.close,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 0),
            child: OTPBox(
              length: 4, autoFocus: false, readOnly: true,
              obscureText: true, autoDisposeControllers: true,
              enabled: controller.passwordCount < 5,
              controller: controller.pinCodeController,
              onChanged: (String value) {},
              onCompleted: controller.confirmSend,
              // focusNode: controller.passcodeFocusNode,
            ),
          ),
          Obx(
            () => Visibility(
              visible:
                  controller.passwordCount > 0 && controller.passwordCount < 5,
              child: Container(
                width: double.infinity,
                // alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Text(
                  localized(invalidPinRemainingAttemptWithParam,params: ["${5 - controller.passwordCount.value}"]),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: JXColors.red),
                ),
              ),
            ),
          ),
          Obx(
            () => Visibility(
              visible: controller.passwordCount >= 5,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Text(
                  localized(walletPinMax),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: JXColors.red,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          NumberPad(
              onNumTap: (num) {
                controller.onNumberTap(num);
              },
              onDeleteTap: () => controller.onDeleteTap()),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
