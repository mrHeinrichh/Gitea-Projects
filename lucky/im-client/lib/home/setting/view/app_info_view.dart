import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/controller/app_info_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';

class AppInfoView extends GetView<AppInfoController> {
  const AppInfoView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: objectMgr.loginMgr.isDesktop
          ? null
          : PrimaryAppBar(
              title: localized(appInfo),
            ),
      body: Column(
        children: [
          if (objectMgr.loginMgr.isDesktop)
            Container(
              height: 52,
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: const Border(
                  bottom: BorderSide(
                    color: JXColors.outlineColor,
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
                              color: JXColors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              localized(buttonBack),
                              style: const TextStyle(
                                fontSize: 13,
                                color: JXColors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    localized(appInfo),
                    style: const TextStyle(
                      fontSize: 16,
                      color: JXColors.black,
                    ),
                  ),
                  const SizedBox()
                ],
              ),
            ),
          Container(
            padding: objectMgr.loginMgr.isDesktop
                ? const EdgeInsets.only(top: 60, left: 16, right: 16)
                : const EdgeInsets.only(top: 60, left: 16, right: 16).w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onDoubleTap: () => controller.getLog(context),
                        child: ClipRRect(
                          borderRadius: objectMgr.loginMgr.isDesktop
                              ? BorderRadius.circular(20)
                              : BorderRadius.circular(20).w,
                          child: Image.asset(
                            'assets/icons/img.png',
                            width: objectMgr.loginMgr.isDesktop ? 120 : 120.w,
                            height: objectMgr.loginMgr.isDesktop ? 120 : 120.w,
                          ),
                        ),
                      ),
                      SizedBox(
                          height: objectMgr.loginMgr.isDesktop ? 16 : 16.w),
                      Obx(
                        () => Text(
                          localized(versionWithParam,
                              params: ["${controller.currentVersion.value}"]),
                          style: jxTextStyle.textStyleBold16(),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          controller.getCurrentVersionDescription(context);
                        },
                        behavior: HitTestBehavior.translucent,
                        child: OpacityEffect(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 8.0),
                            child: Text(
                              localized(learnMore),
                              style:
                                  jxTextStyle.textStyle14(color: accentColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: objectMgr.loginMgr.isDesktop
                      ? const EdgeInsets.only(top: 32, left: 16, bottom: 4)
                      : const EdgeInsets.only(top: 32, left: 16, bottom: 4).w,
                  child: Text(
                    localized(others),
                    style: const TextStyle(
                      fontSize: 13,
                      color: JXColors.secondaryTextBlack,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: objectMgr.loginMgr.isDesktop
                      ? BorderRadius.circular(8)
                      : BorderRadius.circular(8).w,
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

                        /// license
                        // SettingItem(
                        //   onTap: () =>
                        //       Toast.showToast(localized(homeToBeContinue)),
                        //   title: localized(license),
                        // ),
                        SettingItem(
                          onTap: () => Get.toNamed(RouteName.feedback),
                          title: localized(feedback),
                          // withBorder: false,
                        ),

                        /// app update
                        if(Config().enableVersionUpdate)
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
                                    child: Icon(
                                      Icons.circle,
                                      color: errorColor,
                                      size: 8,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    width:
                                        objectMgr.loginMgr.isDesktop ? 8 : 8.w),
                                Obx(
                                  () => Text(
                                    controller.isSoftUpdateAvailable.value
                                        ? localized(latestVersion, params: [
                                            '${controller.latestVersion.value}'
                                          ])
                                        : localized(versionIsLatest),
                                    style: jxTextStyle.textStyle14(
                                        color: JXColors.secondaryTextBlack),
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
