import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/new_appbar.dart';
import 'package:jxim_client/views/privacy_security/privacy_security_controller.dart';

import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';

class PrivacySecuritySettingView extends GetView<PrivacySecurityController> {
  const PrivacySecuritySettingView({super.key});

  Widget createItem(listItem, index) {
    pdebug(listItem.isSelected);
    return SettingItem(
      onTap: () {
        pdebug(index);
        controller.isSelectHandler(index);
        controller.isSelectPrivacySecuritySettingIndex.value = index;
      },
      title: listItem.title,
      withArrow: false,
      withEffect: true,
      withBorder: listItem == controller.getList().last ? false : true,
      rightWidget: Obx(
        () => Visibility(
          visible:
              controller.isSelectPrivacySecuritySettingIndex.value == index,
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

  @override
  Widget build(BuildContext context) {
    controller.initSelected();
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: controller.getTitle(),
        onPressedBackBtn:
            objectMgr.loginMgr.isDesktop ? () => Get.back(id: 3) : null,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: objectMgr.loginMgr.isDesktop ? 10 : 10.w,
                bottom: objectMgr.loginMgr.isDesktop ? 3 : 3.w,
              ),
              child: Text(
                controller.getSubTitle(),
                style: jxTextStyle.textStyle12(color: colorTextSecondary),
              ),
            ),
            ClipRRect(
              borderRadius: objectMgr.loginMgr.isDesktop
                  ? BorderRadius.circular(8)
                  : BorderRadius.circular(8).w,
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: controller.getList().length,
                  itemBuilder: (BuildContext context, int index) {
                    var listItem = controller.getListItem(index);
                    return createItem(listItem, index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
