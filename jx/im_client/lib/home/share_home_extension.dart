import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/object/message/share_image.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/message/share/new_share_chat_controller.dart';
import 'package:jxim_client/views/message/share/share_chat_container.dart';

extension ShareHomeExtension on HomeController {
  /// 长按转发选项
  Future<void> onForwardMessage({
    bool fromChatInfo = false,
    bool fromMediaDetail = false,
    ShareImage? shareImage,
    bool isHousekeeperShare = false,
  }) async {
    if (!Get.isRegistered<NewShareChatController>()) {
      Get.put(NewShareChatController());
    }
    try {
      await showModalBottomSheet(
        context: Get.context!,
        isDismissible: false,
        isScrollControlled: true,
        barrierColor: colorOverlay40,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          final controller = DraggableScrollableController();
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.65,
            minChildSize: 0.4,
            controller: controller,
            builder: (BuildContext context, ScrollController scrollController) {
              return ShareChatContainer(
                shareImage: shareImage,
                draggableScrollableController: controller,
                scrollController: scrollController,
                isHousekeeperShare:isHousekeeperShare,
              );
            },
          );
        },
      );
    } catch (e) {
      // pdebug("kkkkkkk ====> $e");
    }
  }


  /// 长按转发选项
  Future<void> onForwardMessageOnMiniApp({
    bool fromChatInfo = false,
    bool fromMediaDetail = false,
    ShareImage? shareImage,
    bool isHousekeeperShare = false,
  }) async {
    if (!Get.isRegistered<NewShareChatController>()) {
      Get.put(NewShareChatController());
    }

    final overlay = Overlay.of(Get.context!);
    if (overlay == null) return;

    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        final controller = DraggableScrollableController();
        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                overlayEntry?.remove();
                Get.delete<NewShareChatController>(); // 清理控制器
              },
              child: Container(
                color: colorOverlay40, // 半透明背景
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.65,
                minChildSize: 0.4,
                controller: controller,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Material(
                    color: Colors.transparent,
                    child: ShareChatContainer(
                      shareImage: shareImage,
                      draggableScrollableController: controller,
                      scrollController: scrollController,
                      isHousekeeperShare: isHousekeeperShare,
                      overlayEntry: overlayEntry,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );

    try {
      overlay.insert(overlayEntry); // 插入 Overlay
      await Future.delayed(Duration.zero); // 等待用户交互完成
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

}
