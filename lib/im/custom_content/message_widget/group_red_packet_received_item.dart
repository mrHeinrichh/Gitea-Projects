import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class GroupRedPacketReceivedItem extends StatefulWidget {
  final Message message;
  final MessageRed messageRed;
  final Chat chat;
  final int index;
  final bool isPrevious;

  const GroupRedPacketReceivedItem({
    super.key,
    required this.message,
    required this.messageRed,
    required this.chat,
    required this.index,
    this.isPrevious = true,
  });

  @override
  State<GroupRedPacketReceivedItem> createState() =>
      _GroupRedPacketReceivedItemState();
}

class _GroupRedPacketReceivedItemState extends State<GroupRedPacketReceivedItem>
    with MessageWidgetMixin {
  late ChatContentController controller;

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
  }

  void _onAutoDeleteMsgTriggered(Object sender, Object type, Object? data) {
    if (data is Message) {
      if (widget.message.message_id == data.message_id) {
        controller.chatController.removeUnreadBar();
        checkDateMessage(data);
        isExpired.value = true;
      }
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messageRed.userId != objectMgr.userMgr.mainUser.uid &&
        widget.messageRed.senderUid != objectMgr.userMgr.mainUser.uid) {
      return const SizedBox();
    }

    /// 我领取别人的红包
    bool receiveRedPacket =
        widget.messageRed.userId == objectMgr.userMgr.mainUser.uid;

    /// 别人领取我的红包
    bool mySendRedPacket =
        widget.messageRed.senderUid == objectMgr.userMgr.mainUser.uid;

    String content = "";

    if (mySendRedPacket && receiveRedPacket) {
      content = localized(youHaveReceivedYourRedPacket);
    } else {
      int? groupId;
      if (widget.chat.isGroup) {
        groupId = widget.chat.chat_id;
      }
      if (receiveRedPacket) {
        User? data = objectMgr.userMgr.getUserById(widget.messageRed.senderUid);
        String alias = objectMgr.userMgr.getUserTitle(data, groupId: groupId);
        content = localized(youHaveReceivedParamRedPacket, params: [alias]);
      } else if (mySendRedPacket) {
        User? data = objectMgr.userMgr.getUserById(widget.messageRed.userId);
        String alias = objectMgr.userMgr.getUserTitle(data, groupId: groupId);
        content = localized(hasReceivedYourRedPacket, params: [alias]);
      }
    }

    return Obx(
      () => isExpired.value
          ? const SizedBox()
          : Align(
              alignment: Alignment.center,
              child: Container(
                margin: jxDimension.systemMessageMargin(context),
                padding: jxDimension.systemMessagePadding(),
                decoration: const ShapeDecoration(
                  color: colorTextSupporting,
                  shape: StadiumBorder(),
                ),
                child: Text(
                  content,
                  style: jxTextStyle.textStyle12(color: colorWhite),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}
