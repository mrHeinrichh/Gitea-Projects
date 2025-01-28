import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/home/chat/components/chat_cell_action_animation_icon.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:lottie/lottie.dart';

class ChatCellMuteActionPane extends StatefulWidget {
  final Chat chat;
  final AnimationController? drawerController;

  const ChatCellMuteActionPane({
    super.key,
    required this.chat,
    this.drawerController,
  });

  @override
  State<StatefulWidget> createState() => ChatCellMuteActionPaneState();
}

class ChatCellMuteActionPaneState extends State<ChatCellMuteActionPane> {
  final isMuted = false.obs;
  User? user;
  RxBool ableMute = true.obs;

  @override
  void initState() {
    super.initState();
    objectMgr.chatMgr.on(ChatMgr.eventChatMuteChanged, _onMuteChanged);
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    isMuted.value = widget.chat.isMute;

    if (widget.chat.typ == chatTypeSingle) {
      user = objectMgr.userMgr.getUserById(widget.chat.friend_id);
      ableMute.value =
          (user?.relationship != Relationship.friend) ? false : true;
    }
  }

  void _onMuteChanged(Object sender, Object type, Object? data) {
    if (data is Chat && widget.chat.id == data.id) {
      bool muted = widget.chat.isMute;
      if (isMuted.value != muted) {
        isMuted.value = muted;
      }
    }
  }

  void _onUserUpdate(Object sender, Object type, Object? data) {
    if (data is User && data.id == user?.uid) {
      User newUser = data;
      ableMute.value =
          (newUser.relationship != Relationship.friend) ? false : true;
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventChatMuteChanged, _onMuteChanged);
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => CustomSlidableAction(
        onPressed: (context) {
          if (ableMute.value) {
            objectMgr.chatMgr.onChatMute(
              widget.chat,
              expireTime: isMuted.value ? 0 : -1,
            );
          }
        },
        backgroundColor:
            ableMute.value ? colorOrange : colorOrange.withOpacity(0.5),
        foregroundColor: colorWhite,
        padding: EdgeInsets.zero,
        flex: 7,
        child: Obx(
          () {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!objectMgr.loginMgr.isDesktop &&
                    widget.drawerController != null)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Lottie.asset(
                      isMuted.value
                          ? 'assets/lottie/chat_slidable_speake_mute.json'
                          : 'assets/lottie/chat_slidable_speaker.json',
                      controller: widget.drawerController,
                    ),
                  )
                else
                  ChatCellActionAnimationIcon(
                    chatID: widget.chat.id.toString(),
                    path: isMuted.value
                        ? 'assets/lottie/chat_slidable_speake_mute.json'
                        : 'assets/lottie/chat_slidable_speaker.json',
                    width: 40,
                    height: 40,
                  ),
                Text(
                  isMuted.value ? localized(unmute) : localized(mute),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: jxTextStyle.slidableTextStyle(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
