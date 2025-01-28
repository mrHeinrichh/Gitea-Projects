import 'package:flutter/material.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';

import '../../../utils/theme/text_styles.dart';

class EmojiMember{
  int userId = 0;
  String emoji = "";
}

class EmojiBottomSheet extends StatelessWidget {
  final List<EmojiMember> reactEmojiList;

  const EmojiBottomSheet({
    Key? key,
    required this.reactEmojiList,
  }) : super(key: key);

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
              color: dividerColor,
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
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: dividerColor,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Image.asset(
                      'assets/images/lottie/react_emoji01/${MessageReactEmoji.emojiNameOldToNew(reactEmoji.emoji)}',
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 10.0),
                    CustomAvatar(
                      uid: reactEmoji.userId,
                      size: 40,
                      isGroup: false,
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: NicknameText(
                        uid: reactEmoji.userId,
                        isTappable: false,
                        fontWeight: MFontWeight.bold5.value,
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
