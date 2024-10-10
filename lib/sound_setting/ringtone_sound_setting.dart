import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/sound_setting/ringtone_sound_setting_controller.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/secretary_message_icon.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/check_tick_item.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

class RingtoneSoundSetting extends GetView<RingtoneSoundSettingController> {
  const RingtoneSoundSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(call),
        isBackButton: false,
        leading: Obx(() => _buildLeadingWidget()),
        trailing: [
          Obx(
            () => GestureDetector(
              onTap: () => controller.onEditDoneButtonClick(),
              child: OpacityEffect(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    localized(
                      controller.isEditMode.value ? buttonDone : buttonEdit,
                    ),
                    style: jxTextStyle.textStyle17(color: themeColor),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        SettingItem(
                          onTap: () => controller.changeSound(),
                          title: localized(ringtone),
                          withBorder: true,
                        ),
                        SettingItem(
                          withEffect: false,
                          title: localized(letFriendHearWhenCallingMe),
                          withArrow: false,
                          withBorder: false,
                          rightWidget: SizedBox(
                            height: 28,
                            width: 48,
                            child: Obx(
                              () => CupertinoSwitch(
                                value: controller.isSetOutGoingSound.value,
                                activeColor: themeColor,
                                onChanged: (value) =>
                                    controller.onChangeOutGoingSound(value),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: _buildTitle(
                      localized(yourFriendCanHearTheRingtoneWhenCallingYou),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTitle(localized(customisedRingtoneForFriends)),
                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        SettingItem(
                          onTap: () => controller.selectFriend(),
                          iconName: "add",
                          iconColor: themeColor,
                          title: localized(setCustomiseRingtone),
                          titleColor: themeColor,
                          withBorder:
                              controller.userList.isNotEmpty ? true : false,
                          withArrow: false,
                        ),
                        ...List.generate(
                          controller.userList.length,
                          (index) => Obx(() => createItem(index)),
                        ),
                        if (controller.userList.isNotEmpty)
                          SettingItem(
                            onTap: () => controller.onDeleteCustomization(true),
                            iconName: "delete_icon",
                            iconColor: colorRed,
                            title: localized(deleteAllCustomization),
                            titleColor: colorRed,
                            withBorder: false,
                            withArrow: false,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingWidget() {
    if (controller.isEditMode.value) {
      return GestureDetector(
        onTap: () => controller.onDeleteCustomization(false),
        child: OpacityEffect(
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              localized(buttonDelete),
              style: jxTextStyle.textStyle17(color: colorRed),
            ),
          ),
        ),
      );
    } else {
      return const CustomLeadingIcon();
    }
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: colorTextSecondary,
        ),
      ),
    );
  }

  Widget createItem(int index) {
    String user = controller.userList[index];
    Widget imgWidget = Row(
      children: [
        ClipRRect(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 350),
            alignment: Alignment.centerLeft,
            curve: Curves.easeInOutCubic,
            widthFactor: controller.isEditMode.value ? 1 : 0,
            child: Container(
              padding: const EdgeInsets.only(right: 12),
              child: const CheckTickItem(
                  // isCheck: controller.isSelected.value,
                  ),
            ),
          ),
        ),
        const SecretaryMessageIcon(size: 40),
      ],
    );

    return Slidable(
      key: UniqueKey(),
      closeOnScroll: true,
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.5,
        children: [
          CustomSlidableAction(
            onPressed: (_) => controller.changeSound(),
            backgroundColor: colorOrange,
            foregroundColor: Colors.white,
            child: Text(
              localized(buttonEdit),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          CustomSlidableAction(
            onPressed: (context) => controller.onDeleteCustomization(false),
            backgroundColor: colorRed,
            foregroundColor: Colors.white,
            child: Text(
              localized(buttonDelete),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      child: Expanded(
        child: SettingItem(
          imgWidget: imgWidget,
          titleWidget: Text(user),
          subtitle: "Sound",
          withArrow: false,
          withEffect: true,
          withBorder: index == controller.userList.last ? false : true,
        ),
      ),
    );
  }
}
