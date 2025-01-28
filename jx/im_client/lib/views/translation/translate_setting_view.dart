import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/component/custom_cupertino_switch.dart';
import 'package:jxim_client/views/translation/translate_setting_controller.dart';

class TranslateSettingView extends GetView<TranslateSettingController> {
  const TranslateSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(aiRealTimeTranslate),
        leadingWidth: objectMgr.loginMgr.isDesktop ? 60 : null,
        bgColor: Colors.transparent,
        onPressedBackBtn: ()=> objectMgr.loginMgr.isDesktop
            ? Get.back(id: 1) : Get.back(),
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
                          style: jxTextStyle.headerText(),
                        ),
                        onTap: () {
                          controller.autoSettingSwitchChanges(
                            true,
                            !controller.isTurnOnAutoIncoming.value,
                          );
                        },
                        rightWidget: CustomCupertinoSwitch(
                          value: controller.isTurnOnAutoIncoming.value,
                          callBack: (value) {
                            controller.autoSettingSwitchChanges(true, value);
                          },
                        ),
                        withArrow: false,
                      ),
                      SettingItem(
                        onTap: () {
                          if(objectMgr.loginMgr.isDesktop){
                            Get.toNamed(
                              RouteName.translateToView,
                              arguments: [controller.chat, true],
                              id: 1,
                            );
                          }else{
                            Get.toNamed(
                              RouteName.translateToView,
                              arguments: [controller.chat, true],
                            );
                          }
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
                          if(objectMgr.loginMgr.isDesktop){
                            Get.toNamed(
                              RouteName.translateVisualView,
                              arguments: [controller.chat, true],
                              id: 1,
                            );
                          }else{
                            Get.toNamed(
                              RouteName.translateVisualView,
                              arguments: [controller.chat, true],
                            );
                          }
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
                  style: jxTextStyle.normalSmallText(color: colorTextSecondary),
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
                          style: jxTextStyle.headerText(),
                        ),
                        onTap: () {
                          controller.autoSettingSwitchChanges(
                            false,
                            !controller.isTurnOnAutoOutgoing.value,
                          );
                        },
                        rightWidget: CustomCupertinoSwitch(
                          value: controller.isTurnOnAutoOutgoing.value,
                          callBack: (value) {
                            controller.autoSettingSwitchChanges(false, value);
                          },
                        ),
                        withArrow: false,
                      ),
                      SettingItem(
                        onTap: () {
                          if(objectMgr.loginMgr.isDesktop){
                            Get.toNamed(
                              RouteName.translateToView,
                              arguments: [controller.chat, false],
                              id: 1,
                            );
                          }else{
                            Get.toNamed(
                              RouteName.translateToView,
                              arguments: [controller.chat, false],
                            );
                          }
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
                          if(objectMgr.loginMgr.isDesktop){
                            Get.toNamed(
                              RouteName.translateVisualView,
                              arguments: [controller.chat, false],
                              id: 1,
                            );
                          }else{
                            Get.toNamed(
                              RouteName.translateVisualView,
                              arguments: [controller.chat, false],
                            );
                          }
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
                  style: jxTextStyle.normalSmallText(color: colorTextSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
