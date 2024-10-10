import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/setting/notification/notification_controller.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

import 'package:jxim_client/home/setting/setting_item.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:get/get.dart';

class NotificationTypeView extends GetView<NotificationController> {
  const NotificationTypeView({super.key});

  Widget createItem(listItem, index) {
    pdebug(listItem.isSelected);
    return SettingItem(
      onTap: () {
        pdebug(index);
        controller.changeNotificationMode(
          getMode(controller.notificationTypeList[index].value!),
        );
        controller.isSelectNotifyTypeIndex.value = index;
      },
      title: listItem.title,
      withArrow: false,
      withEffect: true,
      withBorder:
          listItem == controller.notificationTypeList.last ? false : true,
      rightWidget: Obx(
        () => Visibility(
          visible: controller.isSelectNotifyTypeIndex.value == index,
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
    for (int index = 0;
        index < controller.notificationTypeList.length;
        index++) {
      var item = controller.notificationTypeList[index];
      item.isSelected = false;
      if (item.value == controller.getNotificationMode().value) {
        item.isSelected = true;
        controller.isSelectNotifyTypeIndex.value = index;
      }
    }

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: PrimaryAppBar(
        bgColor: Colors.transparent,
        title: localized(notificationType),
        onPressedBackBtn:
            objectMgr.loginMgr.isDesktop ? () => Get.back(id: 3) : null,
      ),
      body: Padding(
        padding: objectMgr.loginMgr.isDesktop
            ? const EdgeInsets.all(16)
            : const EdgeInsets.all(16).w,
        child: ClipRRect(
          borderRadius: objectMgr.loginMgr.isDesktop
              ? BorderRadius.circular(8)
              : BorderRadius.circular(8).w,
          child: Container(
            color: Colors.white,
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: controller.notificationTypeList.length,
              itemBuilder: (BuildContext context, int index) {
                var notificationType = controller.notificationTypeList[index];
                return createItem(notificationType, index);
              },
            ),
          ),
        ),
      ),
    );
  }
}
