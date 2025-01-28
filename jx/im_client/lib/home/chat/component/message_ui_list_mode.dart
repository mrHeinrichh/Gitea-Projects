import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/home/chat/component/message_ui_component.dart';
import 'package:jxim_client/home/chat/components/chat_cell_content_factory.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/secretary_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/system_message_icon.dart';

class MessageUIListMode extends MessageUIComponent {
  const MessageUIListMode({
    super.key,
    required super.chat,
    required super.searchText,
    required super.message,
  });

  @override
  Widget buildHeadView(BuildContext context) {
    Widget avatarIcon = const SizedBox();
    if (message.send_id != 0) {
      User? user = objectMgr.userMgr.getUserById(message.send_id);
      if (user != null) {
        avatarIcon = CustomAvatar.user(
          user,
          size: jxDimension.chatListAvatarSize(),
          headMin: Config().headMin,
          fontSize: 24.0,
          // onTap: onTap,
        );
      }
    } else {
      if (chat.isSpecialChat) {
        if (chat.isSystem) {
          avatarIcon = SystemMessageIcon(
            size: jxDimension.chatListAvatarSize(),
          );
        } else if (chat.isSaveMsg) {
          avatarIcon = SavedMessageIcon(
            size: jxDimension.chatListAvatarSize(),
          );
        } else {
          avatarIcon = SecretaryMessageIcon(
            size: jxDimension.chatListAvatarSize(),
          );
        }
      }
    }
    return avatarIcon;
  }

  @override
  Widget buildNameView(BuildContext context) {
    String name = '';
    if (message.send_id == 0) {
      if (chat.isSecretary) {
        name = localized(chatSecretary);
      } else if (chat.isSystem) {
        name = localized(chatSystem);
      } else if (chat.isSaveMsg) {
        name = localized(homeSavedMessage);
      }
    }

    return Row(
      children: <Widget>[
        Flexible(
          child: name.isNotEmpty
              ? Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: MFontWeight.bold5.value,
                    fontSize: MFontSize.size17.value,
                    decoration: TextDecoration.none,
                    fontFamily: appFontfamily,
                    letterSpacing: 0,
                  ),
                )
              : NicknameText(
                  uid: message.send_id,
                  isGroup: false,
                  fontSize: MFontSize.size16.value,
                  fontWeight: MFontWeight.bold5.value,
                  isTappable: false,
                  overflow: TextOverflow.ellipsis,
                  fontSpace: 0,
                ),
        ),
        if (message.send_id == 0 && chat.isSpecialChat)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: SvgPicture.asset(
              'assets/svgs/secretary_check_icon.svg',
              width: 16,
              height: 16,
              color: themeColor,
              fit: BoxFit.fitWidth,
            ),
          ),
      ],
    );
  }

  @override
  Widget buildContentView(BuildContext context) {
    return ChatCellContentFactory.createComponent(
      chat: chat,
      lastMessage: message,
      messageSendState: message.sendState,
      searchText: searchText ?? '',
      displayNickname: false,
    );
  }
}
