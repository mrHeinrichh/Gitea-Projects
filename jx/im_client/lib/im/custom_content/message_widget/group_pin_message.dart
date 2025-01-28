import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';

class GroupPinMessage extends StatefulWidget {
  final Message message;
  final MessagePin messagePin;
  final Chat chat;
  final int index;
  final bool isPrevious;

  const GroupPinMessage({
    super.key,
    required this.message,
    required this.messagePin,
    required this.chat,
    required this.index,
    required this.isPrevious,
  });

  @override
  State<GroupPinMessage> createState() => _GroupPinMessageState();
}

class _GroupPinMessageState extends MessageWidgetMixin<GroupPinMessage> {
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
    bool firstNameIsMe = objectMgr.userMgr.isMe(widget.messagePin.sendId);
    int? groupId;
    if (widget.chat.isGroup) {
      groupId = widget.chat.chat_id;
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
                  shape: StadiumBorder(),
                  color: colorTextSupporting,
                ),
                child: Text(
                  '${firstNameIsMe ? localized(chatInfoYou) : objectMgr.userMgr.getUserTitle(objectMgr.userMgr.getUserById(widget.messagePin.sendId), groupId: groupId)} ${getMessageContent(widget.messagePin)}',
                  style: jxTextStyle.textStyle12(
                    color: colorWhite,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }

  String getMessageContent(MessagePin messagePin) {
    if (objectMgr.userMgr.isMe(messagePin.sendId)) {
      return "${localized(messagePin.isPin == 1 ? havePinParamMessage : haveUnpinParamMessage, params: [
            '${messagePin.messageIds.length}'
          ])}${messagePin.messageIds.length > 1 ? localized(messages) : localized(messageText)}";
    } else {
      return "${localized(messagePin.isPin == 1 ? hasPinParamMessage : hasUnpinParamMessage, params: [
            '${messagePin.messageIds.length}'
          ])}${messagePin.messageIds.length > 1 ? localized(messages) : localized(messageText)}";
    }
  }
}
