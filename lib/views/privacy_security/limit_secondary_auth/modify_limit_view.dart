import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/im_toast/primary_button.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/limit_secondary_auth/limit_secondary_auth_controller.dart';

class ModifyLimitView extends GetView<LimitSecondaryAuthController> {
  const ModifyLimitView({super.key});

  Widget subtitle({required String title, double pBottom = 0.0}) {
    return Padding(
      padding: EdgeInsets.only(left: 16, bottom: pBottom).w,
      child: Text(
        title,
        style: jxTextStyle.textStyle13(
          color: colorTextSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller.initialized || context.mounted) {
      controller.cryptoCurrencyController.clear();
    }

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(modificationLimit),
      ),
      body: Obx(
        () => Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 0.0,
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ImGap.vGap24,
                  subtitle(
                    title: 'USDT ${localized(dailyTransferLimit)}',
                    pBottom: 8,
                  ),
                  common.ImTextField(
                    onTapInput: () {
                      controller.isKeyboardVisible(true);
                      controller.currentKeyboardController(
                        controller.cryptoCurrencyController,
                      );
                    },
                    controller: controller.cryptoCurrencyController,
                    hintText: localized(plzEnter),
                    showClearButton: false,
                    onTapClearButton: () {},
                  ),
                  ImGap.vGap24,
                  PrimaryButton(
                    title: localized(buttonNext),
                    bgColor: controller.isValidLimit.value
                        ? themeColor
                        : Colors.black.withOpacity(0.03),
                    txtColor: controller.isValidLimit.value
                        ? Colors.white
                        : Colors.black.withOpacity(0.24),
                    onPressed: () {
                      controller.onSaveLimit();
                    },
                    width: double.infinity,
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (controller.isKeyboardVisible.value)
              common.KeyboardNumber(
                controller: controller.currentKeyboardController.value,
                showTopButtons: true,
                onTap: (value) {
                  final currentKBController =
                      controller.currentKeyboardController.value;

                  if (!isNumeric(currentKBController.text)) {
                    currentKBController.text = '';
                  }

                  if (currentKBController ==
                      controller.cryptoCurrencyController) {
                    final crypto = currentKBController.text;

                    if (crypto.isNotEmpty) {
                      controller.dailyLimitCrypto.value = crypto;
                    }
                  }
                  controller.isValidLimit.value =
                      controller.cryptoCurrencyController.text.isNotEmpty
                          ? true
                          : false;
                },
                onTapCancel: () => controller.setKeyboardState(false),
                onTapConfirm: () => controller.setKeyboardState(false),
              ),
          ],
        ),
      ),
    );
  }
}
