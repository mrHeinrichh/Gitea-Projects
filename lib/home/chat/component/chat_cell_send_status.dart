import 'package:flutter/material.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:lottie/lottie.dart';

class ChatCellSendStatus extends StatelessWidget {
  final int sendState;
  final int sendId;

  const ChatCellSendStatus({
    super.key,
    required this.sendState,
    required this.sendId,
  });

  @override
  Widget build(BuildContext context) {
    switch (sendState) {
      case MESSAGE_SEND_FAIL:
        return Opacity(
          opacity: 1.0,
          child: Transform.rotate(
            angle: 3.15,
            child: const Icon(
              Icons.info,
              color: colorRed,
              size: 20,
            ),
          ),
        );
      case MESSAGE_SEND_ING:
        if (objectMgr.userMgr.isMe(sendId)) {
          return ColorFiltered(
            colorFilter: const ColorFilter.mode(
               colorTextSecondary,
                BlendMode.srcIn),
            child: Lottie.asset(
              'assets/lottie/clock_animation.json',
              width: 14,
            ),
          );
        }

        return const Icon(
          Icons.keyboard_double_arrow_right,
          color: colorTextSecondary,
          size: 14,
        );
      default:
        return const SizedBox();
    }
  }
}
