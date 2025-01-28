import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_source_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/views/message/chat/group/item/chat_my_sendstate_item.dart';
import 'package:jxim_client/im/model/emoji_model.dart';

import '../../../main.dart';
import '../../../managers/chat_mgr.dart';
import '../../../utils/color.dart';
import 'emoji_list_item.dart';

class GroupVideoAttachmentMeItem extends StatefulWidget {
  const GroupVideoAttachmentMeItem({
    Key? key,
    required this.messageVideo,
    required this.message,
    required this.chat,
    required this.index,
    this.isPrevious = true,
  }) : super(key: key);
  final MessageVideo messageVideo;
  final Chat chat;
  final Message message;
  final int index;
  final bool isPrevious;

  @override
  _GroupVideoAttachmentMeItemState createState() =>
      _GroupVideoAttachmentMeItemState();
}

class _GroupVideoAttachmentMeItemState extends State<GroupVideoAttachmentMeItem>
    with MessageWidgetMixin {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final emojiUserList = <EmojiModel>[].obs;

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());

    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);

    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, onChatMessageEdit);
    emojiUserList.value = widget.message.emojis;
  }

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

  _onReactEmojiUpdate(Object sender, Object type, Object? data) async {
    if (data is Message) {
      if (widget.message.chat_id == data.chat_id &&
          data.id == widget.message.id) {
        emojiUserList.value = data.emojis;
        emojiUserList.refresh();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);

    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, onChatMessageEdit);
  }

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => isExpired.value || isDeleted.value
          ? const SizedBox()
          : Stack(
              children: [
                // ChatPopAnimationWidget(
                //   key: targetWidgetKey,
                //   chat: widget.chat,
                //   actions: [
                //     ChatPopMenuSheet(
                //       message: widget.message,
                //       chat: widget.chat,
                //       sendID: widget.message.send_id,
                //     ),
                //   ],
                //   topWidget: EmojiSelector(
                //     chat: widget.chat,
                //     message: widget.message,
                //     emojiMapList: emojiUserList,
                //   ),
                //   isSender: true,
                //   targetWidget: Container(
                //     width: double.infinity,
                //     child: Container(
                //       margin: EdgeInsets.only(
                //         right: 17.0,
                //         top: isPinnedOpen ? 4.0 : 2.0,
                //         bottom: isPinnedOpen ? 4.0 : 2.0,
                //       ),
                //       alignment: Alignment.centerRight,
                //       constraints: BoxConstraints(
                //         maxWidth: (ObjectMgr.screenMQ!.size.width * 0.8) +
                //             (widget.message.isSendOk ? 30 : 0),
                //       ),
                //       child: messageBody(context),
                //     ),
                //   ),
                //   targetWidgetGlobalKey: targetWidgetKey,
                // ),
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

  Widget messageBody(BuildContext context) {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              constraints: jxDimension.videoAttachmentMeConstraint(),
              padding: jxDimension.videoAttachmentMePadding(),
              child: Stack(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: _buildContentList(),
                  ),
                  if (widget.messageVideo.forward_user_id != 0)
                    ChatSourceView(
                      forward_user_id: widget.messageVideo.forward_user_id,
                      maxWidth: jxDimension.groupTextMeMaxWidth(),
                      isSender: false,
                    ),
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

                          sender: false,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        /// react emoji 表情栏
        Obx(() {
          List<Map<String, int>> emojiCountList = [];
          emojiUserList.forEach((emoji) {
            final emojiCountMap = {
              MessageReactEmoji.emojiNameOldToNew(emoji.emoji):
                  emoji.uidList.length,
            };
            emojiCountList.add(emojiCountMap);
          });

          return Visibility(
            visible: emojiUserList.length > 0,
            child: Positioned(
              left: 50.0,
              bottom: 6.0,
              child: GestureDetector(
                onTap: () => controller.onViewReactList(context, emojiUserList),
                child: EmojiListItem(
                  emojiModelList: emojiUserList,
                  message: widget.message,
                  controller: controller,
                ),
              ),
            ),
          );
        })
      ],
    );
  }

  List<Widget> _buildContentList() {
    List<Widget> _list = [];

    if (!widget.message.isSendOk) {
      _list.add(
        ChatMySendStateItem(
          key: ValueKey(widget.message),
          message: widget.message,
          showLoading: false,
        ),
      );
      _list.add(const SizedBox(width: 5.0));
    }
    _list.add(_buildText());
    return _list;
  }

  Widget _buildText() {
    return Container(
      width: 200,
      height: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(100),
      ),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(300.0),
        child: Stack(
          children: [
            // VideoDetail(
            //   asset: widget.message.asset != null
            //       ? widget.message.asset!
            //       : widget.messageVideo.url,
            // ),
          ],
        ),
      ),
    );
  }
}
