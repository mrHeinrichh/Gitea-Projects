import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/end_to_end_encryption/setup_password/encryption_setup_password_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/custom_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

class EncryptionSetupPasswordView
    extends GetView<EncryptionSetupPasswordController> {
  const EncryptionSetupPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: colorBackground,
        appBar: PrimaryAppBar(
          title: controller.title.value,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorWhite,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Center(
                      child: TextFormField(
                        obscureText: controller.hidePw.value,
                        contextMenuBuilder: im.textMenuBar,
                        autofocus: true,
                        // keyboardType: const TextInputType.numberWithOptions(),
                        cursorColor: themeColor,
                        controller: controller.pwTextEditingController,
                        focusNode: controller.pwFocusNode,
                        textAlignVertical: TextAlignVertical.center,
                        style: jxTextStyle.textStyle16(),
                        decoration: InputDecoration(
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: localized(privateKeyPassword),
                          hintStyle: jxTextStyle.textStyle16(
                              color: colorTextSupporting),
                          isDense: true,
                          suffixIconConstraints: const BoxConstraints(
                            maxWidth: 20,
                          ),
                          suffixIcon: Obx(
                            () => GestureDetector(
                              onTap: () => controller.onHidePassword(
                                  EncryptionSetupPasswordController.PASSWORD),
                              child: Icon(
                                controller.hidePw.value
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                size: 24,
                                color: colorTextSecondary,
                              ),
                            ),
                          ),
                        ),
                        onChanged: (value) => controller.onChanged(
                            EncryptionSetupPasswordController.PASSWORD, value),
                      ),
                    ),
                  ),
                  Obx(
                    () => Visibility(
                      visible: controller.pwErrorText.isNotEmpty,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 8.0, left: 16, right: 16),
                        child: Text(
                          controller.pwErrorText.value,
                          style: jxTextStyle.normalSmallText(
                            color: colorRed,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorWhite,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Center(
                      child: TextFormField(
                        obscureText: controller.hideConfirmPw.value,
                        contextMenuBuilder: im.textMenuBar,
                        // inputFormatters: [
                        //   FilteringTextInputFormatter.digitsOnly,
                        // ],
                        autofocus: true,
                        // keyboardType: const TextInputType.numberWithOptions(),
                        cursorColor: themeColor,
                        controller: controller.confirmPwTextEditingController,
                        focusNode: controller.confirmPwFocusNode,
                        textAlignVertical: TextAlignVertical.center,
                        style: jxTextStyle.textStyle16(),
                        decoration: InputDecoration(
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: localized(confirmPrivateKeyPassword),
                          hintStyle: jxTextStyle.textStyle16(
                              color: colorTextSupporting),
                          isDense: true,
                          suffixIconConstraints: const BoxConstraints(
                            maxWidth: 20,
                          ),
                          suffixIcon: Obx(
                            () => GestureDetector(
                              onTap: () => controller.onHidePassword(
                                  EncryptionSetupPasswordController
                                      .CONFIRM_PASSWORD),
                              child: Icon(
                                controller.hideConfirmPw.value
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                size: 24,
                                color: colorTextSecondary,
                              ),
                            ),
                          ),
                        ),
                        onChanged: (value) => controller.onChanged(
                            EncryptionSetupPasswordController.CONFIRM_PASSWORD,
                            value),
                      ),
                    ),
                  ),
                  Obx(
                    () => Visibility(
                      visible: controller.confirmPwErrorText.isNotEmpty,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 8.0, left: 16, right: 16),
                        child: Text(
                          controller.confirmPwErrorText.value,
                          style: jxTextStyle.normalSmallText(
                            color: colorRed,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localized(encPasswordValidContent1),
                          style: jxTextStyle.normalSmallText(
                            color: colorTextLevelTwo,
                          ),
                        ),
                        Text(
                          localized(encPasswordValidContent2),
                          style: jxTextStyle.normalSmallText(
                            color: colorTextLevelTwo,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(
                    () => CustomButton(
                      color: controller.isValidSubmit.value
                          ? themeColor
                          : colorTextSupporting,
                      text: localized(buttonDone),
                      isBold: false,
                      callBack: () => controller.onDoneClick(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
