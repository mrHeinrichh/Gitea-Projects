import 'package:flutter/cupertino.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:lottie/lottie.dart';

class MessageReadTextIcon extends StatelessWidget {
  final bool isWaitingRead;
  final bool isMe;
  final double? right;
  final double? senderOffset;

  const MessageReadTextIcon(
      {super.key,
        required this.isWaitingRead,
        required this.isMe,
        this.right,
        this.senderOffset,
      });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: isMe ? 11.0 : 6.0,
      right: right,
      child: Transform.translate(
        offset: isMe ? const Offset(-24.0, 0.0) : Offset(senderOffset ?? 24.0, 0.0),
        child: Padding(
          padding: isMe ? const EdgeInsets.only(right: 6) : const EdgeInsets.only(left: 6),
          child: isWaitingRead
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CupertinoActivityIndicator(
                    color: colorWhite,
                  ),
                )
              : Lottie.asset(
                  'assets/lottie/playing_sound.json',
                  width: 20,
                ),
        ),
      ),
    );
  }
}
