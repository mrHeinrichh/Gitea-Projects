import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/reel/reel_profile/edit_profile_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/line_limiting_text_input_formatter.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/custom_button.dart';
import 'package:jxim_client/views/component/custom_image.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/reel/utils/reel_utils.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({
    super.key,
    required this.type,
  });
  final ReelEditTypeEnum type;

  @override
  Widget build(BuildContext context) {
    if (type == ReelEditTypeEnum.nickname) {
      controller.initialFocus = ReelEditTypeEnum.nickname;
    } else {
      controller.initialFocus = ReelEditTypeEnum.bio;
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: colorBackground,
        appBar: PrimaryAppBar(
          title: localized(edit),
          onPressedBackBtn: () => Get.back(),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
                children: [
                  textInputField(
                    labelText: localized(reelNickname),
                    hintText: localized(reelEditNicknameHintTxt),
                    txtController: controller.nameController,
                    focusNode: controller.nameFocusNode,
                    txtRemainCount: controller.nameTxtRemainCount,
                    textCount: controller.nameTxtCount,
                    maxLength: controller.nameMaxLength,
                    suffixIcon: Obx(
                      () => Visibility(
                        visible: controller.showNameClearBtn.value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 16,
                          ),
                          child: CustomImage(
                            'assets/svgs/clear_icon.svg',
                            color: colorTextPlaceholder,
                            width: 14,
                            height: 14,
                            fit: BoxFit.fitWidth,
                            onClick: () {
                              controller.nameController.clear();
                              controller.setShowClearBtn(false, type: 'name');
                              // controller.setRemainTxtCount('name');
                              controller.setTxtCount('name');
                            },
                          ),
                        ),
                      ),
                    ),
                    onChanged: (name) {
                      if (controller.nameController.text.isEmpty) {
                        controller.setShowClearBtn(false, type: 'name');
                      } else {
                        controller.setShowClearBtn(true, type: 'name');
                      }
                      controller.setTxtCount('name');
                    },
                    onTap: () {
                      if (controller.nameController.text.isEmpty) {
                        controller.setShowClearBtn(false, type: 'name');
                      } else {
                        controller.setShowClearBtn(true, type: 'name');
                      }
                    },
                  ),
                  ImGap.vGap8,
                  textInputField(
                    labelText: localized(bio),
                    hintText: localized(reelEditBioHintTxt),
                    maxLines: 5,
                    txtController: controller.bioController,
                    focusNode: controller.bioFocusNode,
                    txtRemainCount: controller.bioTxtRemainCount,
                    textCount: controller.bioTxtCount,
                    maxLength: controller.bioMaxLength,
                    onChanged: (bio) {
                      if (controller.bioController.text.isEmpty) {
                        controller.setShowClearBtn(false, type: 'bio');
                      } else {
                        controller.setShowClearBtn(true, type: 'bio');
                      }
                      controller.setTxtCount('bio');
                    },
                    onTap: () {
                      if (controller.bioController.text.isEmpty) {
                        controller.setShowClearBtn(false, type: 'bio');
                      } else {
                        controller.setShowClearBtn(true, type: 'bio');
                      }
                    },
                    suffixIcon: Obx(
                      () => Visibility(
                        visible: controller.showBioClearBtn.value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 16,
                          ),
                          child: CustomImage(
                            'assets/svgs/clear_icon.svg',
                            color: colorTextPlaceholder,
                            width: 14,
                            height: 14,
                            fit: BoxFit.fitWidth,
                            onClick: () {
                              controller.bioController.clear();
                              controller.setShowClearBtn(false, type: 'bio');
                              // controller.setRemainTxtCount('bio');
                              controller.setTxtCount('bio');
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Obx(() => buildSaveButton(controller.isCanSend.value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSaveButton(bool enabled) {
    Color enabledButtonColor = themeColor;
    Color enabledTextColor = colorWhite;
    Color buttonColor = colorTextPrimary.withOpacity(0.06);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: CustomButton(
        color: enabled ? enabledButtonColor : buttonColor,
        callBack: enabled ? controller.onTapSave : () {},
        text: localized(saveButton),
        textColor: enabled ? enabledTextColor : colorTextSecondary,
      ),
    );
  }

  Widget textInputField({
    labelText,
    hintText,
    maxLines = 1,
    txtController,
    suffixIcon,
    onChanged,
    onTap,
    FocusNode? focusNode,
    txtRemainCount,
    maxLength,
    textCount,
  }) {
    const commonInputBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
      borderRadius: BorderRadius.all(
        Radius.circular(8),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                labelText,
                style: jxTextStyle.textStyle14(color: colorTextSecondary),
              ),
              if (txtRemainCount != null)
                Obx(
                  () => Text(
                    // localized(reelRemainingTxt, params: ["${txtRemainCount}"]),
                    '$textCount/$maxLength',
                    style: jxTextStyle.textStyle13(
                      color: colorTextPrimary.withOpacity(0.24),
                    ),
                  ),
                ),
            ],
          ),
        ),
        TextField(
          contextMenuBuilder: textMenuBar,
          controller: txtController,
          showCursor: true,
          cursorColor: themeColor,
          focusNode: focusNode,
          decoration: InputDecoration(
            counterText: '', // 隱藏字數計數器
            filled: true,
            fillColor: colorWhite,
            hintText: hintText,
            hintStyle: jxTextStyle.textStyle16(color: colorTextSupporting),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            border: InputBorder.none,
            enabledBorder: commonInputBorder,
            focusedBorder: commonInputBorder,
            isDense: true,
            suffixIcon: suffixIcon,
          ),
          style: jxTextStyle.textStyle16(
            color: colorTextPrimary,
          ),
          maxLines: maxLines,
          inputFormatters: [
            LineLimitingTextInputFormatter(13), // 限制最多13行
          ],
          textAlign: TextAlign.left,
          onChanged: onChanged ?? (_) {},
          onTap: onTap,
          maxLength: maxLength,
        ),
      ],
    );
  }
}
