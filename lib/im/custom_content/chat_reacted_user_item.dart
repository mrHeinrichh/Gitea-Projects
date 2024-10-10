import 'package:flutter/material.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';

class ChatReactedUserItem extends StatelessWidget {
  const ChatReactedUserItem(this.user, this.emoji, {super.key});

  final User user;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          CustomAvatar.user(
            user,
            size: 28,
            headMin: Config().headMin,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              user.nickname,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: jxTextStyle.textStyle17(
                color: colorTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: Text(
                emoji,
                style: jxTextStyle.textStyle17(),
              ),
            ),
          )
        ],
      ),
    );
  }
}
