import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:lottie/lottie.dart';

class ChatReadNumView extends StatefulWidget {
  const ChatReadNumView({
    Key? key,
    required this.chat,
    required this.message,
    required this.showPinned,
    required this.sender,
    this.backgroundColor = Colors.transparent,
  }) : super(key: key);

  final Chat chat;
  final Message message;
  final Color backgroundColor;
  final bool showPinned;
  final bool sender;

  @override
  State<ChatReadNumView> createState() => _ChatReadNumViewState();
}

class _ChatReadNumViewState extends State<ChatReadNumView> {
  @override
  void initState() {
    super.initState();
    objectMgr.chatMgr.on(ChatMgr.eventReadMessage, _updateReadMessage);
    widget.message.on(Message.eventSendState, _updateClockState);
  }

  @override
  void dispose() {
    super.dispose();
    objectMgr.chatMgr.off(ChatMgr.eventReadMessage, _updateReadMessage);
    widget.message.off(Message.eventSendState, _updateClockState);
  }

  @override
  void didUpdateWidget(ChatReadNumView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showPinned != widget.showPinned) {
      setState(() {});
    }
  }

  _updateReadMessage(sender, type, data) {
    if (data != null) {
      if (data['id'] == widget.chat.id && data['other_read_idx'] != null) {
        setState(() {
          widget.chat.other_read_idx = data['other_read_idx'];
        });
      }
    }
  }

  _updateClockState(sender, type, data) {
    if (data is Message) {
      if (data.chat_id == widget.message.chat_id &&
          data.chat_idx == widget.message.chat_idx) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color = widget.backgroundColor == Colors.transparent
        ? widget.sender
            ? JXColors.secondaryTextBlack
            : JXColors.chatBubbleTimeText
        : JXColors.white;

    return SelectionContainer.disabled(
      child: Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(bubbleBorderRadius),
        ),
        padding: widget.backgroundColor == Colors.transparent
            ? null
            : const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.showPinned)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Transform.rotate(
                  angle: 1,
                  child: Icon(
                    Icons.push_pin_rounded,
                    color: widget.backgroundColor == Colors.transparent
                        ? widget.sender
                            ? JXColors.chatBubbleSenderPinIcon
                            : JXColors.chatBubbleMePinIcon
                        : JXColors.white,
                    size: 14,
                  ),
                ),
              ),
            Text(
              FormatTime.chartTime(
                widget.message.create_time,
                false,
              ),
              style: jxTextStyle.chatReadNumText(color),
            ),
            if (!widget.sender)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: widget.message.isSendOk
                    ? SvgPicture.asset(
                        'assets/svgs/done_all_icon.svg',
                        width: 14,
                        height: 14,
                        color: widget.chat.other_read_idx >=
                                    widget.message.chat_idx &&
                                widget.message.isSendOk
                            ? JXColors.chatBubbleMeReadColor
                            : (widget.backgroundColor == Colors.transparent)
                                ? JXColors.chatBubbleMeTextColor
                                    .withOpacity(0.5)
                                : JXColors.white,
                      )
                    : ColorFiltered(
                        colorFilter: ColorFilter.mode(
                            widget.backgroundColor == Colors.transparent
                                ? JXColors.chatBubbleMeTextColor
                                    .withOpacity(0.5)
                                : JXColors.white,
                            BlendMode.srcIn),
                        child: Lottie.asset(
                          'assets/lottie/clock_animation.json',
                          width: 14,
                          animate: !widget.message.isSendFail,
                        ),
                      ),
              )
          ],
        ),
      ),
    );
  }
}
