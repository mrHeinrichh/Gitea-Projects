

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/object/message/share_image.dart';
import 'package:jxim_client/views/message/share/new_share_chat_controller.dart';
import 'package:jxim_client/views/message/share/share_chat_container.dart';


extension ShareHomeExtension on  HomeController{

  /// 长按转发选项
  Future<void> onForwardMessage({
    bool fromChatInfo = false,
    bool fromMediaDetail = false,
    ShareImage? shareImage,
  }) async {
    if (!Get.isRegistered<NewShareChatController>()) {
        Get.put(NewShareChatController());
    }
    try {
       await showModalBottomSheet(
        context: Get.context!,
        isDismissible: false,
        isScrollControlled: true,
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
              );
            },
          );
        },
      );
       Get.delete<NewShareChatController>();
    }catch(e){
      // pdebug("kkkkkkk ====> $e");
    }

  }

}
