import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/views/component/new_appbar.dart';

import '../../home/setting/setting_item.dart';
import '../../main.dart';
import '../../utils/color.dart';
import '../../utils/lang_util.dart';
import '../../utils/localization/app_localizations.dart';
import 'notification_controller.dart';
import 'package:get/get.dart';

class NotificationTypeView extends GetView<NotificationController> {
  const NotificationTypeView({Key? key}) : super(key: key);

  Widget createItem(listItem, index) {
    pdebug(listItem.isSelected);
    return SettingItem(
      onTap: () {
        pdebug(index);
        controller.changeNotificationMode(
            controller.notificationTypeList[index].value!.toMode);
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
            colorFilter: ColorFilter.mode(accentColor, BlendMode.srcATop),
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
      backgroundColor: backgroundColor,
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
          )),
    );
  }
}
