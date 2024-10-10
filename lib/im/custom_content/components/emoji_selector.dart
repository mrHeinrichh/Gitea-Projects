import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/im/custom_content/components/emoji_panel_container.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';

class EmojiSelector extends StatefulWidget {
  final Chat chat;
  final Message message;
  final RxList<EmojiModel?> emojiMapList;

  const EmojiSelector({
    super.key,
    required this.chat,
    required this.message,
    required this.emojiMapList,
  });

  @override
  State<EmojiSelector> createState() => _EmojiSelectorState();
}

class _EmojiSelectorState extends State<EmojiSelector> {
  List<String> selectedEmojis = [];
  final List<String> reactEmojiOption = [
    /// 目前只保留6个跟之前一一对应
    '👍',
    '😍',
    '❤️',
    '👎',
    '🔥',
    '😁'
  ];
  final isDesktop = objectMgr.loginMgr.isDesktop;

  int activePointer = 0;

  @override
  void initState() {
    super.initState();
    for (var element in widget.emojiMapList) {
      if (element != null &&
          element.uidList.contains(objectMgr.userMgr.mainUser.uid)) {
        selectedEmojis.add(element.emoji);
      }
    }
  }

  onReactEmojiSelect(String e) {
    if (activePointer > 0) return;
    final String emojiName = e.substring(
      e.lastIndexOf('/') + 1,
    );

    activePointer += 1;
    if (selectedEmojis.contains(emojiName)) {
      ChatHelp.sendRemoveReactEmoji(
        chatID: widget.chat.id,
        messageId: widget.message.message_id,
        chatIdx: widget.message.chat_idx,
        recipientId: widget.message.send_id,
        userId: objectMgr.userMgr.mainUser.uid,
        emoji: emojiName,
      );
    } else {
      for (final selectedEmoji in selectedEmojis) {
        String emojiName =
            selectedEmoji.substring(selectedEmoji.lastIndexOf('/') + 1);
        ChatHelp.sendRemoveReactEmoji(
            chatID: widget.chat.id,
            messageId: widget.message.message_id,
            chatIdx: widget.message.chat_idx,
            recipientId: widget.message.send_id,
            userId: objectMgr.userMgr.mainUser.uid,
            emoji: emojiName);
      }
      ChatHelp.sendReactEmoji(
        chatID: widget.chat.id,
        messageId: widget.message.message_id,
        chatIdx: widget.message.chat_idx,
        recipientId: widget.message.send_id,
        userId: objectMgr.userMgr.mainUser.uid,
        emoji: emojiName,
      );
    }

    if (widget.chat.isGroup) {
      groupChatController!.resetPopupWindow();
    } else {
      singleChatController!.resetPopupWindow();
    }
  }

  GroupChatController? get groupChatController => widget.chat.isGroup
      ? Get.find<GroupChatController>(tag: widget.chat.id.toString())
      : null;

  SingleChatController? get singleChatController => widget.chat.isSingle
      ? Get.find<SingleChatController>(tag: widget.chat.id.toString())
      : null;

  @override
  Widget build(BuildContext context) {
    return widget.chat.typ >= chatTypeSaved ||
            !widget.chat.isValid ||
            (widget.chat.isGroup
                ? groupChatController?.isPinnedOpened ?? false
                : singleChatController?.isPinnedOpened ?? false)
        ? const SizedBox()
        : Obx(() {
            final Widget child;
            if (objectMgr.stickerMgr.isShowEmojiPanel.value) {
              child = EmojiPanelContainer(
                onEmojiClick: (String emoji) {
                  onReactEmojiSelect(emoji);
                },
              );
            } else {
              child = Container(
                height:
                    objectMgr.loginMgr.isDesktop ? 38 : getEmojiPanelHeight(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                margin: EdgeInsets.only(
                  left: objectMgr.userMgr.isMe(widget.message.send_id) ||
                          widget.chat.isSingle
                      ? 0
                      : 40,
                ),
                decoration: jxDimension.emojiSelectorDecoration(),
                child: Center(
                  child: Row(
                    children: [
                      ListView(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        children: reactEmojiOption.map(
                          (e) {
                            bool hasSelect = false;

                            // final key = '${e.substring(e.lastIndexOf('/') + 1)}';
                            for (final emojiData in widget.emojiMapList) {
                              if (emojiData!.emoji.contains(e)) {
                                if (emojiData.uidList
                                    .contains(objectMgr.userMgr.mainUser.uid)) {
                                  hasSelect = true;
                                  selectedEmojis.add(e);
                                }
                                break;
                              }
                            }

                            final childWidget = Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: hasSelect
                                    ? colorBorder
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(40),
                              ),
                              margin: const EdgeInsets.only(right: 4.0),
                              child: FittedBox(
                                child: Padding(
                                  padding: EdgeInsets.all(
                                      Platform.isAndroid ? 3 : 0),
                                  child: Text(
                                    textAlign: TextAlign.center,
                                    e,
                                    style: TextStyle(
                                      fontSize: 28,
                                      // fontFamily: 'emoji',
                                      height: ImLineHeight.getLineHeight(
                                          fontSize: 28, lineHeight: 32.81),
                                    ),
                                  ),
                                ),
                              ),
                            );

                            if (isDesktop) {
                              return ElevatedButtonTheme(
                                  data: ElevatedButtonThemeData(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      disabledBackgroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      surfaceTintColor: colorBorder,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      elevation: 0.0,
                                    ),
                                  ),
                                  child: ElevatedButton(
                                      onPressed: () {
                                        onReactEmojiSelect(e);
                                        Get.back();
                                      },
                                      child: childWidget));
                            } else {
                              return GestureDetector(
                                onTap: () => onReactEmojiSelect(e),
                                child: childWidget,
                              );
                            }
                          },
                        ).toList(),
                      ),
                      GestureDetector(
                        onTap: () {
                          objectMgr.stickerMgr.isShowEmojiPanel.value = true;
                          objectMgr.stickerMgr.showEmojiPanelClick();
                        },
                        child: Image.asset(
                          'assets/images/emoji_menu_more.png',
                          width: 32.0,
                          height: 32.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return child;
          });
  }

  @override
  void dispose() {
    objectMgr.stickerMgr.isShowEmojiPanel.value = false;
    super.dispose();
  }
}
