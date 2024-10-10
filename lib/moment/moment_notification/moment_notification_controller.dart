import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/moment/index.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';

class MomentNotificationController extends GetxController {
  RxList<MomentDetailUpdate> notificationList = <MomentDetailUpdate>[].obs;

  RxBool hasMore = true.obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (objectMgr.momentMgr.notificationList.isNotEmpty) {
      notificationList
          .assignAll(List.from(objectMgr.momentMgr.notificationList));
      // 调用notification update
      _updateLastReadNotification();
    } else {
      onLoadMore();
    }
  }

  void onLoadMore() async {
    if (!hasMore.value || isLoading.value) return;

    isLoading.value = true;

    final res = await objectMgr.momentMgr.getNotificationList(
      startIdx: notificationList.isEmpty ? 0 : notificationList.last.id!,
      limit: 50,
    );

    isLoading.value = false;
    if (res.notifications == null ||
        res.notifications!.isEmpty ||
        res.notifications!.length < 10) {
      hasMore.value = false;
    }

    notificationList.addAll(res.notifications ?? []);
  }

  void _updateLastReadNotification() async {
    if (notificationList.isEmpty) return;

    await objectMgr.momentMgr.updateLastReadNotification(
      notificationId: notificationList.first.id!,
    );
    objectMgr.momentMgr.clearNotificationList();
  }

  void onClearNotification(BuildContext context) async {
    if (notificationList.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return CustomConfirmationPopup(
          withHeader: false,
          cancelButtonColor: themeColor,
          cancelButtonText: localized(cancel),
          cancelCallback: Navigator.of(context).pop,
          confirmButtonText: localized(momentClearAllNotificationTitle),
          confirmButtonColor: colorRed,
          confirmCallback: () => onClearNotificationCallback(context),
        );
      },
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

        // ignore: use_build_context_synchronously
        // ImBottomToast(
        //   context,
        //   title: localized(toastClearSuccess),
        //   icon: ImBottomNotifType.success,
        // );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
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
