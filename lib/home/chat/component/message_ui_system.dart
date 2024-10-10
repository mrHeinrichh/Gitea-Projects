// 文本消息模型

import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/home/chat/component/message_ui_component.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/system_message_icon.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';

class MessageUISystem extends MessageUIComponent {
  MessageUISystem(
      {super.key,
      required super.chat,
      required super.searchText,
      required super.message});

  @override
  Widget buildHeadView(BuildContext context) {
    return SystemMessageIcon(
      size: jxDimension.chatListAvatarSize(),
    );
  }

  @override
  Widget titleBuilder() {
    final bool isDesktop = objectMgr.loginMgr.isDesktop;
    final TextStyle textStyle = TextStyle(
      fontSize: jxTextStyle.chatCellNameSize(),
      color: isDesktop ? colorTextPrimary : null,
      fontWeight: isDesktop ? MFontWeight.bold4.value : MFontWeight.bold5.value,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: [
                Text(
                  localized(homeSystemMessage),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle.useSystemChineseFont(),
                ),
                ImGap.hGap4,
                SvgPicture.asset(
                  'assets/svgs/secretary_check_icon.svg',
                  width: 15,
                  height: 15,
                  color: themeColor,
                  fit: BoxFit.fitWidth,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              // ChatCellTimeText(chat: chat!),
              messageCellTime(message),
            ],
          )
        ],
      ),
    );
  }
}