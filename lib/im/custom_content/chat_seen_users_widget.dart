import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';

class ChatSeenUsersWidget extends StatelessWidget {
  ChatSeenUsersWidget(LinkedHashMap<User, String> users, {super.key}) {
    final uidList = users.keys.toList();

    lastUsers =
        users.length <= 3 ? uidList : uidList.getRange(0, 3).toList();
  }

  late final List<User> lastUsers;

  final avatarSize = 24.0;
  final borderWidth = 2.0;

  double get avatarAllSize => avatarSize + borderWidth;

  Widget _buildAvatar(User user, {required int index}) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(right: 19.0 * index),
          child: CustomAvatar.user(
            user,
            size: avatarSize,
            headMin: Config().headMin,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: lastUsers
          .mapIndexed((i, e) => _buildAvatar(e, index: i))
          .toList(),
    );
  }
}
