import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/end_to_end_encryption/friend_verify_other/friend_verify_other_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';

class FriendVerifyOtherView extends GetView<FriendVerifyOtherController> {
  const FriendVerifyOtherView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: const PrimaryAppBar(
        title: '好友辅助验证',
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                "请选择要帮谁完成好友辅助验证",
                style: jxTextStyle.normalSmallText(color: colorTextSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SettingItem(
                onTap: () => controller.showFriendListPopup(context),
                title: '好友',
                rightWidget: Obx(
                  () => Text(
                    controller.friendName.value != ''
                        ? controller.friendName.value
                        : '请选择',
                    style: jxTextStyle.headerText(color: colorTextSecondary),
                  ),
                ),
                withBorder: false,
                withArrow: true,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                "好友告诉你的6位数字",
                style: jxTextStyle.normalSmallText(color: colorTextSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: colorWhite,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Center(
                child: TextFormField(
                  contextMenuBuilder: textMenuBar,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(),
                  cursorColor: themeColor,
                  controller: controller.textEditingController,
                  focusNode: controller.pwFocusNode,
                  textAlignVertical: TextAlignVertical.center,
                  style: jxTextStyle.textStyle16(),
                  decoration: InputDecoration(
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: '验证码',
                    hintStyle:
                        jxTextStyle.textStyle16(color: colorTextSupporting),
                    isDense: true,
                    suffixIconConstraints: const BoxConstraints(
                      maxWidth: 20,
                      maxHeight: 20,
                    ),
                  ),
                  onChanged: (value) =>
                      controller.onChanged(value),
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
    );
  }
}
