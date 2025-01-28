import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:lottie/lottie.dart';

class ChatReadNumView extends StatefulWidget {
  const ChatReadNumView({
    super.key,
    required this.chat,
    required this.message,
    required this.showPinned,
    required this.sender,
    this.backgroundColor = Colors.transparent,
  });

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
    objectMgr.chatMgr.off(ChatMgr.eventReadMessage, _updateReadMessage);
    widget.message.off(Message.eventSendState, _updateClockState);
    super.dispose();
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
            ? colorTextSecondary
            : bubblePrimary
        : colorWhite;

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
                            ? colorTextSupporting
                            : bubblePrimary
                        : colorWhite,
                    size: 14,
                  ),
                ),
              ),
            if (!widget.message.isEncrypted && widget.message.edit_time > 0)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(localized(chatEdited),
                    style: jxTextStyle.supportSmallText(
                      color: widget.backgroundColor == Colors.transparent
                          ? widget.sender
                              ? colorTextSecondary
                              : bubblePrimary
                          : colorWhite,
                    )),
              ),
            Text(
              FormatTime.chartTime(
                widget.message.create_time,
                false,
              ),
              style: jxTextStyle.chatReadNumText(color).copyWith(height: 1.2),
            ),
            if (!widget.message.isEncrypted && !widget.sender)
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: widget.message.isSendOk
                    ? SvgPicture.asset(
                        (widget.chat.other_read_idx >=
                                        widget.message.chat_idx &&
                                    widget.message.isSendOk) ||
                                (widget.chat.isSecretary ||
                                    widget.chat.isSystem ||
                                    widget.chat.isSaveMsg)
                            ? 'assets/svgs/done_all_icon.svg'
                            : 'assets/svgs/unread_tick_icon.svg',
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          colorReadColor,
                          BlendMode.srcIn,
                        ),
                      )
                    : ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          widget.backgroundColor == Colors.transparent
                              ? colorTextSecondary
                              : colorWhite,
                          BlendMode.srcIn,
                        ),
                        child: Lottie.asset(
                          'assets/lottie/clock_animation.json',
                          width: 16,
                          height: 14,
                          animate: !widget.message.isSendFail,
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
