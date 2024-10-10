import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/end_to_end_encryption/friend_verify/friend_verify_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';

class FriendVerifyView extends GetView<FriendVerifyController> {
  const FriendVerifyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(friendVerify),
        trailing: [
          GestureDetector(
            onTap: () => controller.refreshCode(),
            child: OpacityEffect(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  localized(refreshText),
                  style: jxTextStyle.textStyle17(color: themeColor),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Obx(
                () => Text(
                  controller.code.value,
                  style: TextStyle(
                    fontSize: MFontSize.size34.value,
                    fontWeight: MFontWeight.bold5.value,
                    color: themeColor,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 13, bottom: 16),
              child: Text(
                localized(friendVerifyContent1),
                style: jxTextStyle.headerSmallText(color: colorTextSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "\u2022 ${localized(friendVerifyValidContent1)}",
                    style: jxTextStyle.headerSmallText(color: colorTextPrimary),
                  ),
                  Text(
                    "\u2022 ${localized(friendVerifyValidContent2)}",
                    style: jxTextStyle.headerSmallText(color: colorTextPrimary),
                  ),
                  Text(
                    "\u2022 ${localized(friendVerifyValidContent3)}",
                    style: jxTextStyle.headerSmallText(color: colorTextPrimary),
                  ),
                  Text(
                    "\u2022 ${localized(friendVerifyValidContent4)}",
                    style: jxTextStyle.headerSmallText(color: colorTextPrimary),
                  ),
                ],
              ),
            ),
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SettingItem(
                title: localized(otherFriendVerify),
                rightWidget: Obx(
                  () => Text(
                    '${controller.verified}/${controller.count}',
                    style: jxTextStyle.headerText(color: colorTextSecondary),
                  ),
                ),
                withBorder: false,
                withArrow: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              child: Text(
                localized(friendVerifyContent2),
                style: jxTextStyle.headerSmallText(color: colorTextSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            CustomButton(
              text: localized(buttonNext),
              isBold: false,
              color: controller.isValidToProceed.value
                  ? themeColor
                  : colorTextSupporting,
              callBack: () => controller.confirmResetPassword(),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => controller.skipFriendVerified(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    localized(bindSkip),
                    style: jxTextStyle.headerText(color: colorRed),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
