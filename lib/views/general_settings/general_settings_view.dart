import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/general_settings/general_settings_controller.dart';
import 'package:jxim_client/home/setting/setting_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';

class GeneralSettingsView extends GetView<GeneralSettingsController> {
  const GeneralSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: objectMgr.loginMgr.isDesktop
          ? null
          : PrimaryAppBar(
              title: localized(generalSettings),
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
                    localized(generalSettings),
                    style: const TextStyle(
                      fontSize: 16,
                      color: colorTextPrimary,
                    ),
                  ),
                  const SizedBox(),
                ],
              ),
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  ImGap.vGap24,

                  /// Security Settings
                  Container(
                    margin: objectMgr.loginMgr.isDesktop
                        ? const EdgeInsets.only(bottom: 24)
                        : const EdgeInsets.only(bottom: 24).w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(localized(generalSettingsCompose)),
                        Container(
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              objectMgr.loginMgr.isDesktop ? 8 : 8.w,
                            ),
                          ),
                          child: Column(
                            children: [
                              SettingItem(
                                paddingVerticalMobile: 8,
                                withEffect: false,
                                title:
                                    localized(generalSettingsMirrorFrontCamera),
                                withArrow: false,
                                withBorder: false,
                                rightWidget: SizedBox(
                                  height: 28,
                                  width: 48,
                                  child: Obx(
                                    () => CupertinoSwitch(
                                      value:
                                          controller.isMirrorFrontCamera.value,
                                      activeColor: colorGreen,
                                      onChanged: (bool value) {
                                        controller.onTapMirrorFrontCamera();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildTitle(String title) {
    return Container(
      margin: objectMgr.loginMgr.isDesktop
          ? const EdgeInsets.only(left: 16, bottom: 8)
          : const EdgeInsets.only(left: 16, bottom: 8).w,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: colorTextSecondary,
        ),
      ),
    );
  }
}
