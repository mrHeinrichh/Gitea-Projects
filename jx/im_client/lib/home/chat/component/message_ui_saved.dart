// 文本消息模型

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/home/chat/component/message_ui_component.dart';
import 'package:jxim_client/utils/im_toast/im_gap.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';

class MessageUISaved extends MessageUIComponent {
  const MessageUISaved({
    super.key,
    required super.chat,
    required super.searchText,
    required super.message,
  });

  @override
  Widget buildHeadView(BuildContext context) {
    return SavedMessageIcon(
      size: jxDimension.chatListAvatarSize(),
    );
  }

  @override
  Widget buildNameView(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          localized(homeSavedMessage),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: jxTextStyle.headerText(
            fontWeight: MFontWeight.bold5.value,
          ),
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
    );
  }
}
