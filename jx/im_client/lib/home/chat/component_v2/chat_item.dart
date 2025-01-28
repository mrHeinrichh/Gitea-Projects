import 'dart:convert';
import 'dart:ui';

import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/component_v2/chat_interaction_mixin.dart';
import 'package:jxim_client/home/chat/components/chat_cell_content_factory.dart';
import 'package:jxim_client/home/chat/components/chat_cell_mute_action_pane.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/im/custom_input/component/text_input_field.dart';
import 'package:jxim_client/im/group_chat/group_chat_view.dart';
import 'package:jxim_client/im/services/animated_flip_counter.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/group_mgr.dart';
import 'package:jxim_client/managers/message_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/online_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/chat_input.dart';
import 'package:jxim_client/object/chat/draft_model.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/tasks/chat_typing_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/theme/dimension_styles.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/views/component/component.dart';
import 'package:jxim_client/views/component/special_avatar/saved_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/secretary_message_icon.dart';
import 'package:jxim_client/views/component/special_avatar/system_message_icon.dart';
import 'package:lottie/lottie.dart';

class ChatItem extends StatefulWidget {
  final Chat chat;

  final bool isSearching;
  final bool isEditing;
  final bool isSelected;

  const ChatItem({
    super.key,
    required this.chat,
    this.isSearching = false,
    this.isSelected = false,
    this.isEditing = false,
  });

  @override
  State<ChatItem> createState() => _ChatItemState();
}

class _ChatItemState extends State<ChatItem>
    with TickerProviderStateMixin, ChatInteractionMixin {
  final controller = Get.find<ChatListController>();

  /// Slidable 使用参数
  bool animationPlayed = false;
  late final SlidableController _slidableController;
  late AnimationController _drawerIconController;

  RxBool isOnline = false.obs;

  /// 临时群组
  RxBool isGroupExpireSoon = false.obs;

  /// 最后一条消息
  late Rx<Message?> lastMessage;

  // 聊天室消息发送状态
  RxInt lastMsgSendState = MESSAGE_SEND_SUCCESS.obs;
  RxBool messageIsRead = false.obs;

  // 聊天消息草稿
  RxString draftString = ''.obs;

  // 输入状态
  RxBool isTyping = false.obs;

  /// 聊天室是否静音
  RxBool isMuted = false.obs;

  // 语音消息是否已读
  RxBool isVoicePlayed = false.obs;

  // 未读消息数
  RxInt unreadCount = 0.obs;

  /// LIFECYCLE

  @override
  void initState() {
    super.initState();

    _drawerIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slidableController = SlidableController(this);
    _slidableController.animation.addListener(_handleAnimationChange);

    lastMessage = objectMgr.chatMgr.lastChatMessageMap[widget.chat.chat_id].obs;

    if (lastMessage.value != null) {
      lastMsgSendState.value = lastMessage.value!.sendState;
      if (lastMsgSendState.value == MESSAGE_SEND_FAIL &&
          (lastMessage.value!.typ == messageTypeImage ||
              lastMessage.value!.typ == messageTypeVideo ||
              lastMessage.value!.typ == messageTypeNewAlbum)) {
        objectMgr.chatMgr.showNotification(lastMessage.value!);
      }

      // 初始化语音消息是否已读
      updateVoicePlayed();

      // 初始化消息是否已读
      messageIsRead.value =
          widget.chat.other_read_idx >= lastMessage.value!.chat_idx &&
              lastMessage.value!.isSendOk;
    }

    initOnlineStatus();

    isMuted.value = widget.chat.isMute;
    // 初始化草稿内容, 如果有
    draftString.value =
        objectMgr.chatMgr.getChatDraft(widget.chat.id)?.input ?? '';

    if (lastMessage.value != null) {
      if (lastMessage.value!.isEncrypted) {
        MessageMgr.decodeMsg(
          lastMessage.value!,
          widget.chat,
          objectMgr.userMgr.mainUser.uid,
        );
      }
      updateUser(lastMessage.value!.send_id);
    }

    if (!widget.chat.isDisband) {
      unreadCount.value = widget.chat.unread_count;

      objectMgr.chatMgr.on(ChatMgr.eventAllLastMessageLoaded, _onNewMessage);
      objectMgr.chatMgr.on(ChatMgr.eventChatLastMessageChanged, _onNewMessage);
      objectMgr.chatMgr.on(ChatMgr.eventEditMessage, _onNewMessage);
      objectMgr.chatMgr.on(ChatMgr.eventReadMessage, _onNewMessage);

      objectMgr.chatMgr.on(ChatMgr.eventChatIsTyping, _onChatInput);
      objectMgr.chatMgr.on(ChatMgr.eventVoicePlayUpdate, _onMessageVoicePlayed);
      objectMgr.chatMgr.on(ChatMgr.eventFileOperateDoMsg, _onFileOperateDoMsg);

      objectMgr.chatMgr.on(ChatMgr.eventUpdateUnread, _onUnreadUpdate);
      objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onUnreadUpdate);

      if (lastMessage.value != null && lastMessage.value!.isSendSlow) {
        objectMgr.chatMgr.on(Message.eventSendState, _onMsgSendStateChange);
      }
    }
    objectMgr.chatMgr.on(ChatMgr.eventChatDisband, _onUnreadUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventChatMuteChanged, _onMuteChanged);

    if (widget.chat.isEncrypted) {
      objectMgr.chatMgr.on(ChatMgr.eventDecryptChat, _onDecryptChat);
      objectMgr.chatMgr
          .on(ChatMgr.eventChatEncryptionUpdate, _onChangeEncryptionUpdate);
    }

    objectMgr.chatMgr.on(
      '${widget.chat.id}_${ChatMgr.eventDraftUpdate}',
      _onDraftUpdate,
    );

    if (widget.chat.isSingle) {
      objectMgr.onlineMgr.on(
        OnlineMgr.eventLastSeenStatus,
        _onLastSeenChanged,
      );
    }

    if (widget.chat.isGroup) {
      objectMgr.myGroupMgr.on(
        MyGroupMgr.eventTmpGroupLessThanADay,
        _onGroupIsExpired,
      );
    }

    if (Get.isRegistered<HomeController>()) {
      final homeC = Get.find<HomeController>();
      homeC.tabController?.addListener(_homePageChangeListener);
    }
  }

  @override
  void didUpdateWidget(ChatItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.chat.hashCode != widget.chat.hashCode ||
        oldWidget.isSearching != widget.isSearching ||
        oldWidget.isEditing != widget.isEditing ||
        oldWidget.isSelected != widget.isSelected) {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventAllLastMessageLoaded, _onNewMessage);
    objectMgr.chatMgr.off(ChatMgr.eventChatLastMessageChanged, _onNewMessage);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, _onNewMessage);
    objectMgr.chatMgr.off(ChatMgr.eventReadMessage, _onNewMessage);

    objectMgr.chatMgr.off(ChatMgr.eventChatIsTyping, _onChatInput);
    objectMgr.chatMgr.off(ChatMgr.eventVoicePlayUpdate, _onMessageVoicePlayed);
    objectMgr.chatMgr.off(ChatMgr.eventFileOperateDoMsg, _onFileOperateDoMsg);

    objectMgr.chatMgr.off(ChatMgr.eventAutoDeleteMsg, _onUnreadUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventUpdateUnread, _onUnreadUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventChatDisband, _onUnreadUpdate);

    objectMgr.chatMgr.off(ChatMgr.eventChatMuteChanged, _onMuteChanged);

    objectMgr.chatMgr.off(ChatMgr.eventDecryptChat, _onDecryptChat);
    objectMgr.chatMgr
        .off(ChatMgr.eventChatEncryptionUpdate, _onChangeEncryptionUpdate);

    objectMgr.chatMgr.off(
      '${widget.chat.id}_${ChatMgr.eventDraftUpdate}',
      _onDraftUpdate,
    );

    if (widget.chat.isSingle) {
      objectMgr.onlineMgr.off(
        OnlineMgr.eventLastSeenStatus,
        _onLastSeenChanged,
      );
    }

    if (widget.chat.isGroup) {
      objectMgr.myGroupMgr.off(
        MyGroupMgr.eventTmpGroupLessThanADay,
        _onGroupIsExpired,
      );
    }

    if (Get.isRegistered<HomeController>()) {
      final homeC = Get.find<HomeController>();
      homeC.tabController?.removeListener(_homePageChangeListener);
    }

    _slidableController.animation.removeListener(_handleAnimationChange);
    _slidableController.dispose();
    _drawerIconController.dispose();
    super.dispose();
  }

  /// INIT METHOD

  void initOnlineStatus() async {
    if (!widget.chat.isSingle) return;

    User? user = objectMgr.userMgr.getUserById(widget.chat.friend_id);

    if (user != null) {
      isOnline.value =
          objectMgr.onlineMgr.friendOnlineString[widget.chat.friend_id] ==
              localized(chatOnline);
    }

    user = await objectMgr.userMgr.loadUserById(widget.chat.friend_id);
    isOnline.value =
        objectMgr.onlineMgr.friendOnlineString[widget.chat.friend_id] ==
            localized(chatOnline);
  }

  void updateVoicePlayed() {
    if (lastMessage.value != null &&
        lastMessage.value?.typ == messageTypeVoice) {
      MessageVoice messageVoice =
          lastMessage.value!.decodeContent(cl: MessageVoice.creator);
      if (!isVoicePlayed.value) {
        isVoicePlayed.value = (messageVoice.isOperated == null) ||
            lastMessage.value!.isContentViewed;
      }
    }
  }

  /// LISTENER

  void _handleAnimationChange() {
    if (!mounted) return;

    final offset = _slidableController.animation.value;

    if (!animationPlayed && offset > _animationTriggerThreshold(context)) {
      animationPlayed = true;
      // start animation
      _drawerIconController.forward();
    }

    if (offset == 0) {
      animationPlayed = false;
      // reset animation
      _drawerIconController.reset();
    }
  }

  void _homePageChangeListener() => _slidableController.close();

  double _animationTriggerThreshold(BuildContext context) {
    final singleRatio = _getOneActionPaneRatio(context);
    final ratio = switch (_slidableController.actionPaneType.value) {
      ActionPaneType.start => singleRatio,
      ActionPaneType.end =>
        !widget.chat.isSpecialChat ? singleRatio * 3 : singleRatio,
      _ => 0.0
    };
    return 0.5 * ratio;
  }

  double _getOneActionPaneRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final ratio = 74 / screenWidth;
    return ratio;
  }

  /// 监听器
  void _onNewMessage(_, __, Object? data) {
    // 不同聊天室不需要刷新
    if (data is Message && data.chat_id != widget.chat.id) return;

    if (data is Map<String, dynamic> && data['id'] != widget.chat.id) return;
    if (widget.chat.isDisband) return;

    final latestMsg = objectMgr.chatMgr.getLatestMessage(widget.chat.id);

    if (latestMsg != null) {
      if (latestMsg.ref_typ != 0 &&
          lastMessage.value != null &&
          lastMessage.value!.chat_idx == latestMsg.chat_idx &&
          lastMessage.value!.ref_typ == 0) {
        return;
      }
      lastMessage.value?.off(Message.eventSendState, _onMsgSendStateChange);
      lastMessage.value = null;
      lastMessage.value = latestMsg;

      updateVoicePlayed();

      updateUser(lastMessage.value!.send_id);

      lastMsgSendState.value = lastMessage.value!.sendState;
      if (lastMessage.value!.sendState != MESSAGE_SEND_SUCCESS) {
        lastMessage.value!.on(Message.eventSendState, _onMsgSendStateChange);
      } else if (lastMessage.value!.edit_time != 0) {
        // update();
      }

      messageIsRead.value =
          widget.chat.other_read_idx >= lastMessage.value!.chat_idx &&
              lastMessage.value!.isSendOk;
    } else {
      lastMessage.value?.off(Message.eventSendState, _onMsgSendStateChange);
      lastMessage.value = null;
    }
    _onUnreadUpdate(sender, type, data ?? widget.chat.toJson());
  }

  void _onMsgSendStateChange(_, __, Object? data) {
    if (data is Message &&
        data.id == lastMessage.value?.id &&
        data.sendState != lastMsgSendState.value) {
      lastMsgSendState.value = data.sendState;
    }

    if (data is Message && lastMsgSendState.value != MESSAGE_SEND_ING) {
      lastMessage.value?.off(Message.eventSendState, _onMsgSendStateChange);
    }
  }

  /// 临时群组事件
  void _onGroupIsExpired(_, __, Object? data) {
    if (data == null || data is! Map<String, dynamic>) return;
    if (data['id'] != widget.chat.id) return;

    isGroupExpireSoon.value = data['isExpiring'];
  }

  /// 单聊在线状态事件
  void _onLastSeenChanged(Object sender, Object type, Object? data) {
    isOnline.value =
        objectMgr.onlineMgr.friendOnlineString[widget.chat.friend_id] ==
            localized(chatOnline);
  }

  /// 监听输入草稿
  void _onDraftUpdate(_, __, ___) {
    DraftModel? draftModel =
        objectMgr.chatMgr.getChatDraft(widget.chat.chat_id);

    if (draftModel != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        draftString.value = draftModel.input;
      });
    }
  }

  /// 监听输入状态
  void _onChatInput(_, __, Object? data) {
    if (data is! ChatInput || data.chatId != widget.chat.id) return;
    if (widget.chat.isDisband) return;

    isTyping.value = data.state != ChatInputState.noTyping;
  }

  void _onMessageVoicePlayed(_, __, Object? data) {
    if (data is! Map ||
        data['message_id'] == null ||
        data['message_id'] != lastMessage.value?.message_id) {
      return;
    }
    if (lastMessage.value?.send_id == objectMgr.userMgr.mainUser.uid) {
      //如果是自己点击自己发送的语音消息，不视为语音被已读
      return;
    }

    isVoicePlayed.value = true;
  }

  void _onFileOperateDoMsg(Object sender, Object type, Object? msg) async {
    if (msg is! Message) return;
    if (msg.chat_id != widget.chat.chat_id) return;
    final data = json.decode(msg.content);
    if (data == null || data["message_id"] == null || data["uid"] == null) {
      return;
    }
    bool isMeInReceivers = msg.send_id == objectMgr.userMgr.mainUser.uid ||
        data["uid"] == objectMgr.userMgr.mainUser.uid;
    //如果不是我点击播放的 或者 是我发送的语音消息
    if (!isMeInReceivers) {
      return;
    }
    int msgId = data["message_id"];
    if (msgId != lastMessage.value?.message_id) {
      return;
    }

    isVoicePlayed.value = true;
  }

  void _onUnreadUpdate(_, Object type, data) {
    if (data == null) return;

    int chatId = -1;
    if (data is Message) {
      if (type is String && type == ChatMgr.eventAutoDeleteMsg) {
        objectMgr.chatMgr.removeMentionCache(data.chat_id, data.chat_idx);
      }
      chatId = data.chat_id;
    } else if (data is Chat) {
      chatId = data.chat_id;
    } else if (data is int) {
      chatId = data;
    } else {
      chatId = data['id'];
    }

    if (chatId != widget.chat.id || widget.chat.isSaveMsg) return;

    // 准确数据的chat (Q: 需要?)
    Chat? accurateChat = objectMgr.chatMgr.getChatById(widget.chat.id);
    if (accurateChat == null) return;

    if (lastMessage.value != null) {
      messageIsRead.value =
          widget.chat.other_read_idx >= lastMessage.value!.chat_idx &&
              lastMessage.value!.isSendOk;
    }
    unreadCount.value = accurateChat.unread_count;
  }

  void _onMuteChanged(_, __, Object? data) {
    if (data is! Chat || data.id != widget.chat.id) return;

    isMuted.value = data.isMute;
  }

  void _onDecryptChat(Object sender, Object type, Object? data) {
    if (data is int && data == widget.chat.chat_id) {
      if (mounted) setState(() {});
      return;
    }

    if (data is! List<Chat> ||
        lastMessage.value == null ||
        lastMessage.value != null &&
            (lastMessage.value!.ref_typ == 0 ||
                lastMessage.value!.ref_typ == 4)) return;
    for (var item in data) {
      if (item.chat_id == widget.chat.chat_id) {
        if (item.isActiveChatKeyValid) {
          try {
            MessageMgr.decodeMsg(
                lastMessage.value!, item, objectMgr.userMgr.mainUser.uid);
            if (mounted) setState(() {});
          } catch (e) {
            lastMessage.value!.ref_typ = 4;
            pdebug("_onDecryptChat aes decrypt err: $e");
          }
          return;
        }
      }
    }
  }

  void _onChangeEncryptionUpdate(sender, type, data) {
    if (data is Chat && widget.chat.id == data.id && mounted) {
      setState(() {});
    }
  }

  /// 更新用户id
  void updateUser(uid) {
    if (objectMgr.userMgr.getUserById(uid) == null) {
      objectMgr.userMgr.loadUserById(uid).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  // 聊天室点击事件
  void onItemClick() {
    if (!enableEdit) return;

    if (widget.isEditing) {
      if (!widget.chat.isSpecialChat) {
        controller.isEditing.value = true;
        if (controller.selectedChatIDForEdit.contains(widget.chat.id)) {
          controller.selectedChatIDForEdit.remove(widget.chat.id);
        } else {
          controller.selectedChatIDForEdit.add(widget.chat.id);
        }
      }
      return;
    }

    controller.clearSearching(isUnfocus: true);

    Routes.toChat(chat: widget.chat);
  }

  // 聊天室长按事件
  void onItemLongPress() {
    if (!enableEdit) return;

    controller.isEditing.value = true;
    if (!widget.chat.isSpecialChat) {
      if (controller.selectedChatIDForEdit.contains(widget.chat.id)) {
        controller.selectedChatIDForEdit.remove(widget.chat.id);
      } else {
        controller.selectedChatIDForEdit.add(widget.chat.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(widget.chat.id),
      controller: _slidableController,
      enabled: !objectMgr.loginMgr.isDesktop && !widget.isSearching,
      closeOnScroll: true,
      startActionPane: createStartActionPane(context),
      endActionPane: createEndActionPane(context),
      child: createItemView(context),
    );
  }

  ActionPane createStartActionPane(BuildContext context) {
    return ActionPane(
      motion: const DrawerMotion(),
      extentRatio: _getOneActionPaneRatio(context),
      children: [
        CustomSlidableAction(
          onPressed: (context) => controller.onPinnedChat(
            context,
            widget.chat,
          ),
          backgroundColor: colorGreen,
          foregroundColor: colorWhite,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Lottie.asset(
                  widget.chat.sort != 0
                      ? 'assets/lottie/chat_slidable_unpin.json'
                      : 'assets/lottie/chat_slidable_pin.json',
                  controller: _drawerIconController,
                ),
              ),
              Text(
                widget.chat.sort != 0
                    ? localized(chatUnpin)
                    : localized(chatPin),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: jxTextStyle.slidableTextStyle(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ActionPane createEndActionPane(BuildContext context) {
    final actions = createEndActionChildren(context);
    final actionCount = actions.length;
    final onePaneRatio = _getOneActionPaneRatio(context);
    return ActionPane(
      motion: const DrawerMotion(),
      extentRatio: onePaneRatio * actionCount,
      children: createEndActionChildren(context),
    );
  }

  List<Widget> createEndActionChildren(BuildContext context) {
    List<Widget> listChildren = [];

    if (!widget.chat.isSpecialChat) {
      /// Mute
      listChildren.add(
        ChatCellMuteActionPane(
          chat: widget.chat,
          drawerController: _drawerIconController,
        ),
      );

      /// Delete
      listChildren.add(
        CustomSlidableAction(
          onPressed: (context) => onDeleteChat(context, widget.chat),
          backgroundColor: colorRed,
          foregroundColor: colorWhite,
          padding: EdgeInsets.zero,
          flex: 7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Lottie.asset(
                  'assets/lottie/chat_slidable_dustbin.json',
                  controller: _drawerIconController,
                ),
              ),
              Text(
                localized(chatDelete),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: jxTextStyle.slidableTextStyle(),
              ),
            ],
          ),
        ),
      );

      /// Hide
      listChildren.add(
        CustomSlidableAction(
          onPressed: (context) => showHideChatDialog(context, widget.chat),
          backgroundColor: colorGrey,
          foregroundColor: colorWhite,
          padding: EdgeInsets.zero,
          flex: 7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Lottie.asset(
                  'assets/lottie/chat_slidable_hide.json',
                  controller: _drawerIconController,
                ),
              ),
              Text(
                localized(chatOptionsHide),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: jxTextStyle.slidableTextStyle(),
              ),
            ],
          ),
        ),
      );
    } else {
      /// Mute
      listChildren.add(
        ChatCellMuteActionPane(
          chat: widget.chat,
          drawerController: _drawerIconController,
        ),
      );

      /// Clear
      listChildren.add(
        CustomSlidableAction(
          onPressed: (context) => onClearChat(context, widget.chat),
          backgroundColor: colorRed,
          foregroundColor: colorWhite,
          padding: EdgeInsets.zero,
          flex: 7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Lottie.asset(
                  'assets/lottie/chat_slidable_dustbin.json',
                  controller: _drawerIconController,
                ),
              ),
              Text(
                localized(chatClear),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: jxTextStyle.slidableTextStyle(),
              ),
            ],
          ),
        ),
      );
    }

    return listChildren;
  }

  Widget createItemView(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onItemClick,
      onLongPress: onItemLongPress,
      child: Obx(
        () => AbsorbPointer(
          absorbing: controller.isEditing.value && widget.chat.isSpecialChat,
          child: Opacity(
            opacity: controller.isEditing.value && widget.chat.isSpecialChat
                ? 0.4
                : 1.0,
            child: Container(
              color: widget.chat.sort != 0 ? colorBgPin : colorSurface,
              foregroundDecoration: BoxDecoration(
                color: widget.isSelected
                    ? themeColor.withOpacity(0.08)
                    : Colors.transparent,
              ),
              height: maxChatCellHeight,
              child: OverlayEffect(
                child: Container(
                  padding: jxDimension.messageCellPadding(),
                  child: Row(
                    children: <Widget>[
                      ClipRRect(
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 350),
                          alignment: Alignment.centerLeft,
                          curve: Curves.easeInOutCubic,
                          widthFactor: controller.isEditing.value ? 1 : 0,
                          child: Container(
                            padding: const EdgeInsets.only(right: 8),
                            child: CheckTickItem(isCheck: widget.isSelected),
                          ),
                        ),
                      ),

                      /// 頭像
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 2.0,
                          right: 10.0,
                        ),
                        child: buildHeadView(context),
                      ),

                      /// 內容
                      Expanded(
                        child: Container(
                          height: maxChatCellHeight,
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              _titleBuilder(context),
                              const SizedBox(height: 4.0),
                              _contentBuilder(context),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ), //OverlayEffect(child: child),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHeadView(BuildContext context) {
    return switch (widget.chat.typ) {
      chatTypeSingle => Stack(
          children: <Widget>[
            CustomAvatar.chat(
              key: ValueKey('chat_single_avatar_${widget.chat.id}'),
              widget.chat,
              size: jxDimension.chatListAvatarSize(),
              headMin: Config().headMin,
              fontSize: 24.0,
              shouldAnimate: false,
            ),
            if (widget.chat.autoDeleteInterval > 0 &&
                !widget.chat.enableAudioChat.value)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: colorTextPlaceholder,
                    shape: BoxShape.circle,
                  ),
                  height: 20,
                  width: 20,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      SvgPicture.asset(
                        'assets/svgs/icon_auto_delete.svg',
                        fit: BoxFit.contain,
                        height: 19,
                        width: 19,
                      ),
                      Text(
                        parseAutoDeleteInterval(widget.chat.autoDeleteInterval),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: MFontWeight.bold6.value,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (isOnline.value && !widget.chat.enableAudioChat.value)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.0),
                  ),
                  height: 16,
                  width: 16,
                ),
              )
            else if (widget.chat.enableAudioChat.value)
              Positioned(
                right: 0,
                bottom: 0,
                child: SvgPicture.asset(
                  'assets/svgs/agora_mark_icon.svg',
                  width: 20,
                  height: 20,
                ),
              ),
          ],
        ),
      chatTypeGroup||chatTypeMiniApp => Stack(
          children: <Widget>[
            CustomAvatar.chat(
              key: ValueKey('${widget.chat.id}_${Config().headMin}_24'),
              widget.chat,
              size: jxDimension.chatListAvatarSize(),
              headMin: Config().headMin,
              fontSize: 24.0,
              shouldAnimate: false,
            ),
            if (widget.chat.autoDeleteInterval > 0)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorOverlay40,
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        margin: const EdgeInsets.all(1),
                        height: 20,
                        width: 20,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            SvgPicture.asset(
                              'assets/svgs/icon_auto_delete.svg',
                              fit: BoxFit.contain,
                              height: 19,
                              width: 19,
                            ),
                            Text(
                              parseAutoDeleteInterval(
                                widget.chat.autoDeleteInterval,
                              ),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: MFontWeight.bold6.value,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      chatTypeSaved => SavedMessageIcon(
          size: jxDimension.chatListAvatarSize(),
        ),
      chatTypeSystem => SystemMessageIcon(
          size: jxDimension.chatListAvatarSize(),
        ),
      chatTypeSmallSecretary => SecretaryMessageIcon(
          size: jxDimension.chatListAvatarSize(),
        ),
      _ => const SizedBox()
    };
  }

  Widget _titleBuilder(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: _buildNameView(context)),
        const SizedBox(width: 12.0),
        _buildTimeView(context),
      ],
    );
  }

  Widget _buildNameView(BuildContext context) {
    return switch (widget.chat.typ) {
      chatTypeSingle => Obx(
          () => Row(
            children: <Widget>[
              if (widget.chat.isEncrypted)
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: SvgPicture.asset(
                    'assets/svgs/chat_icon_encrypted.svg',
                    width: 16,
                    height: 16,
                  ),
                ),
              Flexible(
                child: NicknameText(
                  uid: widget.chat.friend_id,
                  displayName: widget.chat.name,
                  fontSize: MFontSize.size17.value,
                  fontWeight: MFontWeight.bold5.value,
                  color: colorTextPrimary.withOpacity(1),
                  isTappable: false,
                  overflow: TextOverflow.ellipsis,
                  fontSpace: 0,
                ),
              ),
              if (isMuted.value)
                Padding(
                  padding: const EdgeInsets.only(left: 3.0),
                  child: SvgPicture.asset(
                    'assets/svgs/mute_icon3.svg',
                    width: 16,
                    height: 16,
                    fit: BoxFit.fill,
                  ),
                ),
            ],
          ),
        ),
      chatTypeGroup => Obx(
          () => Row(
            children: <Widget>[
              Visibility(
                visible: widget.chat.isEncrypted,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: SvgPicture.asset(
                    'assets/svgs/chat_icon_encrypted.svg',
                    width: 16,
                    height: 16,
                  ),
                ),
              ),
              Flexible(
                child: NicknameText(
                  uid: widget.chat.isSingle
                      ? widget.chat.friend_id
                      : widget.chat.id,
                  displayName: widget.chat.name,
                  fontSize: MFontSize.size17.value,
                  fontWeight: MFontWeight.bold5.value,
                  color: colorTextPrimary.withOpacity(1),
                  isTappable: false,
                  isGroup: widget.chat.isGroup,
                  overflow: TextOverflow.ellipsis,
                  fontSpace: 0,
                ),
              ),
              if (widget.chat.isTmpGroup)
                Obx(
                  () => Padding(
                    padding: const EdgeInsets.only(left: 2.0),
                    child: SvgPicture.asset(
                      'assets/svgs/temporary_indicator.svg',
                      width: 16,
                      height: 16,
                      fit: BoxFit.fill,
                      colorFilter: ColorFilter.mode(
                        isGroupExpireSoon.value ? colorRed : themeColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              if (isMuted.value)
                Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: SvgPicture.asset(
                    'assets/svgs/mute_icon3.svg',
                    width: 16,
                    height: 16,
                    fit: BoxFit.fill,
                  ),
                ),
            ],
          ),
        ),
      chatTypeSaved => Obx(
          () => Row(
            children: <Widget>[
              Visibility(
                visible: widget.chat.isEncrypted,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: SvgPicture.asset(
                    'assets/svgs/chat_icon_encrypted.svg',
                    width: 16,
                    height: 16,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  localized(homeSavedMessage),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: MFontWeight.bold5.value,
                    fontSize: MFontSize.size17.value,
                    color: colorTextPrimary.withOpacity(1),
                    decoration: TextDecoration.none,
                    letterSpacing: 0,
                    overflow: TextOverflow.ellipsis,
                    height: 1.2,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: SvgPicture.asset(
                  'assets/svgs/secretary_check_icon.svg',
                  width: 15,
                  height: 15,
                  color: themeColor,
                  fit: BoxFit.fitWidth,
                ),
              ),
              if (isMuted.value)
                Padding(
                  padding: const EdgeInsets.only(left: 3.0),
                  child: SvgPicture.asset(
                    'assets/svgs/mute_icon3.svg',
                    width: 16,
                    height: 16,
                    fit: BoxFit.fill,
                  ),
                ),
            ],
          ),
        ),
      chatTypeSmallSecretary => Obx(
          () => Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  localized(chatSecretary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: MFontWeight.bold5.value,
                    fontSize: MFontSize.size17.value,
                    color: colorTextPrimary.withOpacity(1),
                    decoration: TextDecoration.none,
                    letterSpacing: 0,
                    overflow: TextOverflow.ellipsis,
                    height: 1.2,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: SvgPicture.asset(
                  'assets/svgs/secretary_check_icon.svg',
                  width: 15,
                  height: 15,
                  colorFilter: ColorFilter.mode(
                    themeColor,
                    BlendMode.srcIn,
                  ),
                  fit: BoxFit.fitWidth,
                ),
              ),
              if (isMuted.value)
                Padding(
                  padding: const EdgeInsets.only(left: 3.0),
                  child: SvgPicture.asset(
                    'assets/svgs/mute_icon3.svg',
                    width: 16,
                    height: 16,
                    fit: BoxFit.fill,
                  ),
                ),
            ],
          ),
        ),
      chatTypeSystem => Obx(
          () => Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  localized(chatSystem),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: MFontWeight.bold5.value,
                    fontSize: MFontSize.size17.value,
                    color: colorTextPrimary.withOpacity(1),
                    decoration: TextDecoration.none,
                    letterSpacing: 0,
                    overflow: TextOverflow.ellipsis,
                    height: 1.2,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: SvgPicture.asset(
                  'assets/svgs/secretary_check_icon.svg',
                  width: 15,
                  height: 15,
                  colorFilter: ColorFilter.mode(
                    themeColor,
                    BlendMode.srcIn,
                  ),
                  fit: BoxFit.fitWidth,
                ),
              ),
              if (isMuted.value)
                Padding(
                  padding: const EdgeInsets.only(left: 3.0),
                  child: SvgPicture.asset(
                    'assets/svgs/mute_icon3.svg',
                    width: 16,
                    height: 16,
                    fit: BoxFit.fill,
                  ),
                ),
            ],
          ),
        ),
      chatTypeMiniApp => Obx(
          () => Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  widget.chat.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: MFontWeight.bold5.value,
                    fontSize: MFontSize.size17.value,
                    color: colorTextPrimary.withOpacity(1),
                    decoration: TextDecoration.none,
                    letterSpacing: 0,
                    overflow: TextOverflow.ellipsis,
                    height: 1.2,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: SvgPicture.asset(
                  'assets/svgs/secretary_check_icon.svg',
                  width: 15,
                  height: 15,
                  colorFilter: ColorFilter.mode(
                    themeColor,
                    BlendMode.srcIn,
                  ),
                  fit: BoxFit.fitWidth,
                ),
              ),
              if (isMuted.value)
                Padding(
                  padding: const EdgeInsets.only(left: 3.0),
                  child: SvgPicture.asset(
                    'assets/svgs/mute_icon3.svg',
                    width: 16,
                    height: 16,
                    fit: BoxFit.fill,
                  ),
                ),
            ],
          ),
        ),
      _ => const SizedBox(),
    };
  }

  Widget _buildTimeView(BuildContext context) {
    return Obx(
      () {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.chat.showMessageReadIcon &&
                lastMessage.value != null &&
                lastMessage.value!.hasReadView &&
                lastMsgSendState.value == MESSAGE_SEND_SUCCESS &&
                objectMgr.userMgr.isMe(lastMessage.value!.send_id))
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: SvgPicture.asset(
                  messageIsRead.value
                      ? 'assets/svgs/done_all_icon.svg'
                      : 'assets/svgs/unread_tick_icon.svg',
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    colorReadColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            if (lastMessage.value != null && lastMessage.value!.create_time > 0)
              Text(
                FormatTime.chartTime(
                  lastMessage.value!.create_time,
                  true,
                  todayShowTime: true,
                  dateStyle: DateStyle.MMDDYYYY,
                ),
                style: jxTextStyle
                    .headerSmallText(color: colorTextSecondary)
                    .useSystemChineseFont(),
              ),
          ],
        );
      },
    );
  }

  Widget _contentBuilder(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: _buildContentView(context)),
        _buildUnreadView(context),
      ],
    );
  }

  Widget _buildContentView(BuildContext context) {
    return Obx(
      () {
        if (draftString.value.isNotEmpty) {
          return RichText(
            text: TextSpan(
              style: jxTextStyle.chatCellContentStyle(
                color: colorTextSecondarySolid,
              ),
              children: <InlineSpan>[
                TextSpan(
                  text: '${localized(chatDraft)}: ',
                  style: jxTextStyle.chatCellContentStyle(color: colorRed),
                ),
                TextSpan(text: draftString.value),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        if (isTyping.value) {
          return whoIsTypingWidget(
            ChatTypingTask.whoIsTyping[widget.chat.id]!,
            jxTextStyle.chatCellContentStyle(),
            isSingleChat: widget.chat.isSingle,
            mainAlignment: MainAxisAlignment.start,
          );
        }

        if (lastMessage.value != null) {
          return ChatCellContentFactory.createComponent(
            chat: widget.chat,
            lastMessage: lastMessage.value!,
            messageSendState: lastMsgSendState.value,
            isVoicePlayed: isVoicePlayed.value,
          );
        }

        return const SizedBox(height: 20);
      },
    );
  }

  Widget _buildUnreadView(BuildContext context) {
    return Obx(() {
      final bool hasMention =
          notBlank(objectMgr.chatMgr.mentionMessageMap[widget.chat.chat_id]);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (hasMention)
            Container(
              margin: EdgeInsets.only(
                left: objectMgr.loginMgr.isDesktop ? 10 : 8,
              ),
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: isMuted.value ? colorTextSupporting : themeColor,
                shape: const CircleBorder(),
              ),
              child: Text(
                "@",
                style: jxTextStyle.textStyle14(
                  color: colorWhite,
                ),
              ),
            ),
          if (unreadCount.value > 0)
            Container(
              height: 20,
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              constraints: const BoxConstraints(minWidth: 20),
              decoration: BoxDecoration(
                color: isMuted.value ? colorTextSupporting : themeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: unreadCount.value < 999
                    ? AnimatedFlipCounter(
                        value: unreadCount.value,
                        textStyle: jxTextStyle.headerSmallText(
                          color: colorWhite,
                        ),
                      )
                    : Text(
                        '999+',
                        style: jxTextStyle.headerSmallText(
                          color: colorWhite,
                        ),
                      ),
              ),
            ),
          if (!hasMention && widget.chat.sort != 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              constraints: const BoxConstraints(minWidth: 20, maxHeight: 24),
              child: SvgPicture.asset(
                'assets/svgs/chat_cell_pin_icon.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  colorTextSupporting,
                  BlendMode.srcIn,
                ),
                fit: BoxFit.fill,
              ),
            ),
        ],
      );
    });
  }
}
