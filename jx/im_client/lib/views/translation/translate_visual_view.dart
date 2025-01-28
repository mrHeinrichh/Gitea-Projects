import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/translation/translate_visual_controller.dart';

class TranslateVisualView extends GetView<TranslateVisualController> {
  const TranslateVisualView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(translateShowingType),
        bgColor: Colors.transparent,
        onPressedBackBtn: ()=> objectMgr.loginMgr.isDesktop
            ? Get.back(id: 1) : Get.back(),
        trailing: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: OpacityEffect(
              child: GestureDetector(
                onTap: () {
                  controller.onTapDoneButton();
                },
                child: Text(
                  localized(buttonDone),
                  style: jxTextStyle.textStyle17(color: themeColor),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            color: Colors.white,
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                SettingItem(
                  onTap: (){
                    controller.onTapItem(0);
                  },
                  title: localized(translateShowBoth),
                  withArrow: false,
                  withEffect: true,
                  withBorder: true,
                  rightWidget: Obx(()=> Visibility(
                      visible: controller.currentVisualType.value == 0,
                      child: SvgPicture.asset(
                        'assets/svgs/check.svg',
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(themeColor, BlendMode.srcATop),
                      ),
                    ),
                  ),
                ),
                SettingItem(
                  onTap: (){
                    controller.onTapItem(1);
                  },
                  title: localized(translateShowOne),
                  withArrow: false,
                  withEffect: true,
                  withBorder: false,
                  rightWidget: Obx(()=> Visibility(
                    visible: controller.currentVisualType.value == 1,
                    child: SvgPicture.asset(
                      'assets/svgs/check.svg',
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(themeColor, BlendMode.srcATop),
                    ),
                  ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
