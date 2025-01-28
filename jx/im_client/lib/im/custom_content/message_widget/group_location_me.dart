import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_util.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_location_current.dart';
import 'package:jxim_client/im/custom_content/message_widget/group_location_live.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_forward_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/chat_content_util.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/message/chat/group/item/chat_my_sendstate_item.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final bool isPrevious;
  final bool isPinOpen;

  @override
  State<GroupLocationMe> createState() => _GroupLocationMeState();
}

class _GroupLocationMeState extends MessageWidgetMixin<GroupLocationMe> {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final emojiUserList = <EmojiModel>[].obs;

  late Widget childBody;

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

    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);

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

  get isDesktop => objectMgr.loginMgr.isDesktop;

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  @override
  void dispose() {
    widget.message.off(Message.eventSendState, refreshBubble);
    widget.message.off(Message.eventSendProgress, refreshBubble);

    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);

    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    childBody = messageBody(context);

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
                      _showEnableFloatingWindow(context);
                    }

                    isPressed.value = false;
                  },
                  onSecondaryTapDown: (details) {
                    if (objectMgr.loginMgr.isDesktop) {
                      desktopGeneralDialog(
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
                          menuHeight: ChatPopMenuUtil.getMenuHeight(
                            widget.message,
                            widget.chat,
                            extr: false,
                          ),
                        ),
                      );
                    }
                    isPressed.value = false;
                  },
                  onTapCancel: () {
                    isPressed.value = false;
                  },
                  child: childBody,
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

  void _showEnableFloatingWindow(BuildContext context) {
    enableFloatingWindow(
      context,
      widget.chat.id,
      widget.message,
      childBody,
      targetWidgetKey,
      tapPosition,
      ChatPopMenuSheet(
        message: widget.message,
        chat: widget.chat,
        sendID: widget.message.send_id,
      ),
      bubbleType: BubbleType.sendBubble,
      menuHeight: ChatPopMenuUtil.getMenuHeight(
        widget.message,
        widget.chat,
      ),
      topWidget: EmojiSelector(
        chat: widget.chat,
        message: widget.message,
        emojiMapList: emojiUserList,
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

      final Widget topBody = Padding(
        padding: forwardTitlePadding,
        child: MessageForwardComponent(
          forwardUserId: widget.messageLocation.forward_user_id,
          maxWidth: jxDimension.groupTextMeMaxWidth(),
          isSender: false,
        ),
      );

      Widget bottomBody = Padding(
        padding: EdgeInsets.symmetric(
          vertical: 4,
          horizontal: chatBubbleBodyHorizontalPadding,
        ),
        child: RichText(
          text: TextSpan(
            children: [
              ...BuildTextUtil.buildSpanList(
                widget.message,
                widget.messageLocation.name,
                launchLink:
                    controller.chatController.popupEnabled ? null : onLinkOpen,
                onMentionTap: controller.chatController.popupEnabled
                    ? null
                    : onMentionTap,
                textColor: colorTextPrimary,
                style: jxTextStyle.normalText(),
              ),
              TextSpan(
                  text:
                      '\n${widget.messageLocation.address}                 \u202F',
                  style: jxTextStyle.normalText(color: bubblePrimary)),
            ],
          ),
        ),
      );

      bottomBody = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 302),
        child: ChatBubbleBody(
          type: BubbleType.sendBubble,
          position: position,
          isClipped: true,
          isPressed: isPressed.value,
          body: Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (widget.messageLocation.forward_user_id != 0) topBody,
                  _buildImage(context),
                  bottomBody,
                ],
              ),
              Positioned(
                right: 11,
                bottom: 3,
                child: ChatReadNumView(
                  message: widget.message,
                  chat: widget.chat,
                  showPinned:
                      controller.chatController.pinMessageList.firstWhereOrNull(
                            (pinnedMsg) => pinnedMsg.id == widget.message.id,
                          ) !=
                          null,
                  sender: false,
                ),
              ),
            ],
          ),
        ),
      );

      return Container(
        margin: EdgeInsets.only(
          left: jxDimension.chatRoomSideMarginMaxGap,
          right: jxDimension.chatRoomSideMarginNoAva,
          bottom: isPinnedOpen ? 4 : 0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: AbsorbPointer(
                absorbing: controller.chatController.popupEnabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    bottomBody,

                    /// react emoji 表情栏
                    Obx(() {
                      List<Map<String, int>> emojiCountList = [];
                      for (var emoji in emojiUserList) {
                        final emojiCountMap = {
                          emoji.emoji: emoji.uidList.length,
                        };
                        emojiCountList.add(emojiCountMap);
                      }

                      return Visibility(
                        visible: emojiUserList.isNotEmpty,
                        child: GestureDetector(
                          onTap: controller.chatController.popupEnabled
                              ? null
                              : () => controller.onViewReactList(
                                    context,
                                    emojiUserList,
                                  ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
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
            _buildState(widget.message),
          ],
        ),
      );
    });
  }

  Widget _buildImage(BuildContext context) {
    final Widget imageChild = SizedBox(
      height: 148,
      child: _buildAsset(),
    );

    return isDesktop
        ? DesktopGeneralButton(
            horizontalPadding: 0,
            onPressed: () {
              if (controller.isCTRLPressed()) {
                desktopGeneralDialog(
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
                    menuHeight: ChatPopMenuUtil.getMenuHeight(
                      widget.message,
                      widget.chat,
                      extr: false,
                    ),
                  ),
                );
              } else {
                controller.showLargePhoto(context, widget.message);
              }
            },
            child: imageChild,
          )
        : GestureDetector(
            onTap: controller.chatController.popupEnabled ||
                    widget.message.isSendFail ||
                    !widget.message.isSendOk
                ? null
                : () async {
                    if (Platform.isAndroid) {
                      await Permissions.request(
                        [Permission.location],
                      );
                    }

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      enableDrag: false,
                      barrierColor: colorOverlay40,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Container(
                        height: MediaQuery.of(context).size.height -
                            Get.statusBarHeight,
                        decoration: const BoxDecoration(
                          color: colorWhite,
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
            child: imageChild,
          );
  }

  Widget _buildState(Message msg) {
    int time = msg.message_id == 0 ? msg.send_time : msg.create_time;
    return Padding(
      padding: EdgeInsets.only(
        left: isDesktop ? (!widget.message.isSendOk || message.isSendFail ? 4 : 0): 0,
      ),
      child: ChatMySendStateItem(
        key: Key(time.toString()),
        message: msg,
        failMsgClick: () {
          if (controller.chatController.popupEnabled) {
            return;
          }
          _showEnableFloatingWindow(context);
        },
      ),
    );
  }

  Widget _buildAsset() {
    final bool assetEmpty = widget.message.asset == null;

    return !assetEmpty
        ? Image.file(
            widget.message.asset,
            fit: BoxFit.cover,
            width: double.infinity,
          )
        : RemoteImage(
            key: ValueKey(
              '${widget.message.message_id}_${widget.messageLocation.url}_${Config().messageMin}',
            ),
            src: widget.messageLocation.url,
            fit: BoxFit.cover,
            mini: Config().messageMin,
            width: double.infinity,
          );
  }
}
