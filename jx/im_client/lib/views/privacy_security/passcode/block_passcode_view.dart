import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_block_contrtoller.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_controller.dart';
import 'package:jxim_client/views/wallet/components/fullscreen_width_button.dart';

class BlockPasscodeView extends GetView<PasscodeBlockController> {
  const BlockPasscodeView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(security),
        leading: CustomLeadingIcon(
          buttonOnPressed: () {
            Get.until((route) => Get.currentRoute == RouteName.privacySecurity);
            Get.toNamed(RouteName.passcodeSetting);
          },
          childIcon: 'assets/svgs/close_icon.svg',
        ),
      ),
      body: Container(
        padding: const EdgeInsets.only(
          top: 40,
          bottom: 28,
          left: 20,
          right: 20,
        ),
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/svgs/block_icon.svg',
                    width: 60,
                    height: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localized(youAreBlocked),
                    style: jxTextStyle.textStyleBold16(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  GetBuilder<PasscodeBlockController>(
                    init: controller,
                    builder: (_) {
                      return Text(
                        localized(
                          blockContentWithParam,
                          params: [(controller.expiryTime)],
                        ),
                        style: jxTextStyle.textStyle14(
                          color: colorTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ],
              ),
            ),
            FullScreenWidthButton(
              title: localized(buttonNext),
              buttonColor: themeColor,
              onTap: () {
                if (Get.isRegistered<PasscodeController>()) {
                  Get.until(
                    (route) => Get.currentRoute == RouteName.passcodeSetting,
                  );
                  Get.toNamed(RouteName.passcodeSetting);
                } else {
                  Get.back();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
