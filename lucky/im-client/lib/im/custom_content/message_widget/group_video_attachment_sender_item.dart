import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/im/model/emoji_model.dart';

import '../../../main.dart';
import '../../../managers/chat_mgr.dart';
import '../../../routes.dart';
import '../../../views/component/custom_avatar.dart';

class GroupVideoAttachmentSenderItem extends StatefulWidget {
  const GroupVideoAttachmentSenderItem({
    Key? key,
    required this.index,
    required this.messageVideo,
    required this.chat,
    required this.message,
    this.isPrevious = true,
  }) : super(key: key);
  final int index;
  final MessageVideo messageVideo;
  final Message message;
  final Chat chat;
  final isPrevious;

  @override
  _GroupVideoAttachmentSenderItemState createState() =>
      _GroupVideoAttachmentSenderItemState();
}

class _GroupVideoAttachmentSenderItemState
    extends State<GroupVideoAttachmentSenderItem> with MessageWidgetMixin {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final emojiUserList = <EmojiModel>[].obs;

  int sendID = 0;

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, onChatMessageEdit);
    getRealSendID();
  }

  getRealSendID() {
    sendID = widget.message.send_id;
    if (widget.chat.isSaveMsg) {
      sendID = widget.messageVideo.forward_user_id;
    }
  }

  @override
  void dispose() {
    super.dispose();
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, onChatMessageEdit);
  }

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  onChatMessageDelete(sender, type, data) {
    if (data['id'] != widget.chat.chat_id) {
      return;
    }
    if (data['message'] != null) {
      for (var item in data['message']) {
        if (item is Message) {
          if (item.id == widget.message.id) {
            isDeleted.value = true;
            checkDateMessage(message);
            break;
          }
        } else {
          if (item == widget.message.message_id) {
            isDeleted.value = true;
            checkDateMessage(message);
            break;
          }
        }
      }
    }
  }

  onChatMessageEdit(sender, type, data) {
    if (data['id'] != widget.chat.chat_id) {
      return;
    }
    if (data['message'] != null) {
      Message item = data['message'];
      if (item.id == widget.message.id) {
        widget.message.content = item.content;
        widget.message.edit_time = item.edit_time;
        widget.message.sendState = item.sendState;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => isExpired.value || isDeleted.value
          ? const SizedBox()
          : Stack(
              children: [
                Positioned(
                  top: 0.0,
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  child: MoreChooseView(
                    chatController: controller.chatController,
                    message: widget.message,
                    chat: widget.chat,
                  ),
                ),
              ],
            ),
    );
  }

  Widget messageBody() {
    return Obx(
      () => Container(
        key: targetWidgetKey,
        padding: jxDimension.videoAttachmentSenderPadding(
            controller.chatController.chooseMore.value),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.chat.typ != chatTypeSingle && isLastMessage)
              Padding(
                padding: jxDimension.videoAttachmentSenderAvatarPadding(),
                child: CustomAvatar(
                  uid: sendID,
                  size: jxDimension.videoAttachmentSenderAvatar(),
                  onTap: () {
                    Get.toNamed(
                      RouteName.chatInfo,
                      arguments: {
                        "uid": sendID,
                      },
                    );
                  },
                  onLongPress: () async {
                    User? user = await objectMgr.userMgr.loadUserById2(sendID);
                    if (user != null) {
                      controller.inputController.addMentionUser(user);
                    }
                  },
                ),
              ),
            if (widget.chat.typ != chatTypeSingle && !isLastMessage)
              const SizedBox(width: 40),
            Container(
              width: 200,
              height: 200,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(
                  jxDimension.videoAttachmentBorderRadius(),
                ),
              ),
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(300.0),
                child: Stack(
                  children: [
                    // VideoDetail(asset: widget.messageVideo.url),
                    if (widget.chat.typ != chatTypeSmallSecretary)
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: ChatReadNumView(
                            message: widget.message,
                            chat: widget.chat,
                            showPinned: controller.chatController.pinMessageList
                                    .firstWhereOrNull((pinnedMsg) =>
                                        pinnedMsg.id == widget.message.id) !=
                                null,
                            // color: hexColor(0x363636).withOpacity(0.17),

                            sender: true,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
