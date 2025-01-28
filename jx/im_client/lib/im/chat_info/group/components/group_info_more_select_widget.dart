import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/component/custom_divider.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class GroupInfoMoreSelectWidget extends StatelessWidget {
  const GroupInfoMoreSelectWidget({
    super.key,
    required this.controller,
  });

  final GroupChatInfoController controller;

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey();
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          border: customBorder,
        ),
        child: Row(
          children: <Widget>[
            GestureDetector(
              onTap: controller.onMoreCancel,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 13.0,
                  horizontal: 20,
                ),
                child: Icon(
                  Icons.close,
                  color: themeColor,
                ),
              ),
            ),
            Expanded(
              child: Text(
                controller.selectedMessageList.length.toString(),
                style: TextStyle(
                  color: themeColor,
                  fontSize: 18,
                  fontWeight: MFontWeight.bold5.value,
                ),
              ),
            ),
            if (controller.selectedMessageList.length == 1)
              GestureDetector(
                onTap: () {
                  dynamic msg = controller.selectedMessageList.first;
                  if (msg is Message) {
                    controller.onMoreSelectCallback!(msg);
                  } else if (msg is AlbumDetailBean) {
                    controller.onMoreSelectCallback!(msg.currentMessage);
                  } else {
                    throw "不知道的类型数据";
                  }
                },
                behavior: HitTestBehavior.translucent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 13.0,
                    horizontal: 12,
                  ),
                  child: Icon(
                    Icons.image_search_outlined,
                    color: themeColor,
                    size: 24,
                  ),
                ),
              ),
            if (controller.currentTabIndex.value != 3 &&
                controller.currentTabIndex.value != 4 &&
                controller.currentTabIndex.value != 5)
              Obx(() {
                return Visibility(
                  visible: controller.forwardEnable.value,
                  child: GestureDetector(
                    onTap: () => controller.onForwardMessage(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 13.0,
                        horizontal: 12,
                      ),
                      child: Icon(
                        CupertinoIcons.arrowshape_turn_up_right,
                        color: themeColor,
                        size: 24,
                        weight: 10,
                      ),
                    ),
                  ),
                );
              }),
            if (controller.currentTabIndex.value != 3)
              GestureDetector(
                key: key,
                onTap: () => controller.onDeleteMessage(context, key),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 13.0,
                    horizontal: 12,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: colorRed,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
