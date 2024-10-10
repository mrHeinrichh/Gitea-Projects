import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/discover/controllers/im_discover_controller.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/message/component/custom_angle.dart';

class IMDiscoverView extends GetView<IMDiscoverController> {
  const IMDiscoverView({super.key});

  @override
  Widget build(BuildContext context) {
    final boxDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    );

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        isBackButton: false,
        titleWidget: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  textAlign: TextAlign.center,
                  localized(homeDiscover), // Update to local text
                  style: jxTextStyle.appTitleStyle(color: colorTextPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 7),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  return Column(
                    children: [
                      Container(
                        clipBehavior: Clip.hardEdge,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: boxDecoration,
                        child: Column(
                          children: <Widget>[
                            /// 朋友圈
                            SettingItem(
                              onTap: () => controller.onSettingOptionTap(
                                  context, SettingOption.moment.type),
                              iconName: 'setting_moments',
                              title: localized(moment),
                              withBorder: false,
                              badgeWidget: Obx(() => controller
                                          .showMomentStrongNotification.value >
                                      0
                                  ? CustomAngle(
                                      value: min(
                                        objectMgr
                                            .momentMgr.notificationStrongCount,
                                        100,
                                      ),
                                      maxValue: 99,
                                    )
                                  : const SizedBox()),
                              rightWidget: Obx(
                                () => controller.notificationLastInfo.value !=
                                            null &&
                                        controller.notificationLastInfo.value!
                                                .postCreatorId! >
                                            0
                                    ? Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          CustomAvatar.normal(
                                            controller.notificationLastInfo
                                                .value!.postCreatorId!,
                                            size: 28,
                                          ),
                                          Positioned(
                                            top: objectMgr.loginMgr.isDesktop
                                                ? -6
                                                : -2,
                                            right: -1,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        clipBehavior: Clip.hardEdge,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: boxDecoration,
                        child: Column(
                          children: <Widget>[
                            /// 视频号
                            if (controller.showReel.value ||
                                Config().enableReel)
                              SettingItem(
                                onTap: () => controller.onSettingOptionTap(
                                    context, SettingOption.channel.type),
                                iconName: 'setting_reel',
                                title: localized(channel),
                              ),

                            /// 扫一扫
                            SettingItem(
                              onTap: () => controller.onSettingOptionTap(
                                  context, SettingOption.scan.type),
                              iconName: 'im_scan',
                              title: localized(scanTitle),
                              withBorder: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
              Obx(() {
                double spaceHeight =
                    constraints.maxHeight - 44 * 2 - 24 * 2 - 3;
                if (controller.showReel.value || Config().enableReel) {
                  spaceHeight = spaceHeight - 44;
                }
                return SizedBox(
                  height: spaceHeight,
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
