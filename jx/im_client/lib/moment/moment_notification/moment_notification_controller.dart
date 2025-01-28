import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/custom_bottom_alert_dialog.dart';

class MomentNotificationController extends GetxController {
  RxList<MomentDetailUpdate> notificationList = <MomentDetailUpdate>[].obs;

  RxBool hasMore = true.obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (objectMgr.momentMgr.notificationStrongDetailList.isNotEmpty) {
      notificationList
          .assignAll(List.from(objectMgr.momentMgr.notificationStrongDetailList));
      // 调用notification update
      _updateLastReadNotification();
    } else {
      onLoadMore(isInit:true);
    }
  }

  void onLoadMore({bool isInit = false}) async {
    isLoading.value = true;

    if(isInit){
      notificationList.assignAll(objectMgr.momentMgr.notificationCacheDetailList);
    }

    final res = await objectMgr.momentMgr.getNotificationList(
      startIdx: notificationList.isEmpty||isInit ? 0 : notificationList.last.id!,
      limit: 50,
    );

    isLoading.value = false;
    if (res.notifications == null ||
        res.notifications!.isEmpty ||
        res.notifications!.length < 10) {
      hasMore.value = false;
    }

    if(isInit){
      notificationList.assignAll(res.notifications ?? []);
    }else{
      notificationList.addAll(res.notifications ?? []);
    }

  }

  void _updateLastReadNotification() async {
    if (notificationList.isEmpty) return;

    objectMgr.momentMgr.updateLastReadNotification(
      notificationId: notificationList.first.id!,
    ).then((value){
      objectMgr.momentMgr.clearNotificationList();
    });
  }

  void onClearNotification(BuildContext context) async {
    if (notificationList.isEmpty) return;

    showCustomBottomAlertDialog(
      context,
      withHeader: false,
      confirmText: localized(momentClearAllNotificationTitle),
      confirmTextColor: colorRed,
      cancelTextColor: themeColor,
      onConfirmListener: () => onClearNotificationCallback(context),
    );
  }

  void onClearNotificationCallback(BuildContext context) async {
    try {
      final status = await objectMgr.momentMgr.updateLastReadNotification(
        notificationId: 0,
        hideNotificationId: notificationList.first.id!,
      );

      if (status) {
        notificationList.clear();
        objectMgr.momentMgr.clearNotificationList();
        hasMore.value = false;

        // ImBottomToast(
        //   context,
        //   title: localized(toastClearSuccess),
        //   icon: ImBottomNotifType.success,
        // );
      }
    } catch (e) {
      // ImBottomToast(
      //   Get.context!,
      //   title: localized(e.toString()),
      //   icon: ImBottomNotifType.error,
      // );
    }
  }

  void enterMomentDetail(
    BuildContext context,
    MomentDetailUpdate notification,
  ) async {
    MomentPosts? momentPost = await objectMgr.momentMgr.getSpecificPost(
      notification.content!.postId!,
    );

    Get.toNamed(
      RouteName.momentDetail,
      arguments: {
        'detail': momentPost,
      },
    );
  }
}
