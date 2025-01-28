import 'package:flutter/material.dart';
import 'package:jxim_client/im/custom_content/chat_reacted_user_item.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';

class ChatReactedUsersWidget extends StatelessWidget {
  const ChatReactedUsersWidget({
    required this.users,
    super.key,
  });

  final List<MapEntry<User, String>> users;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: users.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final user = users[index].key;
          final emoji = users[index].value;

          return ChatReactedUserItem(user, emoji);
        },
        separatorBuilder: (context, index) => Container(
          height: 0.3,
          color: colorTextPlaceholder,
        ),
      ),
    );
  }
}
