import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/language/language_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/language_option_model.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';

class LanguageView extends GetView<LanguageController> {
  const LanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(language),
        onPressedBackBtn: () {
          if (objectMgr.loginMgr.isDesktop) {
            Get.back(id: 3);
            Get.find<SettingController>().desktopSettingCurrentRoute = '';
            Get.find<SettingController>().selectedIndex.value = 101010;
          } else {
            controller.languagePageBackTrigger();
          }
        },
        trailing: [
          Obx(
            () => Visibility(
              visible: controller.isChangeLanguage.value,
              child: Center(
                child: CustomTextButton(
                  padding: EdgeInsets.symmetric(
                      horizontal: objectMgr.loginMgr.isDesktop ? 20 : 16),
                  localized(buttonDone),
                  onClick: ()=> controller.showChangeLanguagePopup(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.white,
                    child: Obx(
                      () => ListView(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: controller.languageOptionList
                            .map((e) => createItem(e))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget createItem(LanguageOptionModel languageOptionModel) {
    return SettingItem(
      onTap: () => controller.changeCurrLang(
        languageOptionModel.languageKey,
        languageOptionModel.locale,
      ),
      title: languageOptionModel.title,
      subtitle: languageOptionModel.content,
      subtitleStyle: jxTextStyle.normalSmallText(
        color: colorTextSecondary,
      ),
      withArrow: false,
      withEffect: true,
      withBorder: languageOptionModel == controller.languageOptionList.last
          ? false
          : true,
      rightWidget: languageOptionModel.isSelected
          ? SvgPicture.asset(
              'assets/svgs/check.svg',
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(themeColor, BlendMode.srcATop),
            )
          : const SizedBox(),
    );
  }
}
