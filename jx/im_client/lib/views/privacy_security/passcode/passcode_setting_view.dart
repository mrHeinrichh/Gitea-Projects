import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart' as im;
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/passcode/passcode_controller.dart';

class PasscodeSettingView extends GetView<PasscodeController> {
  const PasscodeSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(paymentPassword),
        leadingWidth: objectMgr.loginMgr.isDesktop ? 60 : null,
        onPressedBackBtn:
            objectMgr.loginMgr.isDesktop ? () => Get.back(id: 3) : null,
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          top: 24,
          left: 16.0,
          right: 16.0,
          bottom: 16.0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ColoredBox(
            color: Colors.white,
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: controller.selectionOptions.length,
              itemBuilder: (context, index) {
                return OverlayEffect(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      controller.walletPasscodeOptionClick(
                        controller.selectionOptions[index].optionType,
                      );
                    },
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            im.ImText(
                              controller.selectionOptions[index].title,
                              fontSize: MFontSize.size17.value,
                              color: controller.selectionOptions[index].color ??
                                  colorTextPrimary,
                            ),
                            const im.ImSvgIcon(
                              icon: 'icon_arrow_right',
                              color: im.ImColor.black48,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Divider(
                    height: 0,
                    thickness: 0.33,
                    color: im.ImColor.black20,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
