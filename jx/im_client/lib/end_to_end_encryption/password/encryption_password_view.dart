import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/end_to_end_encryption/password/encryption_password_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/custom_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

class EncryptionPasswordView extends GetView<EncryptionPasswordController> {
  const EncryptionPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(privateKeyPassword),
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
                    child: Obx(
                      () => TextFormField(
                        obscureText: controller.hidePw.value,
                        contextMenuBuilder: textMenuBar,
                        autofocus: true,
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
                              onTap: () => controller.onHidePassword(),
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
                        onChanged: (value) => controller.onChanged(value),
                      ),
                    ),
                  ),
                ),
                Obx(
                  () => Visibility(
                    visible: controller.pwErrorText.isNotEmpty,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 8.0, left: 16, right: 16),
                      child: Text(
                        controller.pwErrorText.value,
                        style: jxTextStyle.normalSmallText(
                          color: colorRed,
                        ),
                      ),
                    ),
                  ),
                ),
                Obx(
                  () => Visibility(
                    visible: controller.unlockTimeError.value.isNotEmpty,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 8.0, left: 16, right: 16),
                      child: Text(
                        controller.unlockTimeError.value,
                        style: jxTextStyle.normalSmallText(
                          color: colorRed,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => CustomButton(
                    color: controller.isValidSubmit.value
                        ? themeColor
                        : colorTextSupporting,
                    text: localized(buttonNext),
                    isBold: false,
                    callBack: () => controller.onClickNext(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
