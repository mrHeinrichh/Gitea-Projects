import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/special_container/special_container_util.dart';
import 'package:jxim_client/views/component/floating/manager/floating_manager.dart';

final overlayY = 0.0.obs;

class SpecialContainerOverlay {
  static OverlayEntry? overlayEntry;
  static OverlayEntry? overlayEntryNotify;

  static void addSpecialContainerOverlay({
    required SpecialContainerType type,
    required Widget child,
  }) {
    if (Get.overlayContext == null ||
        Get.context == null ||
        Get.overlayContext == null) {
      return;
    }
    if (overlayEntry != null) {
      return;
    }

    overlayEntry = OverlayEntry(builder: (context) {
      return Obx(() {
        final olWidth = MediaQuery.of(Get.context!).size.width;
        var olHeight = MediaQuery.of(Get.context!).size.height;
        if (type == SpecialContainerType.fix) {
          olHeight = kSheetHeightFix;
        }
        if (scStatus.value == SpecialContainerStatus.max.index) {
          overlayY.value = 0.0;
        } else if (scStatus.value == SpecialContainerStatus.min.index) {
          overlayY.value = -2000.0;
        }
        return AnimatedPositioned(
          duration: kAnimationTime,
          bottom: overlayY.value,
          width: olWidth,
          height: olHeight,
          child: child,
        );
      });
    });

    if (overlayEntry != null && navigatorKey.currentState != null) {
      var overlayCall =
          floatingManager.getFloating('call_floating')?.overlayEntry;
      Overlay.of(Get.overlayContext!).insert(overlayEntry!, below: overlayCall);

      List<OverlayEntry> entriesList = [];
      if (overlayCall != null) {
        entriesList.add(overlayCall);
      }
      if (overlayEntryNotify != null) {
        entriesList.add(overlayEntryNotify!);
      }
      if (entriesList.isNotEmpty) {
        Overlay.of(Get.overlayContext!)
            .rearrange(entriesList, above: overlayEntry);
      }
    }
  }

  /*
  * 最小化
  * */
  static void minOverlay() {
    // overlayY.value = -2000.0;
    scStatus.value = SpecialContainerStatus.min.index;
    objectMgr.miniAppMgr.onRestore();
    ChatListController.setStatusBarStyleInIOS(false,milliseconds: 400);
    ChatListController? controller;
    try {
      controller = Get.find<ChatListController>();
    } catch (e) {
      // 打印日志或者处理异常
      debugPrint('ChatListController not found: $e');
    }
    if (controller != null) {
      if (controller.isShowingApplet.value) {
        controller.backToMainPageState();
      }
    }
  }

  /*
  * 关闭
  * */
  static void closeOverlay() {
    scStatus.value = SpecialContainerStatus.none.index;
    overlayEntry?.remove();
    overlayEntry = null;
    ChatListController? controller;
    try {
      controller = Get.find<ChatListController>();
    } catch (e) {
      // 打印日志或者处理异常
      debugPrint('ChatListController not found: $e');
    }
    if (controller != null) {
      if (controller.isShowingApplet.value) {
        controller.backToMiniAppPageState();
      }
    }
  }

  /*
  * 最大化
  * */
  static void showOverlayMax({
    SpecialContainerType type = SpecialContainerType.fix,
  }) {
    scType.value = type.index;
    scStatus.value = SpecialContainerStatus.max.index;
    ChatListController.setStatusBarStyleInIOS(false,milliseconds: 400);
  }

  /*
  * 偏差距离
  * */
  static double getOverlayDiffHeight() {
    double diffHeight = 0.0;
    if (scStatus.value == SpecialContainerStatus.min.index) {
      diffHeight = kSheetHeightMin;
    }
    return diffHeight;
  }
}
