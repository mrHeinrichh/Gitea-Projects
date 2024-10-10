import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/end_to_end_encryption/friend_verify_setting/friend_verify_setting_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

class FriendVerifySettingView
    extends GetView<FriendVerifySettingController> {
  const FriendVerifySettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(friendVerify),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                localized(myFriendVerify),
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
                onTap: () => controller.navigateToForgetPasswordPage(),
                title: localized(friendVerify),
                rightWidget: Text(
                  '0/3',
                  // '${controller.verified}/${controller.count}',
                  style: jxTextStyle.headerText(color: colorTextSecondary),
                ),
                withBorder: false,
                withArrow: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Text(
                localized(cannotHelpOtherVerify),
                style: jxTextStyle.normalSmallText(color: colorTextSecondary),
              ),
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Text(
                    localized(helpOtherToVerify),
                    style:
                        jxTextStyle.normalSmallText(color: colorTextSecondary),
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
                    onTap: () => controller.navigateFriendVerifyPage(),
                    title: localized(otherFriendVerify),
                    withBorder: false,
                    withArrow: true,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
