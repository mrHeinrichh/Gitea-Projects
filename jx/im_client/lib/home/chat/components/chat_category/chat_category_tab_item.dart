import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/im/services/animated_flip_counter.dart';
import 'package:jxim_client/object/chat/chat_category.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class ChatCategoryTabItem extends StatelessWidget {
  final ChatListController controller;
  final ChatCategory category;
  final bool isOverlay;

  const ChatCategoryTabItem({
    super.key,
    required this.category,
    required this.controller,
    this.isOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          category.isAllChatRoom
              ? localized(chatCategoryAllChatRoom)
              : category.name,
          overflow: TextOverflow.ellipsis,
          style:
              isOverlay ? jxTextStyle.textStyleBold14(color: themeColor) : null,
        ),
        GetBuilder<ChatListController>(
          id: 'chat_category',
          builder: (_) {
            if (controller.chatCategoryUnreadCount[category.id] != null &&
                controller.chatCategoryUnreadCount[category.id]!.isNotEmpty) {
              return Container(
                height: 20,
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                constraints: const BoxConstraints(minWidth: 20),
                decoration: BoxDecoration(
                  // color: widget.chat.isMute
                  //     ? colorTextSupporting
                  //     : themeColor,
                  color: themeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: (controller.chatCategoryUnreadCount[category.id]
                                  ?.length ??
                              0) <
                          999
                      ? AnimatedFlipCounter(
                          value: controller
                              .chatCategoryUnreadCount[category.id]!.length,
                          textStyle: jxTextStyle.textStyle13(color: colorWhite),
                        )
                      : Text(
                          '999+',
                          style: jxTextStyle.textStyle14(color: colorWhite),
                        ),
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ],
    );
  }
}
