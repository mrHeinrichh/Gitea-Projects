import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/favourite/model/favourite_model.dart';
import 'package:jxim_client/im/custom_content/chat_content_controller.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_sheet.dart';
import 'package:jxim_client/im/custom_content/chat_pop_menu/chat_pop_menu_util.dart';
import 'package:jxim_client/im/custom_content/components/emoji_selector.dart';
import 'package:jxim_client/im/custom_content/message_widget/chat_read_num_view.dart';
import 'package:jxim_client/im/custom_content/message_widget/emoji_list_item.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_forward_component.dart';
import 'package:jxim_client/im/custom_content/message_widget/message_widget_mixin.dart';
import 'package:jxim_client/im/custom_content/message_widget/more_choose_view.dart';
import 'package:jxim_client/im/model/emoji_model.dart';
import 'package:jxim_client/im/services/chat_bubble_body.dart';
import 'package:jxim_client/im/services/chat_bubble_painter.dart';
import 'package:jxim_client/im/services/desktop_message_pop_menu.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/enums/enum.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/im_toast/overlay_extension.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/newline_device_utils.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views_desktop/component/desktop_general_dialog.dart';
import 'package:jxim_client/widgets/image/image_libs.dart';

class GroupFavouriteSender extends StatefulWidget {
  const GroupFavouriteSender({
    super.key,
    required this.controller,
    required this.message,
    required this.messageFavourite,
    required this.index,
    required this.chat,
    this.isPrevious = true,
  });

  final ChatContentController controller;
  final Chat chat;
  final Message message;
  final MessageFavourite messageFavourite;
  final int index;
  final bool isPrevious;

  @override
  State<GroupFavouriteSender> createState() => _GroupFavouriteSenderState();
}

class _GroupFavouriteSenderState
    extends MessageWidgetMixin<GroupFavouriteSender> {
  final GlobalKey targetWidgetKey = GlobalKey();
  final GlobalKey avatarWidgetKey = GlobalKey();

  final emojiUserList = <EmojiModel>[].obs;
  int sendID = 0;
  bool isDesktop = objectMgr.loginMgr.isDesktop;

  bool get isNote => widget.message.typ == messageTypeNote;

  bool get showForwardContent =>
      widget.messageFavourite.forward_user_id != 0 &&
      !widget.controller.chatController.chat.isSaveMsg;

  @override
  void initState() {
    super.initState();

    checkExpiredMessage(widget.message);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onAutoDeleteMsgTriggered);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onReactEmojiUpdate);

    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);

    initMessage(widget.controller.chatController, widget.index, widget.message);

    emojiUserList.value = widget.message.emojis;
    getRealSendID();
  }

  getRealSendID() {
    sendID = widget.message.send_id;
    if (widget.controller.chatController.chat.isSaveMsg) {
      sendID = widget.messageFavourite.forward_user_id;
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
        widget.controller.chatController.removeUnreadBar();
        checkDateMessage(data);
        isExpired.value = true;
      }
    }
  }

  onChatMessageDelete(sender, type, data) {
    if (data['id'] != widget.controller.chatController.chat.chat_id) {
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

  get isPinnedOpen => widget.controller.chatController.isPinnedOpened;

  bool get showAvatar =>
      !widget.controller.chat!.isSystem &&
      !widget.controller.chat!.isSecretary &&
      !widget.controller.chat!.isSingle &&
      (isLastMessage || widget.controller.chatController.isPinnedOpened);

  @override
  Widget build(BuildContext context) {
    Widget child = messageBody(context);

    return Obx(
      () => isExpired.value || isDeleted.value
          ? const SizedBox()
          : Stack(
              children: [
                GestureDetector(
                  key: targetWidgetKey,
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    tapPosition = details.globalPosition;
                    isPressed.value = true;
                  },
                  onTapUp: (details) {
                    if (widget.controller.isCTRLPressed()) {
                      desktopGeneralDialog(
                        context,
                        color: Colors.transparent,
                        widgetChild: DesktopMessagePopMenu(
                          offset: details.globalPosition,
                          emojiSelector: EmojiSelector(
                            chat: widget.controller.chatController.chat,
                            message: widget.message,
                            emojiMapList: emojiUserList,
                          ),
                          popMenu: ChatPopMenuSheet(
                            message: widget.message,
                            chat: widget.controller.chatController.chat,
                            sendID: widget.message.send_id,
                          ),
                          menuHeight: ChatPopMenuUtil.getMenuHeight(
                              widget.message,
                              widget.controller.chatController.chat,
                              extr: false),
                        ),
                      );
                    }
                    isPressed.value = false;
                    widget.controller.chatController.onCancelFocus();
                  },
                  onLongPress: () {
                    if (!objectMgr.loginMgr.isDesktop) {
                      enableFloatingWindow(
                        context,
                        widget.controller.chatController.chat.id,
                        widget.message,
                        child,
                        targetWidgetKey,
                        tapPosition,
                        ChatPopMenuSheet(
                          message: widget.message,
                          chat: widget.controller.chatController.chat,
                          sendID: widget.message.send_id,
                        ),
                        bubbleType: BubbleType.receiverBubble,
                        menuHeight: ChatPopMenuUtil.getMenuHeight(
                            widget.message,
                            widget.controller.chatController.chat),
                        topWidget: EmojiSelector(
                          chat: widget.controller.chatController.chat,
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
                            chat: widget.controller.chatController.chat,
                            message: widget.message,
                            emojiMapList: emojiUserList,
                          ),
                          popMenu: ChatPopMenuSheet(
                            message: widget.message,
                            chat: widget.controller.chatController.chat,
                            sendID: widget.message.send_id,
                          ),
                          menuHeight: ChatPopMenuUtil.getMenuHeight(
                              widget.message,
                              widget.controller.chatController.chat,
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
                  top: 0.0,
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  child: MoreChooseView(
                    chatController: widget.controller.chatController,
                    message: widget.message,
                    chat: widget.controller.chatController.chat,
                  ),
                ),
              ],
            ),
    );
  }

  void onCardTaped() async {
    try {
      Toast.showLoadingPopup(
          context, DialogType.loading, localized(isLoadingText));
      List<FavouriteData> data = await objectMgr.favouriteMgr
          .getFavouriteRemoteById([widget.messageFavourite.favouriteId]);
      if (data.isNotEmpty) {
        Get.toNamed(
          RouteName.favouriteDetailPage,
          arguments: {
            'favouriteData': data.first,
            'isShowHeader': false,
          },
        );
      } else {
        Toast.showLoadingPopup(
            context, DialogType.fail, localized(noteHasBeenDeleted));
      }
    } catch (e) {
      dismissAllToast();
      if (e is HttpException) {
        imBottomToast(
          Get.context!,
          title: localized(noNetworkPleaseTryAgainLater),
          icon: ImBottomNotifType.warning,
          duration: 1,
        );
      }
    }
  }

  Widget messageBody(BuildContext context) {
    return Obx(() {
      Widget body = IntrinsicWidth(
        child: GestureDetector(
          onTap: onCardTaped,
          child: Container(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width *
                  (objectMgr.loginMgr.isDesktop ? 0.3 : 0.5),
              maxWidth: MediaQuery.of(context).size.width *
                  (objectMgr.loginMgr.isDesktop ? 0.3 : 0.7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (isFirstMessage || isPinnedOpen)
                  Offstage(
                    offstage: widget.controller.chatController.chat.isSingle ||
                        widget.controller.chatController.chat.typ ==
                            chatTypeSystem,
                    child: NicknameText(
                      uid: sendID,
                      color: themeColor,
                      isRandomColor: true,
                      fontWeight: MFontWeight.bold5.value,
                      overflow: TextOverflow.ellipsis,
                      fontSize: bubbleNicknameSize,
                      groupId: widget.chat.isGroup ? widget.chat.id : null,
                    ),
                  ),
                if (showForwardContent)
                  MessageForwardComponent(
                    forwardUserId: widget.messageFavourite.forward_user_id,
                    maxWidth: jxDimension.groupTextSenderMaxWidth(),
                    isSender: true,
                  ),
                const SizedBox(height: 4.0),
                buildCard(),
              ],
            ),
          ),
        ),
      );

      BubblePosition position = isFirstMessage && isLastMessage
          ? BubblePosition.isFirstAndLastMessage
          : isLastMessage
              ? BubblePosition.isLastMessage
              : isFirstMessage
                  ? BubblePosition.isFirstMessage
                  : BubblePosition.isMiddleMessage;

      if (widget.controller.chatController.isPinnedOpened) {
        position = BubblePosition.isLastMessage;
      }

      body = Container(
        padding: EdgeInsets.only(left: jxDimension.chatRoomSideMarginAvaR),
        child: ChatBubbleBody(
          position: position,
          verticalPadding: chatBubbleBodyVerticalPadding,
          horizontalPadding: chatBubbleBodyHorizontalPadding,
          isPressed: isPressed.value,
          constraints: BoxConstraints(
            maxWidth: jxDimension.groupTextSenderMaxWidth(),
          ),
          body: Stack(
            children: <Widget>[
              Column(
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
                        onTap: () => widget.controller
                            .onViewReactList(context, emojiUserList),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: jxDimension.groupTextSenderMaxWidth(),
                          ),
                          child: EmojiListItem(
                            emojiModelList: emojiUserList,
                            message: widget.message,
                            controller: widget.controller,
                            eMargin: EmojiMargin.sender,
                          ),
                        ),
                      ),
                    );
                  }),
                  if (emojiUserList.isEmpty) const SizedBox(height: 20.0),
                ],
              ),
              Positioned(
                right: 0.0,
                bottom: 0.0,
                child: ChatReadNumView(
                  message: widget.message,
                  chat: widget.controller.chatController.chat,
                  showPinned: widget.controller.chatController.pinMessageList
                          .firstWhereOrNull((pinnedMsg) =>
                              pinnedMsg.id == widget.message.id) !=
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
          left: widget.controller.chatController.chooseMore.value
              ? 40
              : (widget.controller.chatController.chat.typ == chatTypeSingle
                  ? jxDimension.chatRoomSideMarginSingle
                  : jxDimension.chatRoomSideMargin),
        ),
        child: AbsorbPointer(
          absorbing: widget.controller.chatController.popupEnabled,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              /// 头像
              Opacity(
                opacity: showAvatar ? 1 : 0,
                child: buildAvatar(),
              ),

              body,
            ],
          ),
        ),
      );
    });
  }

  Widget buildAvatar() {
    if (widget.controller.chatController.chat.isSaveMsg) {
      return Container(
        key: widget.controller.chatController.popupEnabled
            ? null
            : avatarWidgetKey,
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

    if (widget.controller.chatController.chat.isSecretary) {
      return Image.asset(
        key: widget.controller.chatController.popupEnabled
            ? null
            : avatarWidgetKey,
        'assets/images/message_new/secretary.png',
        width: 36,
        height: 36,
      );
    }

    if (widget.controller.chatController.chat.isSystem) {
      return Image.asset(
        key: widget.controller.chatController.popupEnabled
            ? null
            : avatarWidgetKey,
        'assets/images/message_new/sys_notification.png',
        width: 36,
        height: 36,
      );
    }

    if (widget.controller.chatController.chat.isGroup) {
      return CustomAvatar.normal(
        key: widget.controller.chatController.popupEnabled
            ? null
            : avatarWidgetKey,
        sendID,
        size: jxDimension.chatRoomAvatarSize(),
        headMin: Config().headMin,
        onTap: sendID == 0
            ? null
            : () {
                Get.toNamed(RouteName.chatInfo,
                    arguments: {
                      "uid": sendID,
                    },
                    id: objectMgr.loginMgr.isDesktop ? 1 : null);
              },
        onLongPress: sendID == 0
            ? null
            : () async {
                User? user = await objectMgr.userMgr.loadUserById2(sendID);
                if (user != null) {
                  HapticFeedback.mediumImpact();
                  widget.controller.inputController.onAppendMentionUser(user);
                }
              },
      );
    }

    return SizedBox(
      key: widget.controller.chatController.popupEnabled
          ? null
          : avatarWidgetKey,
      width: widget.controller.chatController.chat.isSingle ||
              widget.controller.chatController.chat.isSystem
          ? 0
          : jxDimension.chatRoomAvatarSize(),
    );
  }

  Widget buildCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 4),
        decoration: BoxDecoration(
          color: colorTextPrimary.withOpacity(0.03),
          border: Border(
            left: BorderSide(
              color: themeColor,
              width: 3.0,
              style: BorderStyle.solid,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isNote ? _buildNoteView() : _buildChatHistoryView(),
            const SizedBox(height: 8),
            Divider(
              color: colorTextPrimary.withOpacity(0.2),
              thickness: 0.33,
              height: 1,
            ),
            SizedBox(
              height: 32,
              child: Center(
                child: Text(
                  isNote
                      ? localized(viewFavouriteNote)
                      : localized(viewFavouriteChatHistory),
                  style: TextStyle(
                    color: themeColor,
                    // color: _friendCardThemeColor,
                    fontSize: 14,
                    fontWeight: MFontWeight.bold5.value,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteView() {
    String title = widget.messageFavourite.title;
    List<String> contentList = widget.messageFavourite.subTitles;
    List<dynamic> mediaList = widget.messageFavourite.mediaList;

    int contentLine = 1;
    if (contentList.length == 1) {
      contentLine = 4;
    } else if (contentList.length == 2) {
      contentLine = 2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Visibility(
          visible: title.isNotEmpty,
          child: Text(
            title,
            maxLines: 1,
            style: jxTextStyle.normalText(fontWeight: MFontWeight.bold5.value),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...List.generate(contentList.length.clamp(0, 4), (index) {
          String content = contentList[index];
          if (index == 1 && contentList.length > 2) {
            content += "...";
          }
          return Text(
            content,
            style: jxTextStyle.normalText(color: colorTextSecondary),
            maxLines: contentLine,
            overflow: TextOverflow.ellipsis,
          );
        }),
        Visibility(
          visible: mediaList.isNotEmpty,
          child: SizedBox(
            width: 200,
            height: 50,
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisSpacing: 4.0,
                crossAxisCount: 4,
              ),
              itemCount: mediaList.length > 4
                  ? mediaList.sublist(0, 4).length
                  : mediaList.length,
              itemBuilder: (BuildContext context, int index) {
                return _buildMedia(mediaList[index], mediaList.length, index);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedia(FavouriteDetailData media, int length, int index) {
    int remainCount = length - 4;
    String path = "";
    String gausPath = "";
    if (media.typ == FavouriteTypeVideo) {
      FavouriteVideo favourite = objectMgr.favouriteMgr
          .getFavouriteContent(media.typ, media.content ?? '');
      path = favourite.cover;
      gausPath = favourite.gausPath;
    } else {
      FavouriteImage favourite = objectMgr.favouriteMgr
          .getFavouriteContent(media.typ, media.content ?? '');
      path = favourite.url;
      gausPath = favourite.gausPath;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          RemoteGaussianImage(
            src: path,
            gaussianPath: gausPath,
            width: 46,
            height: 46,
            fit: BoxFit.cover,
          ),
          if (index == 3 && remainCount > 0)
            Positioned.fill(
              child: Stack(
                children: [
                  Container(
                    color: colorTextPlaceholder,
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Text(
                      "(${remainCount.toString()})",
                      style: jxTextStyle.supportText(color: colorWhite),
                    ),
                  )
                ],
              ),
            ),
          _buildVideoIcon(media.typ),
        ],
      ),
    );
  }

  Widget _buildVideoIcon(int type) {
    if (type == FavouriteTypeVideo) {
      return SvgPicture.asset(
        'assets/svgs/video_play_icon.svg',
        width: 20,
        height: 20,
      );
    }
    return const SizedBox();
  }

  Widget _buildChatHistoryView() {
    String title = widget.messageFavourite.title;
    List<String> contentList = widget.messageFavourite.subTitles;

    int contentLine = 1;
    if (contentList.length == 1) {
      contentLine = 4;
    } else if (contentList.length == 2) {
      contentLine = 2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: jxTextStyle.normalText(fontWeight: MFontWeight.bold5.value),
        ),
        ...List.generate(
            contentList.length > 4
                ? contentList.sublist(0, 4).length
                : contentList.length, (index) {
          String content = contentList[index];
          if (index == 3 && contentList.length > 4) {
            content = content + "...";
          }
          return Text(
            content,
            style: jxTextStyle.normalText(color: colorTextSecondary),
            maxLines: contentLine,
            overflow: TextOverflow.ellipsis,
          );
        }),
      ],
    );
  }
}
