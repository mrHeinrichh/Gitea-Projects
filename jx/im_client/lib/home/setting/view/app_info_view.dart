import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/controller/app_info_controller.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';

class AppInfoView extends GetView<AppInfoController> {
  const AppInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        title: localized(appInfo),
        onPressedBackBtn: objectMgr.loginMgr.isDesktop
            ? () {
                Get.back(id: 3);
                Get.find<SettingController>().desktopSettingCurrentRoute = '';
                Get.find<SettingController>().selectedIndex.value = 101010;
              }
            : null,
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/icons/img.png',
                            width: 100,
                            height: 100,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => Text(
                          localized(versionWithParam,
                              params: [(controller.currentVersion.value)]),
                          style: jxTextStyle.textStyleBold14(
                            fontWeight: MFontWeight.bold4.value,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          controller.getCurrentVersionDescription(context);
                        },
                        behavior: HitTestBehavior.translucent,
                        child: OpacityEffect(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              localized(learnMore),
                              style: jxTextStyle.normalText(color: themeColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 32, left: 16, bottom: 4),
                  child: Text(localized(others),
                      style: jxTextStyle.normalSmallText(
                        color: colorTextLevelTwo,
                      )),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        /// tnc
                        SettingItem(
                          onTap: () {
                            linkToWebView(
                                "${Config().officialUrl}terms-of-service",
                                useInternalWebView: false);
                          },
                          title: localized(termAndCondition),
                        ),

                        /// privacy and policy
                        SettingItem(
                          onTap: () {
                            linkToWebView(
                                "${Config().officialUrl}privacy-policy",
                                useInternalWebView: false);
                          },
                          title: localized(privacyPolicy),
                        ),

                        if (Config().enableExperiment)
                          SettingItem(
                            onTap: () {
                              if (objectMgr.loginMgr.isDesktop) {
                                Get.toNamed(RouteName.experimentView, id: 3);
                              } else {
                                Get.toNamed(RouteName.experimentView);
                              }
                            },
                            title: localized(experimentTitle),
                          ),

                        SettingItem(
                          onTap: () {
                            if (objectMgr.loginMgr.isDesktop) {
                              Get.toNamed(RouteName.feedback, id: 3);
                            } else {
                              Get.toNamed(RouteName.feedback);
                            }
                          },
                          title: localized(feedback),
                        ),

                        /// app update
                        if (Config().enableVersionUpdate)
                          SettingItem(
                            onTap: () {
                              controller.softUpdateVersionDialogPopUp(context);
                            },
                            title: localized(appUpdate),
                            withBorder: false,
                            rightWidget: Row(
                              children: [
                                Obx(
                                  () => Visibility(
                                    visible:
                                        controller.isSoftUpdateAvailable.value,
                                    child: const Icon(
                                      Icons.circle,
                                      color: colorRed,
                                      size: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Obx(
                                  () => Text(
                                    controller.isSoftUpdateAvailable.value
                                        ? localized(latestVersion, params: [
                                            (controller.latestVersion.value)
                                          ])
                                        : localized(versionIsLatest),
                                    style: jxTextStyle.headerText(
                                        color: colorTextSecondary),
                                  ),
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
          ),
        ],
      ),
    );
  }
}
