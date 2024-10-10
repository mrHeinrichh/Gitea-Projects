import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/privacy_security_controller.dart';

class MomentPrivacyAvailableDaysView
    extends GetView<PrivacySecurityController> {
  const MomentPrivacyAvailableDaysView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(momentPrivacyAvailableDaysTitle),
        onPressedBackBtn:
            objectMgr.loginMgr.isDesktop ? () => Get.back(id: 3) : null,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: colorWhite,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: controller.momentSelectionOptionModelList.length,
          itemBuilder: (BuildContext context, int index) {
            final listItem = controller.momentSelectionOptionModelList[index];

            return SettingItem(
              onTap: () => controller.onMomentAvailableDaysUpdate(index),
              title: listItem.title,
              withArrow: false,
              withEffect: true,
              withBorder:
                  index == controller.momentSelectionOptionModelList.length - 1
                      ? false
                      : true,
              rightWidget: Obx(
                () => Visibility(
                  visible: controller.momentSelectionIdx.value == index,
                  child: SvgPicture.asset(
                    'assets/svgs/check.svg',
                    width: 16,
                    height: 16,
                    colorFilter:
                        ColorFilter.mode(themeColor, BlendMode.srcATop),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
