import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/translation/translate_setting_controller.dart';

class TranslateSettingView extends GetView<TranslateSettingController> {
  const TranslateSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(aiRealTimeTranslate),
        bgColor: Colors.transparent,
      ),
      body: CustomScrollableListView(
        children: [
          // Translate Receiving Messages
          Column(
            children: [
              BorderContainer(
                verticalPadding: 0,
                horizontalPadding: 0,
                child: Obx(() {
                  return Column(
                    children: [
                      SettingItem(
                        titleWidget: Text(
                          localized(translateIncomingTitle),
                          style: TextStyle(fontSize: MFontSize.size16.value),
                        ),
                        onTap: () {
                          controller.autoSettingSwitchChanges(
                            true,
                            !controller.isTurnOnAutoIncoming.value,
                          );
                        },
                        rightWidget: SizedBox(
                          width: 48,
                          height: 28,
                          child: FlutterSwitch(
                            activeColor: themeColor,
                            width: 48.0,
                            height: 28.0,
                            toggleSize: 24,
                            value: controller.isTurnOnAutoIncoming.value,
                            onToggle: (value) {
                              controller.autoSettingSwitchChanges(true, value);
                            },
                          ),
                        ),
                        withArrow: false,
                      ),
                      SettingItem(
                        onTap: () {
                          Get.toNamed(
                            RouteName.translateToView,
                            arguments: [controller.chat, true],
                          );
                        },
                        title: localized(translateTo),
                        rightTitle: controller.incomingLanguage.value.name ==
                                'App Language'
                            ? localized(controller.incomingLanguage.value.key)
                            : controller.incomingLanguage.value.name,
                        withBorder: true,
                        withEffect: true,
                        withArrow: true,
                      ),
                      SettingItem(
                        onTap: () {
                          Get.toNamed(
                            RouteName.translateVisualView,
                            arguments: [controller.chat, true],
                          );
                        },
                        title: localized(translateShowingType),
                        rightTitle: controller.incomingVisual.value == 0
                            ? localized(translateShowBoth)
                            : localized(translateShowOne),
                        withBorder: false,
                        withEffect: true,
                        withArrow: true,
                      ),
                    ],
                  );
                }),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  localized(translateIncomingDesc),
                  style: TextStyle(
                    fontSize: MFontSize.size14.value,
                    color: colorTextSecondary,
                  ),
                ),
              ),
            ],
          ),

          // Translate Sending Messages
          Column(
            children: [
              BorderContainer(
                verticalPadding: 0,
                horizontalPadding: 0,
                child: Obx(() {
                  return Column(
                    children: [
                      SettingItem(
                        titleWidget: Text(
                          localized(translateOutgoingTitle),
                          style: TextStyle(fontSize: MFontSize.size16.value),
                        ),
                        onTap: () {
                          controller.autoSettingSwitchChanges(
                            false,
                            !controller.isTurnOnAutoOutgoing.value,
                          );
                        },
                        rightWidget: SizedBox(
                          width: 48,
                          height: 28,
                          child: FlutterSwitch(
                            activeColor: themeColor,
                            width: 48.0,
                            height: 28.0,
                            toggleSize: 24,
                            value: controller.isTurnOnAutoOutgoing.value,
                            onToggle: (value) {
                              controller.autoSettingSwitchChanges(false, value);
                            },
                          ),
                        ),
                        withArrow: false,
                      ),
                      SettingItem(
                        onTap: () {
                          Get.toNamed(
                            RouteName.translateToView,
                            arguments: [controller.chat, false],
                          );
                        },
                        title: localized(translateTo),
                        rightTitle: controller.outgoingLanguage.value.name ==
                                'App Language'
                            ? localized(controller.outgoingLanguage.value.key)
                            : controller.outgoingLanguage.value.name,
                        withBorder: true,
                        withEffect: true,
                        withArrow: true,
                      ),
                      SettingItem(
                        onTap: () {
                          Get.toNamed(
                            RouteName.translateVisualView,
                            arguments: [controller.chat, false],
                          );
                        },
                        title: localized(translateShowingType),
                        rightTitle: controller.outgoingVisual.value == 0
                            ? localized(translateShowBoth)
                            : localized(translateShowOne),
                        withBorder: false,
                        withEffect: true,
                        withArrow: true,
                      ),
                    ],
                  );
                }),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  localized(translateOutgoingDesc),
                  style: TextStyle(
                    fontSize: MFontSize.size14.value,
                    color: colorTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
