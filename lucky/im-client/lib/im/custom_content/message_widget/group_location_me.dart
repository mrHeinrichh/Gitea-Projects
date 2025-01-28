import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_source_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/cache_image.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:jxim_client/im/model/emoji_model.dart';

import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/message/chat/group/item/chat_my_sendstate_item.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/im/custom_input/component/circular_count_down.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_location_current.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_location_live.dart';

class GroupLocationMe extends StatefulWidget {
  const GroupLocationMe({
    super.key,
    required this.messageLocation,
    required this.chat,
    required this.message,
    required this.index,
    this.isPrevious = true,
    this.isPinOpen = false,
  });

  final MessageMyLocation messageLocation;
  final Chat chat;
  final Message message;
  final int index;
  final isPrevious;
  final bool isPinOpen;

  @override
  State<GroupLocationMe> createState() => _GroupLocationMeState();
}

class _GroupLocationMeState extends State<GroupLocationMe>
    with MessageWidgetMixin {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final emojiUserList = <EmojiModel>[].obs;

  late MessageMyLocation msgImg;

  @override
  void initState() {
    super.initState();

    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());

    checkExpiredMessage(widget.message);
    msgImg = widget.messageLocation;

    widget.message.on(Message.eventSendState, refreshBubble);
    widget.message.on(Message.eventSendProgress, refreshBubble);
    widget.message.on(Message.eventAssetUpdate, updateAsset);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, onChatMessageEdit);

    initMessage(controller.chatController, widget.index, widget.message);
    emojiUserList.value = widget.message.emojis;
  }

  void updateAsset(sender, type, data) {
    if (widget.message == sender) {
      msgImg = widget.message.decodeContent(cl: MessageMyLocation.creator);
      if (mounted) setState(() {});
    }
  }

  void refreshBubble(sender, type, data) async {
    if (mounted) setState(() {});
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
        controller.chatController.removeUnreadBar();
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

  get isDesktop => objectMgr.loginMgr.isDesktop;

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  @override
  void dispose() {
    super.dispose();
    widget.message.off(Message.eventSendState, refreshBubble);
    widget.message.off(Message.eventSendProgress, refreshBubble);
    widget.message.off(Message.eventAssetUpdate, updateAsset);
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);

    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, onChatMessageEdit);
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
                    controller.chatController.onCancelFocus();
                    isPressed.value = false;
                  },
                  onLongPress: () {
                    if (!objectMgr.loginMgr.isDesktop) {
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
                    }

                    isPressed.value = false;
                  },
                  onSecondaryTapDown: (details) {
                    if (objectMgr.loginMgr.isDesktop) {
                      DesktopGeneralDialog(
                        context,
                        color: Colors.transparent,
                        widgetChild: DesktopMessagePopMenu(
                          offset: details.globalPosition,
                          isSender: true,
                          emojiSelector: EmojiSelector(
                            chat: widget.chat,
                            message: widget.message,
                            emojiMapList: emojiUserList,
                          ),
                          popMenu: ChatPopMenuSheet(
                            message: widget.message,
                            chat: widget.chat,
                            sendID: widget.message.send_id,
                          ),
                          menuHeight: ChatPopMenuSheet.getMenuHeight(
                              widget.message, widget.chat,
                              extr: false),
                        ),
                      );
                    }
                    isPressed.value = false;
                  },
                  onTapCancel: () {
                    isPressed.value = false;
                  },
                  child: child,
                ),
                Positioned(
                  left: 0.0,
                  right: 0.0,
                  top: 0.0,
                  bottom: 0.0,
                  child: RepaintBoundary(
                    child: MoreChooseView(
                      chatController: controller.chatController,
                      message: widget.message,
                      chat: widget.chat,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget messageBody(BuildContext context) {
    return Obx(() {
      BubblePosition position = isFirstMessage && isLastMessage
          ? BubblePosition.isFirstAndLastMessage
          : isLastMessage
              ? BubblePosition.isLastMessage
              : isFirstMessage
                  ? BubblePosition.isFirstMessage
                  : BubblePosition.isMiddleMessage;

      if (controller.chatController.isPinnedOpened) {
        position = BubblePosition.isLastMessage;
      }

      Widget topBody = const SizedBox();

      if (widget.messageLocation.forward_user_id != 0) {
        topBody = Padding(
          padding: const EdgeInsets.all(bubbleInnerPadding),
          child: ChatSourceView(
            forward_user_id: widget.messageLocation.forward_user_id,
            maxWidth: jxDimension.groupTextMeMaxWidth(),
            isSender: false,
          ),
        );
      }

      Widget bottomBody = const SizedBox();
      // if (widget.messageLocation.caption.isNotEmpty) {
      bottomBody = Container(
        width: 300,
        padding: const EdgeInsets.symmetric(
            vertical: bubbleInnerPadding, horizontal: 10),
        child: Material(
          color: Colors.transparent,
          child: Text.rich(
            TextSpan(
              children: [
                ...BuildTextUtil.buildSpanList(
                  widget.message,
                  '${widget.messageLocation.name}',
                  launchLink: controller.chatController.popupEnabled
                      ? null
                      : onLinkOpen,
                  onMentionTap: controller.chatController.popupEnabled
                      ? null
                      : onMentionTap,
                  textColor: JXColors.chatBubbleMeTextColor,
                ),
                TextSpan(
                  text:
                      '\n${widget.messageLocation.address}                 \u202F',
                  style: jxTextStyle
                      .normalBubbleText(JXColors.chatBubbleMeTextColor)
                      .copyWith(fontSize: 12),
                )
              ],
            ),
          ),
        ),
      );
      // }

      bottomBody = SizedBox(
        width: 300,
        child: Stack(
          children: <Widget>[
            ChatBubbleBody(
              type: BubbleType.sendBubble,
              position: position,
              isClipped: true,
              isPressed: isPressed.value,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  topBody,
                  _buildText(context, position),
                  bottomBody,
                ],
              ),
            ),
            false
                ? Positioned(
                    right: objectMgr.loginMgr.isDesktop ? 12 : 12.w,
                    bottom: objectMgr.loginMgr.isDesktop ? 16 : 16.w,
                    child: const CircularCountdown(
                      countDownSec: 120,
                    ),
                  )
                : Positioned(
                    right: objectMgr.loginMgr.isDesktop ? 12 : 12.w,
                    bottom: objectMgr.loginMgr.isDesktop ? 8 : 8.w,
                    child: ChatReadNumView(
                      message: widget.message,
                      chat: widget.chat,
                      showPinned: controller.chatController.pinMessageList
                              .firstWhereOrNull((pinnedMsg) =>
                                  pinnedMsg.id == widget.message.id) !=
                          null,
                      sender: false,
                    ),
                  ),
          ],
        ),
      );

      return SizedBox(
        width: double.infinity,
        child: Container(
          margin: EdgeInsets.only(
            left: jxDimension.chatRoomSideMarginMaxGap,
            right: jxDimension.chatRoomSideMarginNoAva,
            bottom: isPinnedOpen ? 4.w : 0,
          ),
          child: Row(
            children: [
              if (!widget.message.isSendOk)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _buildState(widget.message),
                ),
              Expanded(
                child: AbsorbPointer(
                  absorbing: controller.chatController.popupEnabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      bottomBody,

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
                          visible: emojiUserList.length > 0,
                          child: GestureDetector(
                            onTap: controller.chatController.popupEnabled
                                ? null
                                : () => controller.onViewReactList(
                                    context, emojiUserList),
                            child: Container(
                              margin: EdgeInsets.only(
                                  bottom:
                                      objectMgr.loginMgr.isDesktop ? 4 : 4.w),
                              child: EmojiListItem(
                                specialBgColor: true,
                                emojiModelList: emojiUserList,
                                message: widget.message,
                                controller: controller,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildText(BuildContext context, BubblePosition position) {
    BorderRadius imageBorderRadius = BorderRadius.zero;
    imageBorderRadius =
        bubbleSideRadius(position, BubbleType.sendBubble).copyWith(
      bottomLeft: const Radius.circular(0),
      bottomRight: const Radius.circular(0),
    );
    final Widget imageChild = Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            borderRadius: imageBorderRadius,
            color: isPressed.value ? JXColors.outlineColor : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: (!widget.message.isSendOk || widget.message.asset != null)
              ? buildAsset()
              : RemoteImage(
                  key: ValueKey(
                      '${widget.message.message_id}_${widget.messageLocation.url}_${Config().messageMin}'),
                  src: widget.messageLocation.url,
                  fit: BoxFit.cover,
                  mini: Config().messageMin,
                  width: 400,
                ),
        ),
        if (isPressed.value)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: imageBorderRadius,
                color: JXColors.outlineColor,
              ),
            ),
          ),
      ],
    );

    return isDesktop
        ? DesktopGeneralButton(
            horizontalPadding: 0,
            onPressed: () {
              if (controller.isCTRLPressed()) {
                DesktopGeneralDialog(
                  context,
                  color: Colors.transparent,
                  widgetChild: DesktopMessagePopMenu(
                    offset: tapPosition,
                    isSender: true,
                    emojiSelector: EmojiSelector(
                      chat: widget.chat,
                      message: widget.message,
                      emojiMapList: emojiUserList,
                    ),
                    popMenu: ChatPopMenuSheet(
                      message: widget.message,
                      chat: widget.chat,
                      sendID: widget.message.send_id,
                    ),
                    menuHeight: ChatPopMenuSheet.getMenuHeight(
                        widget.message, widget.chat,
                        extr: false),
                  ),
                );
              } else
                controller.showLargePhoto(context, widget.message);
            },
            child: Container(
              width: 300,
              height: 150,
              child: imageChild,
            ),
          )
        : GestureDetector(
            onTap: controller.chatController.popupEnabled ||
                    widget.message.isSendFail ||
                    !widget.message.isSendOk
                ? null
                : () async {
                    if (Platform.isAndroid) {
                      await Permissions.request([Permission.location],
                          context: context);
                    }

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      enableDrag: false,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Container(
                        height: MediaQuery.of(context).size.height -
                            Get.statusBarHeight,
                        decoration: const BoxDecoration(
                          color: JXColors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: widget.messageLocation.type == 0
                            ? GroupLocationCurrent(
                                messageLocation: widget.messageLocation,
                              )
                            : GroupLocationLive(
                                chat: widget.chat,
                                messageLocation: widget.messageLocation,
                                role: 'me',
                              ),
                      ),
                    );
                  },
            child: Container(
              width: 300,
              height: 150,
              child: imageChild,
            ),
          );
  }

  Widget _buildState(Message msg) {
    int time = msg.message_id == 0 ? msg.send_time : msg.create_time;
    return ChatMySendStateItem(key: Key(time.toString()), message: msg);
  }

  Widget buildAsset() {
    final bool assetEmpty = widget.message.asset == null;

    return !assetEmpty
        ? Image.file(
            widget.message.asset,
            fit: BoxFit.cover,
            width: 400,
          )
        : RemoteImage(
            src: widget.messageLocation.url,
            fit: BoxFit.cover,
            mini: Config().messageMin,
            width: 400,
            height: 200,
          );
  }
}
