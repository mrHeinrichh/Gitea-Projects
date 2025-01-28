import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/components/task/assignee.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/task_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/task_content.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/views/component/click_effect_button.dart';
import 'package:jxim_client/views/component/custom_avatar.dart';
import 'package:jxim_client/im/model/emoji_model.dart';

import '../../../utils/saved_message_icon.dart';
import '../../../utils/theme/text_styles.dart';

class TaskSenderBubble extends StatefulWidget {
  final TaskContent messageTask;
  final Chat chat;
  final Message message;
  final int index;
  final bool isPrevious;

  const TaskSenderBubble({
    super.key,
    required this.chat,
    required this.message,
    required this.index,
    required this.messageTask,
    this.isPrevious = true,
  });

  @override
  TaskSenderBubbleState createState() => TaskSenderBubbleState();
}

class TaskSenderBubbleState extends State<TaskSenderBubble>
    with MessageWidgetMixin {
  final GlobalKey targetWidgetKey = GlobalKey();
  final GlobalKey avatarWidgetKey = GlobalKey();
  ChatContentController? controller;

  late final Rx<TaskContent> task;

  final emojiUserList = <EmojiModel>[].obs;

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<ChatContentController>(tag: widget.chat.id.toString());

    if (objectMgr.taskMgr.taskMap[widget.messageTask.taskId] != null) {
      task = Rx<TaskContent>(
          objectMgr.taskMgr.taskMap[widget.messageTask.taskId]!);
    } else {
      task = Rx<TaskContent>(widget.messageTask);
    }

    checkExpiredMessage(widget.message);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, onChatMessageEdit);
    objectMgr.taskMgr.on(MgrTask.UPDATE_TASK, onStatusUpdate);

    initMessage(controller!.chatController, widget.index, widget.message);

    emojiUserList.value = widget.message.emojis;
  }

  @override
  void dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, onChatMessageEdit);

    objectMgr.taskMgr.off(MgrTask.UPDATE_TASK, onStatusUpdate);
    super.dispose();
  }

  void onStatusUpdate(Object sender, Object type, Object? data) {
    if (data is SubTask && data.taskId == task.value.taskId) {
      final subTask = task.value.subtasks.firstWhere(
          (element) => element.subTaskId == data.subTaskId,
          orElse: () => SubTask());
      subTask.status = data.status;
      task.refresh();
    }
  }

  _onReactEmojiUpdate(Object sender, Object type, Object? data) async {
    if (data is Message) {
      if (widget.message.chat_id == data.chat_id &&
          data.id == widget.message.id) {
        emojiUserList.value = data.emojis;
        emojiUserList.refresh();
      }
    }
  }

  void _onAutoDeleteMsgTriggered(Object sender, Object type, Object? data) {
    if (data is Message) {
      if (widget.message.message_id == data.message_id) {
        controller!.chatController.removeUnreadBar();
        checkDateMessage(data);
        isExpired.value = true;
      }
    }
  }

  onChatMessageDelete(sender, type, data) {
    if (data['id'] != widget.chat.chat_id) {
      return;
    }
    if (data['message'] != null) {
      for (var item in data['message']) {
        if (item is Message) {
          if (item.id == widget.message.id) {
            isDeleted.value = true;
            checkDateMessage(message);
            break;
          }
        } else {
          if (item == widget.message.message_id) {
            isDeleted.value = true;
            checkDateMessage(message);
            break;
          }
        }
      }
    }
  }

  onChatMessageEdit(sender, type, data) {
    if (data['id'] != widget.chat.chat_id) {
      return;
    }
    if (data['message'] != null) {
      Message item = data['message'];
      if (item.id == widget.message.id) {
        widget.message.content = item.content;
        widget.message.edit_time = item.edit_time;
        widget.message.sendState = item.sendState;
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
              children: <Widget>[
                GestureDetector(
                  key: targetWidgetKey,
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    tapPosition = details.globalPosition;
                    isPressed.value = true;
                  },
                  onTapUp: (_) {
                    controller?.chatController.onCancelFocus();
                    isPressed.value = false;
                  },
                  onTapCancel: () {
                    isPressed.value = false;
                  },
                  onLongPress: () {
                    enableFloatingWindow(
                      context,
                      widget.chat.id,
                      widget.message,
                      child,
                      targetWidgetKey,
                      tapPosition,
                      ChatPopMenuSheet(
                        message: widget.message,
                        chat: widget.chat,
                        sendID: widget.message.send_id,
                      ),
                      bubbleType: BubbleType.receiverBubble,
                      menuHeight: ChatPopMenuSheet.getMenuHeight(
                          widget.message, widget.chat),
                      topWidget: EmojiSelector(
                        chat: widget.chat,
                        message: widget.message,
                        emojiMapList: emojiUserList,
                      ),
                    );
                    isPressed.value = false;
                  },
                  onSecondaryTapDown: (details) {
                    enableFloatingWindow(
                      context,
                      widget.chat.id,
                      widget.message,
                      child,
                      targetWidgetKey,
                      tapPosition,
                      ChatPopMenuSheet(
                        message: widget.message,
                        chat: widget.chat,
                        sendID: widget.message.send_id,
                      ),
                      bubbleType: BubbleType.sendBubble,
                      menuHeight: ChatPopMenuSheet.getMenuHeight(
                          widget.message, widget.chat),
                      topWidget: EmojiSelector(
                        chat: widget.chat,
                        message: widget.message,
                        emojiMapList: emojiUserList,
                      ),
                    );
                    isPressed.value = false;
                  },
                  child: child,
                ),
                Positioned(
                  top: 0.0,
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  child: MoreChooseView(
                    message: widget.message,
                    chat: widget.chat,
                    chatController: controller!.chatController,
                  ),
                ),
              ],
            ),
    );
  }

  bool get showAvatar =>
      !controller!.chat!.isSystem &&
      !controller!.chat!.isSecretary &&
      !controller!.chat!.isSingle &&
      (isLastMessage || controller!.chatController.isPinnedOpened);

  Widget messageBody(BuildContext context) {
    Widget body = Container(
      width: 268,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // title
          Text(
            task.value.title,
            style: TextStyle(
              fontSize: 16.0,
              height: 1.25,
              fontWeight: MFontWeight.bold6.value,
              color: JXColors.primaryTextBlack,
            ),
          ),

          // sub task details
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: min(8, task.value.totalCount),
            itemBuilder: (BuildContext context, int index) {
              return Obx(() {
                final SubTask subTask = task.value.subtasks[index];

                return OpacityEffect(
                  child: GestureDetector(
                    onTap: () => controller!.onTaskItemTap(
                      context,
                      widget.messageTask,
                      subTask,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        buildStatusTick(subTask.status),
                        const SizedBox(width: 12.0),
                        buildTaskContent(
                          subTask,
                          index == (widget.messageTask.totalCount - 1),
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          ),

          if (widget.messageTask.totalCount > 8) buildSeeMore(),
        ],
      ),
    );

    BubblePosition position = isFirstMessage && isLastMessage
        ? BubblePosition.isFirstAndLastMessage
        : isLastMessage
            ? BubblePosition.isLastMessage
            : isFirstMessage
                ? BubblePosition.isFirstMessage
                : BubblePosition.isMiddleMessage;

    if (controller!.chatController.isPinnedOpened) {
      position = BubblePosition.isLastMessage;
    }

    body = Container(
      padding: EdgeInsets.only(left: jxDimension.chatRoomSideMarginAvaR),
      child: ChatBubbleBody(
        type: BubbleType.receiverBubble,
        position: position,
        verticalPadding: 6,
        horizontalPadding: 12,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            body,

            /// react emoji 表情栏
            Obx(() {
              List<Map<String, int>> emojiCountList = [];
              emojiUserList.forEach((emoji) {
                final emojiCountMap = {
                  MessageReactEmoji.emojiNameOldToNew(emoji.emoji):
                      emoji.uidList.length,
                };
                emojiCountList.add(emojiCountMap);
              });

              return Visibility(
                visible: emojiUserList.isNotEmpty,
                child: GestureDetector(
                  onTap: () =>
                      controller?.onViewReactList(context, emojiUserList),
                  child: EmojiListItem(
                    emojiModelList: emojiUserList,
                    message: widget.message,
                    controller: controller!,
                    eMargin: EmojiMargin.me,
                    isSender: true,
                  ),
                ),
              );
            })
          ],
        ),
      ),
    );

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        right: controller!.chatController.chooseMore.value
            ? jxDimension.chatRoomSideMargin
            : jxDimension.chatRoomSideMarginMaxGap,
        left: controller!.chatController.chooseMore.value
            ? 40
            : (widget.chat.typ == chatTypeSingle
                ? jxDimension.chatRoomSideMarginSingle
                : jxDimension.chatRoomSideMargin),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Opacity(
            opacity: showAvatar ? 1 : 0,
            child: buildAvatar(),
          ),
          Stack(
            children: <Widget>[
              body,
              Positioned(
                right: 12,
                bottom: 8,
                child: ChatReadNumView(
                  message: widget.message,
                  chat: widget.chat,
                  showPinned: false,
                  sender: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildAvatar() {
    if (controller!.chat!.isSaveMsg) {
      return Container(
        key: controller!.chatController.popupEnabled ? null : avatarWidgetKey,
        width: jxDimension.chatRoomAvatarSize(),
        height: jxDimension.chatRoomAvatarSize(),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: [
              Color(0xFFFFD08E),
              Color(0xFFFFECD2),
            ],
          ),
        ),
        child: const SavedMessageIcon(),
      );
    }

    if (controller!.chat!.isSecretary) {
      return Image.asset(
        key: controller!.chatController.popupEnabled ? null : avatarWidgetKey,
        'assets/images/message_new/secretary.png',
        width: 36,
        height: 36,
      );
    }

    if (controller!.chat!.isSystem) {
      return Image.asset(
        key: controller!.chatController.popupEnabled ? null : avatarWidgetKey,
        'assets/images/message_new/sys_notification.png',
        width: 36,
        height: 36,
      );
    }

    if (controller!.chat!.isGroup) {
      return CustomAvatar(
        key: controller!.chatController.popupEnabled ? null : avatarWidgetKey,
        uid: widget.message.send_id,
        size: jxDimension.chatRoomAvatarSize(),
        headMin: Config().headMin,
        onTap: widget.message.send_id == 0
            ? null
            : () {
                Get.toNamed(RouteName.chatInfo,
                    arguments: {
                      "uid": widget.message.send_id,
                    },
                    id: objectMgr.loginMgr.isDesktop ? 1 : null);
              },
        onLongPress: widget.message.send_id == 0
            ? null
            : () async {
                User? user = await objectMgr.userMgr
                    .loadUserById2(widget.message.send_id);
                if (user != null) {
                  controller!.inputController.addMentionUser(user);
                }
              },
      );
    }

    return SizedBox(
      key: controller!.chatController.popupEnabled ? null : avatarWidgetKey,
      width: controller!.chatController.chat.isSingle
          ? 0
          : jxDimension.chatRoomAvatarSize(),
    );
  }

  Widget buildStatusTick(TaskStatus status) {
    if (status == TaskStatus.progress) {
      return Container(
        width: 20.0,
        height: 20.0,
        margin: const EdgeInsets.only(top: 12),
        decoration: const BoxDecoration(
          color: JXColors.purple,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.more_horiz,
          size: 18.0,
          color: Colors.white,
        ),
      );
    }

    if (status == TaskStatus.done) {
      return Container(
        width: 20.0,
        height: 20.0,
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: successColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          size: 18.0,
          color: Colors.white,
        ),
      );
    }

    if (status == TaskStatus.cancel) {
      return Container(
        width: 20.0,
        height: 20.0,
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: JXColors.white.withOpacity(0.48),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close,
          size: 18.0,
          color: JXColors.primaryTextBlack.withOpacity(0.6),
        ),
      );
    }

    return Container(
        width: 20.0,
        height: 20.0,
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: JXColors.primaryTextBlack.withOpacity(0.6),
            width: 1.0,
          ),
          shape: BoxShape.circle,
        ));
  }

  Widget buildTaskContent(SubTask subTask, bool isLast) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(
                    color: JXColors.bgTertiaryColor,
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                subTask.content,
                style: const TextStyle(
                  fontSize: 16.0,
                  color: JXColors.primaryTextBlack,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Assignee(
              uid: subTask.uid,
              color: JXColors.primaryTextBlack,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSeeMore() {
    return OpacityEffect(
      child: GestureDetector(
        onTap: () => Get.toNamed(
          RouteName.taskDetail,
          arguments: {
            'task': task.value,
            'message': widget.message,
            'chat': widget.chat,
          },
        ),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            localized(
              seeMore,
              params: [widget.messageTask.totalCount.toString()],
            ),
            style: TextStyle(
              fontSize: 14.0,
              color: accentColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
