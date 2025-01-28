import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_util.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/contact/contact_controller.dart';
import 'package:jxim_client/views/message/chat/widget/chat_help.dart';

class CallStateItem extends StatefulWidget {
  const CallStateItem({
    super.key,
    required this.chatContentController,
    required this.index,
    required this.chat,
    required this.message,
    required this.messageCall,
    this.isPrevious = true,
  });

  final ChatContentController chatContentController;
  final int index;
  final Chat chat;
  final Message message;
  final MessageCall messageCall;
  final bool isPrevious;

  @override
  CallStateItemState createState() => CallStateItemState();
}

class CallStateItemState extends MessageWidgetMixin<CallStateItem> {
  late ChatContentController controller;
  final selfKey = GlobalKey();
  final options = [
    // MessagePopupOption.reply,
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
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    super.dispose();
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
    Widget child = messageBody(context);

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
                          ///add confirm call to message bubble call.
                          User? user = objectMgr.userMgr
                              .getUserById(widget.chat.friend_id);
                          final ContactController contactController =
                              Get.find<ContactController>();
                          if (user != null) {
                            contactController.showCallSingleOption(
                              context,
                              widget.chat,
                              widget.messageCall.is_videocall == 0,
                            );
                          }
                          // objectMgr.callMgr.startCall(widget.chat,
                          //     widget.messageCall.is_videocall == 0);
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
                      onTapCancel: () => isPressed.value = false,
                      onLongPress: () {
                        enableFloatingWindow(
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
                          menuHeight: ChatPopMenuUtil.getMenuHeight(
                            widget.message,
                            widget.chat,
                            options: options,
                            extr: false,
                          ),
                        );
                        isPressed.value = false;
                      },
                      child: child,
                    ),
                  ),
                ),
                Positioned(
                  left: 0.0,
                  right: 0.0,
                  top: 0.0,
                  bottom: 0.0,
                  child: RepaintBoundary(
                    child: MoreChooseView(
                      chatController:
                          widget.chatContentController.chatController,
                      message: widget.message,
                      chat: widget.chatContentController.chatController.chat,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget messageBody(BuildContext context) {
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
            right: isMe ? jxDimension.chatRoomSideMarginAvaR * 2 : 0,
          ),
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: IntrinsicWidth(
            child: ChatBubbleBody(
              position: position,
              type: isMe ? BubbleType.sendBubble : BubbleType.receiverBubble,
              isPressed: isPressed.value,
              verticalPadding: 6,
              horizontalPadding: 12,
              body: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    ChatHelp.callImageContent(widget.messageCall),
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      isMe ? bubblePrimary : themeColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ChatHelp.callMsgContent(widget.message),
                          style: jxTextStyle.headerText(),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Text(
                              createTime,
                              style: jxTextStyle.normalSmallText(
                                color: colorTextSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.messageCall.time > 0
                                  ? ", ${constructTimeDetail(widget.messageCall.time)}"
                                  : ", ${localized(isMe ? callUnanswered : callReturn)}",
                              style: jxTextStyle.textStyle12(
                                color: colorTextSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
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
