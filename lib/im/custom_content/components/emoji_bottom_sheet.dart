import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';

class EmojiMember {
  int userId = 0;
  String emoji = "";
}

class EmojiBottomSheet extends StatelessWidget {
  final List<EmojiMember> reactEmojiList;
  final Chat chat;

  const EmojiBottomSheet({
    super.key,
    required this.reactEmojiList,
    required this.chat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Container(
            height: 9,
            width: 63,
            decoration: BoxDecoration(
              color: colorBorder,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: reactEmojiList.length,
            itemBuilder: (BuildContext context, int index) {
              EmojiMember reactEmoji = reactEmojiList[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colorBorder,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    // Image.asset(
                    //   'assets/images/lottie/react_emoji01/${MessageReactEmoji.emojiNameOldToNew(reactEmoji.emoji)}',
                    //   width: 30,
                    //   height: 30,
                    //   alignment: Alignment.center,
                    //   fit: BoxFit.cover,
                    // ),
                    FittedBox(
                      child: Text(
                        textAlign: TextAlign.center,
                        reactEmoji.emoji,
                        style: TextStyle(
                          fontSize: 28,
                          // fontFamily: 'emoji',
                          height: ImLineHeight.getLineHeight(
                              fontSize: 28, lineHeight: 32.81),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    CustomAvatar.normal(
                      reactEmoji.userId,
                      size: 40,
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: NicknameText(
                        uid: reactEmoji.userId,
                        isTappable: false,
                        fontWeight: MFontWeight.bold5.value,
                        groupId: chat.isGroup ? chat.chat_id : null,
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(height: 1.0);
            },
          ),
        ),
      ],
    );
  }
}
