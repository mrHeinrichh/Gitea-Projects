

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as common;
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/im_toast/primary_button.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

import '../../../managers/utils.dart';
import '../../component/new_appbar.dart';
import 'limit_secondary_auth_controller.dart';

class ModifyLimitView extends GetView<LimitSecondaryAuthController> {
   ModifyLimitView({Key? key}) : super(key: key);

  late LimitSecondaryAuthController controller;

  Widget subtitle({required String title, double pBottom = 0.0}){
    return Padding(
      padding: EdgeInsets.only(left: 16, bottom: pBottom).w,
      child: Text(title,
        style: jxTextStyle.textStyle13(
            color: JXColors.black48
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    controller = Get.find<LimitSecondaryAuthController>();

    if(controller.initialized || context.mounted) {
      ///fixing init problem in controller
      controller.legalCurrencyController.clear();
      controller.cryptoCurrencyController.clear();
    };

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PrimaryAppBar(
        bgColor: Colors.transparent,
        title: '修改限额',
      ),
      body: Obx(()=> Column(
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
                    title: '说明：将已修改后的额度作为二次验证的额度。',
                    pBottom: 24
                ),
                subtitle(
                    title: '人民币限额',
                    pBottom: 8
                ),
                common.ImTextField(
                  onTapInput: () {
                    controller.isKeyboardVisible(true);
                    controller.currentKeyboardController(
                        controller.legalCurrencyController);
                  },
                  controller: controller.legalCurrencyController,
                  hintText: '请输入',
                  showClearButton: false,
                  onTapClearButton: () {},
                ),
                ImGap.vGap24,
                subtitle(
                    title: 'USDT限额',
                    pBottom: 8
                ),

                common.ImTextField(
                  onTapInput: () {
                    controller.isKeyboardVisible(true);
                    controller.currentKeyboardController(
                        controller.cryptoCurrencyController);
                  },
                  controller: controller.cryptoCurrencyController,
                  hintText: '请输入',
                  showClearButton: false,
                  onTapClearButton: () {},
                ),
                ImGap.vGap24,

                PrimaryButton(
                  title: '下一步',
                  bgColor: controller.isValidLimit.value ? JXColors.blue : JXColors.black3,
                  txtColor: controller.isValidLimit.value ? JXColors.white : JXColors.black24,
                  onPressed: (){
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
                double input = 0;

                final currentKBController =
                    controller.currentKeyboardController.value;

                ///防呆禁止user輸入非合法數值
                if(!isNumeric(currentKBController.text)) currentKBController.text = '';

                if (currentKBController == controller.legalCurrencyController) {
                  final legalText = currentKBController.text;

                  if (legalText.isNotEmpty) {
                    // input = double.parse(legalText);
                    controller.dailyLimitLegal.value = legalText;
                  }
                }

                if (currentKBController == controller.cryptoCurrencyController) {
                  final crypto = currentKBController.text;

                  if (crypto.isNotEmpty) {
                    // input = double.parse(crypto);
                    controller.dailyLimitCrypto.value = crypto;
                  }

                }
                controller.isValidLimit.value = controller.legalCurrencyController.text.isNotEmpty &&
                    controller.cryptoCurrencyController.text.isNotEmpty ? true : false;
              },
              onTapCancel: () => controller.setKeyboardState(false),
              onTapConfirm: () => controller.setKeyboardState(false),
            ),
        ],
      )),
    );
  }
}
