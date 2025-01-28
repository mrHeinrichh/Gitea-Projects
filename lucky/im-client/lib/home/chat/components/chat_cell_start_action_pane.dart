import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class ChatCellStartActionPane extends GetView<ChatListController> {
  final Chat chat;

  const ChatCellStartActionPane({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return CustomSlidableAction(
      onPressed: (context) => controller.onPinnedChat(context, chat),
      backgroundColor: JXColors.green,
      foregroundColor: JXColors.cIconPrimaryColor,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            chat.sort != 0
                ? 'assets/svgs/unpin_icon.svg'
                : 'assets/svgs/pin2_icon.svg',
            width: 40,
            height: 40,
            fit: BoxFit.fill,
          ),
          const SizedBox(height: 4.0),
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
