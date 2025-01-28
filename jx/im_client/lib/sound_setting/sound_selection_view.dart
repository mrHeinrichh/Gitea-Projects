import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/object/sound.dart';
import 'package:jxim_client/sound_setting/sound_selection_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

class SoundSelectionView extends GetView<SoundSelectionController> {
  const SoundSelectionView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: controller.title,
        isBackButton: false,
        leading: OpacityEffect(
          child: GestureDetector(
            onTap: () => controller.onBackButtonTrigger(),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                top: 10.0,
                bottom: 10.0,
              ),
              child: Text(
                localized(buttonCancel),
                style: jxTextStyle.textStyle17(color: themeColor),
              ),
            ),
          ),
        ),
        trailing: [
          Visibility(
            visible: true,
            child: GestureDetector(
              onTap: () => controller.onDoneButtonClick(),
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
        ],
      ),
      body: Obx(
        () => _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (controller.isLoading.value) {
      return Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            color: themeColor,
            strokeWidth: 2,
          ),
        ),
      );
    } else {
      if (controller.soundList.isEmpty) {
        return Center(
          child: Text(localized(nothingHere)),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: colorSurface,
              child: Obx(
                () => ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: List.generate(
                    controller.soundList.length,
                    (index) => createItem(index),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
  }

  Widget createItem(int index) {
    SoundData sound = controller.soundList[index];
    return SettingItem(
      onTap: () => controller.onClickItem(index),
      title: (sound.isDefault == 1) ? "Default" : sound.name,
      withArrow: false,
      withEffect: true,
      withBorder: index == controller.soundList.length - 1 ? false : true,
      rightWidget: controller.currentIndex.value == index
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
