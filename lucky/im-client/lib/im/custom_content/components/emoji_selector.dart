import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/im/model/emoji_model.dart';

import '../../../utils/color.dart';
import '../../../utils/theme/dimension_styles.dart';

class EmojiSelector extends StatefulWidget {
  final Chat chat;
  final Message message;
  final RxList<EmojiModel?> emojiMapList;

  EmojiSelector({
    Key? key,
    required this.chat,
    required this.message,
    required this.emojiMapList,
  }) : super(key: key);

  @override
  State<EmojiSelector> createState() => _EmojiSelectorState();
}

class _EmojiSelectorState extends State<EmojiSelector> {
  List<String> selectedEmojis = [];
  final List<String> reactEmojiOption = [
    /// 目前只保留6个跟之前一一对应
    'assets/images/lottie/react_emoji01/emoji_thumb_up.webp',
    'assets/images/lottie/react_emoji01/emoji_smile_with_heart.webp',
    // 'assets/images/lottie/react_emoji01/emoji_clap.webp',
    'assets/images/lottie/react_emoji01/emoji_thumb_down.webp',
    'assets/images/lottie/react_emoji01/emoji_fire.webp',
    'assets/images/lottie/react_emoji01/emoji_smile.webp',
    'assets/images/lottie/react_emoji01/emoji_heart.webp',

    // 'assets/images/lottie/react_emoji/thumbs-up-2.json',
    // 'assets/images/lottie/react_emoji/heart-1.json',
    // 'assets/images/lottie/react_emoji/beaming-face.json',
    // 'assets/images/lottie/react_emoji/astonished-face.json',
    // 'assets/images/lottie/react_emoji/angry-face.json',
    // 'assets/images/lottie/react_emoji/anxious-face.json',
  ];
  final isDesktop = objectMgr.loginMgr.isDesktop;

  int activePointer = 0;

  @override
  void initState() {
    super.initState();
    widget.emojiMapList.forEach((element) { 
      if(element != null && element.uidList.contains(objectMgr.userMgr.mainUser.uid)){
        selectedEmojis.add(MessageReactEmoji.emojiNameOldToNew(element.emoji));
      }
    });
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
        emoji: MessageReactEmoji.emojiNameNewToOld(emojiName),
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
            emoji: MessageReactEmoji.emojiNameNewToOld(emojiName));
      }
      ChatHelp.sendReactEmoji(
        chatID: widget.chat.id,
        messageId: widget.message.message_id,
        chatIdx: widget.message.chat_idx,
        recipientId: widget.message.send_id,
        userId: objectMgr.userMgr.mainUser.uid,
        emoji: MessageReactEmoji.emojiNameNewToOld(emojiName),
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
    return !widget.chat.isValid ||
            (widget.chat.isGroup
                ? groupChatController?.isPinnedOpened ?? false
                : singleChatController?.isPinnedOpened ?? false)
        ? const SizedBox()
        : Container(
            height: objectMgr.loginMgr.isDesktop ? 38 : 48,
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
              child: ListView(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                children: reactEmojiOption.map(
                  (e) {
                    bool hasSelect = false;

                    final key = '${e.substring(e.lastIndexOf('/') + 1)}';
                    for (final emojiData in widget.emojiMapList) {
                      if (emojiData!.emoji.contains(key)) {
                        if (emojiData.uidList.contains(objectMgr.userMgr.mainUser.uid)) {
                          hasSelect = true;
                          selectedEmojis.add(e);
                        }
                        break;
                      }
                    }

                    final childWidget = Container(
                      width: objectMgr.loginMgr.isDesktop ? 40 : 40,
                      height: objectMgr.loginMgr.isDesktop ? 40 : 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: hasSelect
                            ? objectMgr.loginMgr.isDesktop
                                ? JXColors.white
                                : Colors.grey[200]
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      margin: const EdgeInsets.only(right: 4.0),
                      child: Image.asset(
                        e,
                        width: objectMgr.loginMgr.isDesktop ? 24 : 32,
                        height: objectMgr.loginMgr.isDesktop ? 24 : 32,
                      ),
                    );

                    if (isDesktop)
                      return ElevatedButtonTheme(
                          data: ElevatedButtonThemeData(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              surfaceTintColor: JXColors.outlineColor,
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
                    // return DesktopGeneralButton(
                    //   horizontalPadding: 2.5,
                    //   onPressed: () => onReactEmojiSelect(e),
                    //   child: childWidget,
                    // );
                    else
                      return GestureDetector(
                        onTap: () => onReactEmojiSelect(e),
                        child: childWidget,
                      );
                  },
                ).toList(),
              ),
            ),
          );
  }
}
