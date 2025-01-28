import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jxim_client/managers/group_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:get/get.dart';

class ChatCellSettingView extends StatefulWidget {
  final Chat chat;
  final int index;

  const ChatCellSettingView({
    super.key,
    required this.chat,
    required this.index,
  });

  @override
  State<StatefulWidget> createState() => ChatCellSettingViewState();
}

class ChatCellSettingViewState extends State<ChatCellSettingView> {
  bool isMuted = false;

  ChatListController get controller => Get.find<ChatListController>();

  RxBool isGroupExpireSoon = false.obs;

  @override
  void initState() {
    super.initState();
    objectMgr.chatMgr.on(ChatMgr.eventChatMuteChanged, _onMuteChanged);
    objectMgr.myGroupMgr
        .on(MyGroupMgr.eventTmpGroupLessThanADay, _onGroupIsExpired);
    isMuted = widget.chat.isMute;
  }

  void _onMuteChanged(Object sender, Object type, Object? data) {
    if (data is Chat && widget.chat.id == data.id) {
      bool muted = widget.chat.isMute;
      if (isMuted != muted) {
        setState(() {
          isMuted = muted;
        });
      }
    }
  }

  void _onGroupIsExpired(_, __, Object? data) {
    if (data != null && data is Map<String, dynamic>) {
      if (data['id'] == widget.chat.id) {
        isGroupExpireSoon.value = data['isExpiring'];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = objectMgr.loginMgr.isDesktop;

    final TextStyle textStyle = TextStyle(
      fontWeight: MFontWeight.bold5.value,
      fontSize: objectMgr.loginMgr.isDesktop
          ? MFontSize.size14.value
          : MFontSize.size16.value,
      color: (isDesktop && controller.selectedCellIndex.value == widget.index)
          ? Colors.white
          : colorTextPrimary,
      decoration: TextDecoration.none,
      fontFamily: appFontfamily,
      letterSpacing: 0,
    );

    return Padding(
      padding: jxDimension.chatCellTitlePadding().copyWith(
            top: 2.0,
          ),
      child: Row(
        children: [
          widget.chat.typ == chatTypeSmallSecretary
              ? Text(
                  localized(chatSecretary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                )
              : Flexible(
                  child: widget.chat.typ == chatTypeSmallSecretary
                      ? Text(
                          localized(chatSecretary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle,
                        )
                      : widget.chat.isSystem
                          ? Text(
                              localized(chatSystem),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle,
                            )
                          : widget.chat.isSaveMsg
                              ? Text(
                                  localized(homeSavedMessage),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textStyle,
                                )
                              : NicknameText(
                                  uid: widget.chat.typ == chatTypeSingle
                                      ? widget.chat.friend_id
                                      : widget.chat.id,
                                  //必须获取用户的名字，不是chat的名字
                                  displayName: widget.chat.name,
                                  isGroup: widget.chat.isGroup || widget.chat.isChatTypeMiniApp,
                                  fontSize: objectMgr.loginMgr.isDesktop
                                      ? MFontSize.size14.value
                                      : MFontSize.size16.value,
                                  fontWeight: MFontWeight.bold5.value,
                                  color: (isDesktop &&
                                          controller.selectedCellIndex.value ==
                                              widget.index)
                                      ? Colors.white
                                      : colorTextPrimary,
                                  isTappable: false,
                                  overflow: TextOverflow.ellipsis,
                                  fontSpace: 0,
                                ),
                ),
          if (widget.chat.typ == chatTypeSmallSecretary)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: SvgPicture.asset(
                'assets/svgs/secretary_check_icon.svg',
                width: 16,
                height: 16,
                color:
                    controller.desktopSelectedChatID.value == widget.chat.id &&
                            isDesktop
                        ? colorWhite
                        : themeColor,
                fit: BoxFit.fitWidth,
              ),
            ),
          if (widget.chat.isTmpGroup)
            Padding(
              padding: const EdgeInsets.only(left: 2.0),
              child: SvgPicture.asset(
                'assets/svgs/temporary_indicator.svg',
                width: 16,
                height: 16,
                fit: BoxFit.fill,
                color: isGroupExpireSoon.value ? colorRed : themeColor,
              ),
            ),
          if (isMuted)
            Padding(
              padding: const EdgeInsets.only(left: 3.0),
              child: SvgPicture.asset(
                'assets/svgs/mute_icon3.svg',
                width: 16,
                height: 16,
                color:
                    controller.desktopSelectedChatID.value == widget.chat.id &&
                            objectMgr.loginMgr.isDesktop
                        ? colorWhite
                        : null,
                fit: BoxFit.fill,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventChatMuteChanged, _onMuteChanged);
    objectMgr.myGroupMgr
        .off(MyGroupMgr.eventTmpGroupLessThanADay, _onGroupIsExpired);
    super.dispose();
  }
}
