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
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

class LanguageView extends GetView<LanguageController> {
  const LanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: objectMgr.loginMgr.isDesktop
          ? null
          : PrimaryAppBar(
              title: localized(language),
              onPressedBackBtn: () => controller.languagePageBackTrigger(),
              trailing: [
                Obx(
                  () => Visibility(
                    visible: controller.isChangeLanguage.value,
                    child: GestureDetector(
                      onTap: () => controller.showChangeLanguagePopup(),
                      child: OpacityEffect(
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            localized(buttonDone),
                            style: jxTextStyle.textStyle17(color: themeColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      body: Column(
        children: [
          if (objectMgr.loginMgr.isDesktop)
            Container(
              height: 52,
              padding: const EdgeInsets.only(left: 10),
              decoration: const BoxDecoration(
                color: colorBackground,
                border: Border(
                  bottom: BorderSide(
                    color: colorBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                /// 普通界面
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  OpacityEffect(
                    child: GestureDetector(
                      onTap: () {
                        Get.back(id: 3);
                        Get.find<SettingController>()
                            .desktopSettingCurrentRoute = '';
                        Get.find<SettingController>().selectedIndex.value =
                            101010;
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/svgs/Back.svg',
                              width: 18,
                              height: 18,
                              color: themeColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              localized(buttonBack),
                              style: TextStyle(
                                fontSize: 13,
                                color: themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    localized(language),
                    style: const TextStyle(
                      fontSize: 16,
                      color: colorTextPrimary,
                    ),
                  ),
                  Obx(
                    () => Visibility(
                      visible: controller.isChangeLanguage.value,
                      child: GestureDetector(
                        onTap: () async => controller.showChangeLanguagePopup(),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            localized(buttonDone),
                            style:
                                jxTextStyle.textStyleBold17(color: themeColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: Colors.white,
                child: Obx(
                  () => ListView(
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
