import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/translation/translate_to_controller.dart';

class TranslateToView extends GetView<TranslateToController> {
  const TranslateToView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(translateTo),
        bgColor: Colors.transparent,
        onPressedBackBtn: ()=> objectMgr.loginMgr.isDesktop
            ? Get.back(id: 1) : Get.back(),
        trailing: [
          OpacityEffect(
            child: GestureDetector(
              onTap: () {
                controller.onTapDoneButton();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: controller.languageList.length,
              itemBuilder: (ctx, index) {
                return createItem(index);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget createItem(int index) {
    LanguageOption item = controller.languageList[index];
    bool isAuto = item.name == 'App Language';
    return SettingItem(
      onTap: () {
        controller.onChangeLanguage(item);
      },
      title: isAuto ? localized(item.key) : item.name,
      subtitle: isAuto
          ? getAutoLocale(
              isMe: !controller.incomingChatSettings,
              fullName: true,
            )
          : localized(item.key),
      withArrow: false,
      withEffect: true,
      withBorder: index != controller.languageList.length - 1,
      rightWidget: Obx(
        () => Visibility(
          visible: controller.chosenLanguage.value == item,
          child: SvgPicture.asset(
            'assets/svgs/check.svg',
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(themeColor, BlendMode.srcATop),
          ),
        ),
      ),
    );
  }
}
