import 'package:flutter/material.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';

class Assignee extends StatelessWidget {
  final int uid;
  final Color color;

  const Assignee({
    super.key,
    required this.uid,
    this.color = colorTextPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 1.0,
        top: 1.0,
        bottom: 1.0,
        right: 8,
      ),
      decoration: BoxDecoration(
        color: color.computeLuminance() < 0.5
            ? colorTextPrimary.withOpacity(0.06)
            : colorWhite.withOpacity(0.15),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Row(
        children: [
          CustomAvatar.normal(
            uid,
            size: 24.0,
            headMin: Config().headMin,
            fontSize: 14,
          ),
          const SizedBox(width: 4),
          NicknameText(
            uid: uid,
            overflow: TextOverflow.ellipsis,
            isTappable: false,
            isShowYou: objectMgr.userMgr.isMe(uid),
            color: color,
          ),
        ],
      ),
    );
  }
}
