import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/custom_content/translate/translate_controller.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

import '../../../home/setting/setting_item.dart';
import '../../../object/language_option_model.dart';
import '../../../utils/color.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/localization/app_localizations.dart';
import '../../../utils/theme/text_styles.dart';
import '../../../views/component/click_effect_button.dart';
import 'expandable_text.dart';

class TranslateContainer extends StatelessWidget {
  final String messageText;

  TranslateContainer({
    Key? key,
    required this.messageText,
  }) : super(key: key);

  TranslateController get controller => Get.find<TranslateController>();

  @override
  Widget build(BuildContext context) {
    Get.put(TranslateController(messageText));

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Obx(
        () => AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: controller.currentPage == 1
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: firstPage(context),
          secondChild: secondPage(context),
          firstCurve: Curves.easeInOutCubic,
          secondCurve: Curves.easeInOutCubic,
        ),
      ),
    );
  }

  Widget firstPage(BuildContext context) {
    return Obx(
      () => Container(
        height: MediaQuery.of(context).size.height * controller.height.value,
        child: Column(
          children: [
            /// navigator bar
            SizedBox(
              height: 60,
              child: NavigationToolbar(
                leading: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: Get.back,
                  child: OpacityEffect(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      child: Text(
                        localized(buttonClose),
                        style: jxTextStyle.textStyle17(color: accentColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                centerMiddle: true,
                middle: Text(
                  localized(chatOptionsTranslate),
                  style: jxTextStyle.textStyleBold17(),
                ),
              ),
            ),

            /// content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 4.0,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  localized(detectAs),
                                  style: jxTextStyle.textStyle12(
                                      color: JXColors.secondaryTextBlack),
                                ),
                                GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () => controller.switchPage(2,
                                      translatePage: TranslateController
                                          .TRANSLATE_FROM_PAGE),
                                  child: OpacityEffect(
                                    child: Text(
                                      controller.langOptionList
                                              .firstWhereOrNull((element) =>
                                                  element.locale ==
                                                  controller.translateFromLocale
                                                      .value)
                                              ?.content ??
                                          "",
                                      style: jxTextStyle.textStyleBold12(
                                          fontWeight: MFontWeight.bold6.value),
                                    ),
                                  ),
                                ),
                                SvgPicture.asset(
                                  'assets/svgs/translate_option.svg',
                                  width: 12,
                                  height: 12,
                                ),
                              ],
                            ),
                          ),
                          ExpandableText(
                            text: messageText,
                            callBack: () {
                              controller.height.value = 0.95;
                            },
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SeparateDivider(indent: 0.0),
                      ),
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Visibility(
                              visible: controller.translateToLocale.value.countryCode != null,
                              child: GestureDetector(
                                onTap: () => controller.switchPage(2,
                                    translatePage:
                                        TranslateController.TRANSLATE_TO_PAGE),
                                child: OpacityEffect(
                                  child: Row(
                                    children: [
                                      Text(
                                        controller.langOptionList
                                                .firstWhereOrNull((element) =>
                                                    element.locale ==
                                                    controller
                                                        .translateToLocale.value)
                                                ?.content ??
                                            "",
                                        style: jxTextStyle.textStyleBold12(
                                          color: accentColor,
                                          fontWeight: MFontWeight.bold6.value,
                                        ),
                                      ),
                                      SvgPicture.asset(
                                        'assets/svgs/translate_option.svg',
                                        width: 12,
                                        height: 12,
                                        colorFilter: ColorFilter.mode(
                                            accentColor, BlendMode.srcIn),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Obx(
                              () => Text(
                                controller.translateText.value,
                                style:
                                    jxTextStyle.textStyle16(color: accentColor),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget secondPage(BuildContext context) {
    return Obx(
      () => Container(
        height: MediaQuery.of(context).size.height * controller.height.value,
        child: Column(
          children: [
            /// navigator bar
            SizedBox(
              height: 60,
              child: NavigationToolbar(
                leading: OpacityEffect(
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomLeadingIcon(
                      needPadding: false,
                      buttonOnPressed: () =>
                          controller.switchPage(1, isBack: true),
                    ),
                  ),
                ),
                centerMiddle: true,
                middle: Text(
                  localized(original),
                  style: jxTextStyle.textStyleBold17(),
                ),
                trailing: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => controller.onClickDone(),
                  child: OpacityEffect(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      child: Text(
                        localized(buttonDone),
                        style: jxTextStyle.textStyle17(color: accentColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// content
            Container(
              margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Obx(
                () => ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: controller.langOptionList
                      .map((e) => createItem(e))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget createItem(LanguageOptionModel languageOptionModel) {
    String translatePage = controller.currentTranslatePage.value;
    Locale? currentLocale = controller.selectTranslateLocale.value;

    return SettingItem(
      onTap: () => controller.onClickItem(translatePage, languageOptionModel),
      title: languageOptionModel.title,
      subtitle: languageOptionModel.content,
      withArrow: false,
      withEffect: true,
      withBorder:
          languageOptionModel == controller.langOptionList.last ? false : true,
      rightWidget: languageOptionModel.locale == currentLocale
          ? SvgPicture.asset(
              'assets/svgs/check.svg',
              width: 16,
              height: 16,
        colorFilter: ColorFilter.mode(accentColor, BlendMode.srcATop),
            )
          : const SizedBox(),
    );
  }
}
