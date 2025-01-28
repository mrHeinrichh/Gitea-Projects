// 文本消息模型

import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/home/chat/component/message_ui_component.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/saved_message_icon.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class MessageUISaved extends MessageUIComponent {
  MessageUISaved(
      {super.key,
      required super.chat,
      required super.searchText,
      required super.message});

  @override
  Widget buildHeadView(BuildContext context) {
    return SavedMessageIcon(
      size: jxDimension.chatListAvatarSize(),
    );
  }

  @override
  Widget titleBuilder() {
    final bool isDesktop = objectMgr.loginMgr.isDesktop;
    final TextStyle textStyle = TextStyle(
      fontSize: jxTextStyle.chatCellNameSize(),
      color: isDesktop ? JXColors.primaryTextBlack : null,
      fontWeight: isDesktop ? MFontWeight.bold4.value : MFontWeight.bold5.value,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: <Widget>[
          Expanded(
              child: Text(
            chat.name,
            style: textStyle.useSystemChineseFont(),
          )),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              // ChatCellTimeText(chat: chat!),
              messageCellTime(this.message),
            ],
          )
        ],
      ),
    );
  }
}
