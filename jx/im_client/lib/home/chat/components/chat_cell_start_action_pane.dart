import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/components/chat_cell_action_animation_icon.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class ChatCellStartActionPane extends GetView<ChatListController> {
  final Chat chat;

  const ChatCellStartActionPane({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return CustomSlidableAction(
      onPressed: (context) => controller.onPinnedChat(context, chat),
      backgroundColor: colorGreen,
      foregroundColor: colorWhite,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChatCellActionAnimationIcon(
            chatID: chat.id.toString(),
            path: chat.sort != 0
                ? 'assets/lottie/chat_slidable_unpin.json'
                : 'assets/lottie/chat_slidable_pin.json',
            width: 40,
            height: 40,
          ),
          Text(
            chat.sort != 0 ? localized(chatUnpin) : localized(chatPin),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: jxTextStyle.slidableTextStyle(),
          ),
        ],
      ),
    );
  }
}
