import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';

class CallStateItem extends StatefulWidget {
  const CallStateItem({
    Key? key,
    required this.chatContentController,
    required this.index,
    required this.chat,
    required this.message,
    required this.messageCall,
    this.isPrevious = true,
  }) : super(key: key);
  final ChatContentController chatContentController;
  final int index;
  final Chat chat;
  final Message message;
  final MessageCall messageCall;
  final isPrevious;

  @override
  _CallStateItemState createState() => _CallStateItemState();
}

class _CallStateItemState extends State<CallStateItem> with MessageWidgetMixin {
  late ChatContentController controller;
  final selfKey = GlobalKey();
  final options = [
    MessagePopupOption.delete,
  ];

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());

    checkExpiredMessage(widget.message);

    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);

    initMessage(controller.chatController, widget.index, widget.message);
  }

  @override
  void dispose() {
    super.dispose();
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
  }

  void _onAutoDeleteMsgTriggered(Object sender, Object type, Object? data) {
    if (data is Message) {
      if (widget.message.id == data.id) {
        controller.chatController.removeUnreadBar();
        checkDateMessage(data);
        isExpired.value = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = messageBody();

    return Obx(
      () => isExpired.value || isDeleted.value
          ? const SizedBox()
          : Stack(
              children: [
                Obx(
                  () => AbsorbPointer(
                    absorbing: widget
                        .chatContentController.chatController.chooseMore.value,
                    child: GestureDetector(
                      key: selfKey,
                      onTap: () {
                        if (objectMgr.loginMgr.isMobile) {
                          objectMgr.callMgr.startCall(widget.chat,
                              widget.messageCall.is_videocall == 0);
                        }
                      },
                      onTapDown: (details) {
                        tapPosition = details.globalPosition;
                        isPressed.value = true;
                      },
                      onTapUp: (_) {
                        controller.chatController.onCancelFocus();
                        isPressed.value = false;
                      },
                      onLongPress: () => enableFloatingWindow(
                        context,
                        widget.chat.id,
                        widget.message,
                        child,
                        selfKey,
                        tapPosition,
                        ChatPopMenuSheet(
                          message: widget.message,
                          chat: widget.chat,
                          sendID: widget.message.send_id,
                          options: options,
                        ),
                        bubbleType:
                            objectMgr.userMgr.isMe(widget.messageCall.inviter)
                                ? BubbleType.sendBubble
                                : BubbleType.receiverBubble,
                        menuHeight: ChatPopMenuSheet.getMenuHeight(
                          widget.message,
                          widget.chat,
                          options: options,
                        ),
                      ),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget messageBody() {
    final isMe = objectMgr.userMgr.isMe(widget.messageCall.inviter);
    final createTime = FormatTime.chartTime(widget.message.create_time, false);

    return Obx(
      () {
        BubblePosition position = isFirstMessage && isLastMessage
            ? BubblePosition.isFirstAndLastMessage
            : isLastMessage
                ? BubblePosition.isLastMessage
                : isFirstMessage
                    ? BubblePosition.isFirstMessage
                    : BubblePosition.isMiddleMessage;
        return Container(
          margin: EdgeInsets.only(
              left: widget.chatContentController.chatController.chooseMore.value
                  ? 40.w
                  : isMe
                      ? 0
                      : jxDimension.chatRoomSideMarginAvaR * 2,
              right: isMe ? jxDimension.chatRoomSideMarginAvaR * 2 : 0),
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: IntrinsicWidth(
            child: ChatBubbleBody(
              position: position,
              type: isMe ? BubbleType.sendBubble : BubbleType.receiverBubble,
              verticalPadding: 6,
              horizontalPadding: 12,
              body: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ChatHelp.callMsgContent(widget.message),
                          style: TextStyle(
                            fontWeight: MFontWeight.bold4.value,
                            fontSize: MFontSize.size16.value,
                            color: isMe
                                ? JXColors.chatBubbleMeTextColor
                                : JXColors.chatBubbleSenderTextColor,
                            decoration: TextDecoration.none,
                            fontFamily: appFontfamily,
                            letterSpacing: 0,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Icon(
                              isMe
                                  ? CupertinoIcons.arrow_up_right
                                  : CupertinoIcons.arrow_down_left,
                              color: widget.messageCall.time > 0
                                  ? JXColors.chatBubbleCallIndicatorColor
                                  : JXColors.red,
                              size: MFontSize.size12.value,
                            ),
                            Text(
                              createTime,
                              style: jxTextStyle.textStyle12(
                                color: isMe
                                    ? JXColors.chatBubbleCallTextMeColor
                                    : JXColors.chatBubbleCallTextSenderColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                                widget.messageCall.time > 0
                                    ? ", ${constructTimeDetail(widget.messageCall.time)}"
                                    : "",
                                style: jxTextStyle.textStyle12(
                                  color: isMe
                                      ? JXColors.chatBubbleCallTextMeColor
                                      : JXColors.chatBubbleCallTextSenderColor,
                                ),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SvgPicture.asset(
                    widget.messageCall.is_videocall == 1
                        ? 'assets/svgs/video_call_outline.svg'
                        : 'assets/svgs/call_outline.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      isMe ? JXColors.green : accentColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
