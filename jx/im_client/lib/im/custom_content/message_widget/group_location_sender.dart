import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/permissions.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/avatar/custom_avatar.dart';
import 'package:jxim_client/views/component/nickname_text.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_button.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';
import 'package:permission_handler/permission_handler.dart';

class GroupLocationSender extends StatefulWidget {
  const GroupLocationSender({
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
  State<GroupLocationSender> createState() => _GroupLocationSenderState();
}

class _GroupLocationSenderState
    extends MessageWidgetMixin<GroupLocationSender> {
  late ChatContentController controller;
  final GlobalKey targetWidgetKey = GlobalKey();
  final GlobalKey avatarWidgetKey = GlobalKey();

  final emojiUserList = <EmojiModel>[].obs;
  int sendID = 0;

  @override
  void initState() {
    super.initState();

    controller =
        Get.find<ChatContentController>(tag: widget.chat.chat_id.toString());

    checkExpiredMessage(widget.message);

    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);

    initMessage(controller.chatController, widget.index, widget.message);

    emojiUserList.value = widget.message.emojis;
    getRealSendID();
  }

  getRealSendID() {
    sendID = widget.message.send_id;
    if (widget.chat.isSaveMsg) {
      sendID = widget.messageLocation.forward_user_id;
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
        controller.chatController.removeUnreadBar();
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

  @override
  void dispose() {
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
    super.dispose();
  }

  get isPinnedOpen => controller.chatController.isPinnedOpened;

  bool get showAvatar =>
      !controller.chat!.isSystem &&
      !controller.chat!.isSecretary &&
      !controller.chat!.isSingle &&
      (isLastMessage || controller.chatController.isPinnedOpened);

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
                  onTapCancel: () {
                    isPressed.value = false;
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
                        bubbleType: BubbleType.receiverBubble,
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
                    isPressed.value = false;
                  },
                  onSecondaryTapDown: (details) {
                    if (objectMgr.loginMgr.isDesktop) {
                      desktopGeneralDialog(
                        context,
                        color: Colors.transparent,
                        widgetChild: DesktopMessagePopMenu(
                          offset: details.globalPosition,
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
                  child: child,
                ),
                Positioned(
                  left: 0.0,
                  right: 0.0,
                  bottom: 0.0,
                  top: 0.0,
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
      /// 消息内容
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
          maxWidth: jxDimension.groupTextSenderMaxWidth(hasAvatar: true),
          isSender: true,
        ),
      );

      final Widget bottomBody = Padding(
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
                style: jxTextStyle.normalText(color: colorTextSecondary),
              ),
            ],
          ),
        ),
      );
      // }

      Widget body = Container(
        padding: EdgeInsets.only(
          left: widget.chat.typ == chatTypeSingle
              ? 0
              : jxDimension.chatRoomSideMarginAvaR,
        ),
        constraints: BoxConstraints(
          maxWidth: widget.chat.typ == chatTypeSingle
              ? 302
              : 302 -
                  (jxDimension.chatRoomAvatarSize() -
                      jxDimension.chatRoomSideMarginAvaR),
        ),
        child: ChatBubbleBody(
          position: position,
          isClipped: true,
          isPressed: isPressed.value,
          body: Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 昵称
                  if (widget.messageLocation.forward_user_id != 0 &&
                      (isFirstMessage || widget.isPinOpen) &&
                      !widget.chat.isSaveMsg)
                    Offstage(
                      offstage: widget.chat.isSingle ||
                          widget.chat.typ == chatTypeSystem ||
                          widget.chat.typ == chatTypeSmallSecretary,
                      child: Padding(
                        padding: BubblePadding.nickname,
                        child: NicknameText(
                          uid: sendID,
                          // color: themeColor,
                          isRandomColor: true,
                          fontWeight: MFontWeight.bold5.value,
                          fontSize: bubbleNicknameSize,
                          groupId: widget.chat.isGroup ? widget.chat.id : null,
                        ),
                      ),
                    ),
                  if (widget.messageLocation.forward_user_id != 0 &&
                      !widget.chat.isSaveMsg)
                    topBody,

                  if (objectMgr.loginMgr.isDesktop)
                    DesktopGeneralButton(
                      horizontalPadding: 0,
                      onPressed: () {
                        if (controller.isCTRLPressed()) {
                          desktopGeneralDialog(
                            context,
                            color: Colors.transparent,
                            widgetChild: DesktopMessagePopMenu(
                              offset: tapPosition,
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
                      child: getImage(),
                    )
                  else
                    GestureDetector(
                      onTap: controller.chatController.popupEnabled
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
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: widget.messageLocation.type == 0
                                      ? GroupLocationCurrent(
                                          messageLocation:
                                              widget.messageLocation,
                                        )
                                      : GroupLocationLive(
                                          chat: widget.chat,
                                          messageLocation:
                                              widget.messageLocation,
                                          role: 'sender',
                                        ),
                                ),
                              );
                            },
                      child: getImage(),
                    ),
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
                  sender: true,
                ),
              ),
            ],
          ),
        ),
      );

      return Container(
        margin: EdgeInsets.only(
          right: jxDimension.chatRoomSideMarginMaxGap,
          left: controller.chatController.chooseMore.value
              ? objectMgr.loginMgr.isDesktop
                  ? 48
                  : 40
              : (widget.chat.typ == chatTypeSingle
                  ? jxDimension.chatRoomSideMarginNoAva
                  : jxDimension.chatRoomSideMargin),
          bottom: isPinnedOpen ? 4 : 0,
        ),
        child: AbsorbPointer(
          absorbing: controller.chatController.popupEnabled,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              /// 头像
              Opacity(
                opacity: showAvatar ? 1 : 0,
                child: buildAvatar(),
              ),

              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    body,

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
                          onTap: () => controller.onViewReactList(
                              context, emojiUserList),
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: jxDimension.groupTextSenderMaxWidth(
                                hasAvatar: true,
                              ),
                            ),
                            margin: EdgeInsets.only(
                              left: jxDimension.chatBubbleLeftMargin,
                              bottom: 4,
                            ),
                            child: EmojiListItem(
                              specialBgColor: true,
                              emojiModelList: emojiUserList,
                              message: widget.message,
                              controller: controller,
                              maxWidth: jxDimension.groupTextSenderMaxWidth(
                                hasAvatar: true,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildAvatar() {
    if (controller.chat!.isSaveMsg) {
      return Container(
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
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

    if (controller.chat!.isSecretary) {
      return Image.asset(
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
        'assets/images/message_new/secretary.png',
        width: jxDimension.chatRoomAvatarSize(),
        height: jxDimension.chatRoomAvatarSize(),
      );
    }

    if (controller.chat!.isSystem) {
      return Image.asset(
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
        'assets/images/message_new/sys_notification.png',
        width: jxDimension.chatRoomAvatarSize(),
        height: jxDimension.chatRoomAvatarSize(),
      );
    }

    if (controller.chat!.isGroup) {
      return CustomAvatar.normal(
        key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
        sendID,
        size: jxDimension.chatRoomAvatarSize(),
        headMin: Config().headMin,
        onTap: sendID == 0
            ? null
            : () {
                Get.toNamed(
                  RouteName.chatInfo,
                  arguments: {
                    "uid": sendID,
                  },
                  id: objectMgr.loginMgr.isDesktop ? 1 : null,
                );
              },
        onLongPress: sendID == 0
            ? null
            : () async {
                User? user = await objectMgr.userMgr.loadUserById2(sendID);
                if (user != null) {
                  HapticFeedback.mediumImpact();
                  controller.inputController.onAppendMentionUser(user);
                }
              },
      );
    }

    return SizedBox(
      key: controller.chatController.popupEnabled ? null : avatarWidgetKey,
      width: controller.chatController.chat.isSingle ||
              controller.chatController.chat.isSystem
          ? 0
          : jxDimension.chatRoomAvatarSize(),
    );
  }

  Widget getImage() {
    return SizedBox(
      height: 148,
      child: RemoteImage(
        key: ValueKey(
          '${widget.message.message_id}_${widget.messageLocation.url}_${Config().messageMin}',
        ),
        src: widget.messageLocation.url,
        mini: Config().messageMin,
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }
}
