import 'package:flutter/material.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:lottie/lottie.dart';

import 'package:jxim_client/utils/theme/text_styles.dart';

class ReactEmojiBottomSheet extends StatelessWidget {
  final List<MessageReactEmoji> reactEmojiList;

  const ReactEmojiBottomSheet({
    super.key,
    required this.reactEmojiList,
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
              MessageReactEmoji reactEmoji = reactEmojiList[index];
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
                    LottieBuilder.asset(
                      'assets/images/lottie/react_emoji01/${reactEmoji.emoji}',
                      width: 30,
                      height: 30,
                      animate: true,
                      addRepaintBoundary: true,
                      alignment: Alignment.center,
                      fit: BoxFit.cover,
                      repeat: false,
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
