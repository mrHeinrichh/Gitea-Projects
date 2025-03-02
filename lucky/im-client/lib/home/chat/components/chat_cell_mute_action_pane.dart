import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import '../../../main.dart';
import '../../../managers/chat_mgr.dart';
import '../../../object/chat/chat.dart';
import '../../../utils/color.dart';
import '../../../utils/lang_util.dart';
import '../../../utils/localization/app_localizations.dart';
import '../../../utils/theme/text_styles.dart';

class ChatCellMuteActionPane extends StatefulWidget {
  final Chat chat;

  const ChatCellMuteActionPane({super.key, required this.chat});

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
    super.dispose();
    objectMgr.chatMgr.off(ChatMgr.eventChatMuteChanged, _onMuteChanged);
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
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
            ableMute.value ? JXColors.orange : JXColors.orange.withOpacity(0.5),
        foregroundColor: JXColors.cIconPrimaryColor,
        padding: EdgeInsets.zero,
        flex: 7,
        child: Obx(
          () {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  isMuted.value
                      ? 'assets/svgs/volume_up_icon.svg'
                      : 'assets/svgs/volume_mute_icon.svg',
                  width: 40.w,
                  height: 40.w,
                  fit: BoxFit.fill,
                ),
                SizedBox(height: 4.w),
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
