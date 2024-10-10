import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/group_mgr.dart';
import 'package:jxim_client/managers/message_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/online_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/chat_input.dart';
import 'package:jxim_client/object/chat/draft_model.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/saved_message_icon.dart';
import 'package:jxim_client/utils/secretary_message_icon.dart';
import 'package:jxim_client/utils/system_message_icon.dart';
import 'package:jxim_client/utils/theme/text_styles.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:jxim_client/views/component/component.dart';

class ChatItemController extends GetxController {
  // 变量
  final ChatListEvent chatListEvent = ChatListEvent.instance;
  late Chat chat;
  late Rx<Message?> lastMessage;

  // 聊天室消息发送状态
  RxInt lastMsgSendState = MESSAGE_SEND_SUCCESS.obs;

  // 开启聊天室编辑状态
  RxBool isEditing = false.obs;

  bool enableEdit = true;

  // 聊天室选中状态
  RxBool isSelected = false.obs;

  // 聊天室搜索状态
  RxBool isSearching = false.obs;

  RxBool isMuted = false.obs;

  RxBool isTyping = false.obs;

  // 新聊天室
  RxBool isNewChat = false.obs;

  // 未读消息数
  RxInt unreadCount = 0.obs;

  // 在线状态
  RxBool isOnline = false.obs;

  // 自动清除消息
  RxInt autoDeleteInterval = 0.obs;

  // 临时群组
  RxBool isGroupExpireSoon = false.obs;

  // 聊天消息草稿
  RxString draftString = ''.obs;

  // 语音消息是否已读
  RxBool isVoicePlayed = false.obs;

  RxBool messageIsRead = false.obs;

  // 构造器
  ChatItemController({
    required this.chat,
    required this.isEditing,
  });

  // 函数
  @override
  void onInit() {
    super.onInit();
    lastMessage = objectMgr.chatMgr.lastChatMessageMap[chat.chat_id].obs;
    if (lastMessage.value != null) {
      lastMsgSendState.value = lastMessage.value!.sendState;
      if (lastMsgSendState.value == MESSAGE_SEND_FAIL &&
          (lastMessage.value!.typ == messageTypeImage ||
              lastMessage.value!.typ == messageTypeVideo ||
              lastMessage.value!.typ == messageTypeNewAlbum)) {
        objectMgr.chatMgr.showNotification(lastMessage.value!);
      }

      // 初始化语音消息是否已读
      isVoicePlayed.value = objectMgr.userMgr
              .isMe(lastMessage.value!.send_id) ||
          objectMgr.localStorageMgr.read('${lastMessage.value!.message_id}') !=
              null;
      // 初始化消息是否已读
      messageIsRead.value =
          chat.other_read_idx >= lastMessage.value!.chat_idx &&
              lastMessage.value!.isSendOk;
    }

    isMuted.value = chat.isMute;

    // 初始化草稿内容, 如果有
    draftString.value = objectMgr.chatMgr.getChatDraft(chat.id)?.input ?? '';

    initOnlineStatus();

    if (!chat.isDisband) {
      checkIsNewChat();
      unreadCount.value = chat.unread_count;
    }

    autoDeleteInterval.value = chat.autoDeleteInterval;

    // 聊天列表状态更新监听
    chatListEvent.on(
      ChatListEvent.eventMultiSelectStateChange,
      _onEditStateChange,
    );
    chatListEvent.on(
      ChatListEvent.eventChatEnableEditStateChange,
      _onEnableEditStateChange,
    );

    // 新消息监听
    objectMgr.chatMgr.on(ChatMgr.eventAllLastMessageLoaded, _onNewMessage);
    objectMgr.chatMgr.on(ChatMgr.eventChatLastMessageChanged, _onNewMessage);
    objectMgr.chatMgr.on(ChatMgr.eventEditMessage, _onNewMessage);
    objectMgr.chatMgr.on(ChatMgr.eventReadMessage, _onNewMessage);
    objectMgr.chatMgr.on(ChatMgr.eventChatMuteChanged, _onMuteChanged);

    objectMgr.chatMgr.on(ChatMgr.eventRejoined, _onChatRejoined);
    objectMgr.chatMgr.on(ChatMgr.eventAutoDeleteMsg, _onUnreadUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventUpdateUnread, _onUnreadUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventChatDisband, _onUnreadUpdate);

    objectMgr.chatMgr.on(ChatMgr.eventChatIsTyping, _onChatInput);
    objectMgr.chatMgr
        .on(ChatMgr.eventAutoDeleteInterval, _onAutoDeleteIntervalChange);

    objectMgr.myGroupMgr
        .on(MyGroupMgr.eventTmpGroupLessThanADay, _onGroupIsExpired);

    objectMgr.onlineMgr.on(OnlineMgr.eventLastSeenStatus, _onLastSeenChanged);
    objectMgr.chatMgr
        .on('${chat.id}_${ChatMgr.eventDraftUpdate}', _onDraftUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventVoicePlayUpdate, _onMessageVoicePlayed);
    objectMgr.chatMgr.on(ChatMgr.eventDecryptChat, _onDecryptChat);
    objectMgr.chatMgr.on(ChatMgr.eventChatEncryptionUpdate, _onChangeEncryptionUpdate);


    if (lastMessage.value != null) {
      updateUser(lastMessage.value!.send_id);
    }
  }

  @override
  void onClose() {
    chatListEvent.off(
      ChatListEvent.eventMultiSelectStateChange,
      _onEditStateChange,
    );
    chatListEvent.off(
      ChatListEvent.eventChatEnableEditStateChange,
      _onEnableEditStateChange,
    );

    objectMgr.chatMgr.off(ChatMgr.eventAllLastMessageLoaded, _onNewMessage);
    objectMgr.chatMgr.off(ChatMgr.eventChatLastMessageChanged, _onNewMessage);
    objectMgr.chatMgr.off(ChatMgr.eventEditMessage, _onNewMessage);
    objectMgr.chatMgr.off(ChatMgr.eventReadMessage, _onNewMessage);
    objectMgr.chatMgr.off(ChatMgr.eventChatMuteChanged, _onMuteChanged);

    objectMgr.chatMgr.off(ChatMgr.eventRejoined, _onChatRejoined);
    objectMgr.chatMgr.off(ChatMgr.eventAutoDeleteMsg, _onUnreadUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventUpdateUnread, _onUnreadUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventChatDisband, _onUnreadUpdate);

    objectMgr.chatMgr.off(ChatMgr.eventChatIsTyping, _onChatInput);
    objectMgr.chatMgr
        .off(ChatMgr.eventAutoDeleteInterval, _onAutoDeleteIntervalChange);

    objectMgr.myGroupMgr
        .off(MyGroupMgr.eventTmpGroupLessThanADay, _onGroupIsExpired);

    objectMgr.onlineMgr.off(OnlineMgr.eventLastSeenStatus, _onLastSeenChanged);
    objectMgr.chatMgr
        .off('${chat.id}_${ChatMgr.eventDraftUpdate}', _onDraftUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventVoicePlayUpdate, _onMessageVoicePlayed);
    objectMgr.chatMgr.off(ChatMgr.eventDecryptChat, _onDecryptChat);
    objectMgr.chatMgr.off(ChatMgr.eventChatEncryptionUpdate, _onChangeEncryptionUpdate);

    super.onClose();
  }

  void initOnlineStatus() async {
    if (!chat.isSingle) return;

    User? user = objectMgr.userMgr.getUserById(chat.friend_id);

    if (user != null) {
      isOnline.value = objectMgr.onlineMgr.friendOnlineString[chat.friend_id] ==
          localized(chatOnline);
    }

    user = await objectMgr.userMgr.loadUserById(chat.friend_id);
    isOnline.value = objectMgr.onlineMgr.friendOnlineString[chat.friend_id] ==
        localized(chatOnline);
  }

  void updateUser(uid) {
    if (objectMgr.userMgr.getUserById(uid) == null) {
      objectMgr.userMgr.loadUserById(uid).then((value) {
        update();
      });
    }
  }

  void _onMuteChanged(_, __, Object? data) {
    if (data is! Chat || data.id != chat.id) return;

    isMuted.value = chat.isMute;
  }

  void _onNewMessage(Object sender, Object type, Object? data) {
    // 不同聊天室不需要刷新
    if (data is Message && data.chat_id != chat.id) return;

    if (data is Map<String, dynamic> && data['id'] != chat.id) return;
    if (chat.isDisband) return;

    final latestMsg = objectMgr.chatMgr.getLatestMessage(chat.id);

    if (latestMsg != null) {
      lastMessage.value?.off(Message.eventSendState, _onMsgSendStateChange);
      lastMessage.value = latestMsg;

      if (lastMessage.value!.typ == messageTypeVoice) {
        isVoicePlayed.value =
            objectMgr.userMgr.isMe(lastMessage.value?.send_id ?? -1) ||
                objectMgr.localStorageMgr
                        .read('${lastMessage.value?.message_id}') !=
                    null;
      }

      updateUser(lastMessage.value!.send_id);
      if (lastMessage.value!.sendState != MESSAGE_SEND_SUCCESS) {
        lastMsgSendState.value = lastMessage.value!.sendState;
        lastMessage.value!.on(Message.eventSendState, _onMsgSendStateChange);
      } else if (lastMessage.value!.edit_time != 0) {
        update();
      }

      messageIsRead.value =
          chat.other_read_idx >= lastMessage.value!.chat_idx &&
              lastMessage.value!.isSendOk;
    } else {
      if (lastMessage.value != null) {
        lastMessage.value?.off(Message.eventSendState, _onMsgSendStateChange);
      }
      lastMessage.value = null;
    }
    _onUnreadUpdate(sender, type, data ?? chat.toJson());
  }

  void _onDecryptChat(Object sender, Object type, Object? data) {
    if (data is! List<Chat> ||
        lastMessage.value == null ||
        lastMessage.value != null &&
            (lastMessage.value!.ref_typ == 0 ||
                lastMessage.value!.ref_typ == 4)) return;
    for (var item in data) {
      if (item.chat_id == chat.chat_id) {
        if (item.chat_key != "") {
          try {
            MessageMgr.decodeMsg(lastMessage.value!, chat, objectMgr.userMgr.mainUser.uid);
            update();
          } catch (e) {
            lastMessage.value!.ref_typ = 4;
            pdebug("_onDecryptChat aes decrypt err: $e");
          }
          return;
        }
      }
    }
  }

  void _onChatInput(_, __, Object? data) {
    if (data is! ChatInput || data.chatId != chat.id) return;
    if (chat.isDisband) return;

    isTyping.value = data.state != ChatInputState.noTyping;
  }

  void _onChangeEncryptionUpdate(sender, type, data) {
    if (data is Chat && chat.id == data.id) {
      update();
    }
  }

  void _onChatRejoined(_, __, Object? data) {
    if (data is! Chat || data.id != chat.id) return;

    checkIsNewChat(startIdx: data.start_idx);
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

    if (chatId != chat.id || chat.isSaveMsg) return;
    // 准确数据的chat
    Chat? accurateChat = objectMgr.chatMgr.getChatById(chat.id);
    if (accurateChat == null) return;

    if (isNewChat.value) checkIsNewChat(startIdx: accurateChat.start_idx);

    if (lastMessage.value != null) {
      messageIsRead.value =
          chat.other_read_idx >= lastMessage.value!.chat_idx &&
              lastMessage.value!.isSendOk;
    }
    unreadCount.value = accurateChat.unread_count;
  }

  void _onEditStateChange(_, __, Object? isEditMode) {
    if (isEditMode is! bool) return;

    if (isEditMode == false) {
      isSelected.value = false;
    }
  }

  void _onEnableEditStateChange(_, __, Object? data) {
    if (data is! bool) return;

    enableEdit = data;
    if (!enableEdit) {
      isEditing.value = false;
      isSelected.value = false;
    }
  }

  void _onMsgSendStateChange(_, __, Object? data) {
    if (data is Message &&
        data.id == lastMessage.value?.id &&
        data.sendState != lastMsgSendState.value) {
      lastMsgSendState.value = data.sendState;
    }
  }

  void _onAutoDeleteIntervalChange(_, __, Object? data) {
    if (data is Message) {
      if (data.chat_id != chat.id) return;
      MessageInterval msgInterval =
          data.decodeContent(cl: MessageInterval.creator);
      autoDeleteInterval.value = msgInterval.interval;
    }
  }

  void _onGroupIsExpired(_, __, Object? data) {
    if (data != null && data is Map<String, dynamic>) {
      if (data['id'] == chat.id) {
        isGroupExpireSoon.value = data['isExpiring'];
      }
    }
  }

  void _onLastSeenChanged(Object sender, Object type, Object? data) {
    if (!chat.isSingle) return;

    isOnline.value = objectMgr.onlineMgr.friendOnlineString[chat.friend_id] ==
        localized(chatOnline);
  }

  void _onDraftUpdate(_, __, ___) {
    /// 获取输入草稿
    DraftModel? draftModel = objectMgr.chatMgr.getChatDraft(chat.chat_id);

    if (draftModel != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        draftString.value = draftModel.input;
      });
    }
  }

  void _onMessageVoicePlayed(_, __, Object? data) {
    if (data is! Map ||
        data['message_id'] == null ||
        data['message_id'] != lastMessage.value?.message_id) {
      return;
    }

    isVoicePlayed.value = objectMgr.userMgr
            .isMe(lastMessage.value?.send_id ?? -1) ||
        objectMgr.localStorageMgr.read('${lastMessage.value?.message_id}') !=
            null;
  }

  // 聊天室点击事件
  void onItemClick() {
    if (!enableEdit) return;

    if (isEditing.value) {
      if (chat.isSpecialChat) {
        Toast.showToast(
          localized(hideOrDeleteSavedMessageIsNotAllowed,
              params: [getSpecialChatName(chat.typ)]),
          isStickBottom: false,
        );
      } else {
        isSelected.value = !isSelected.value;
        chatListEvent.event(
          ChatListEvent.instance,
          ChatListEvent.eventChatEditSelect,
          data: chat,
        );
      }
      return;
    }

    chatListEvent.event(
      ChatListEvent.instance,
      ChatListEvent.eventSearchStateChange,
      data: true,
    );
    Routes.toChat(chat: chat);
  }

  // 聊天室长按事件
  void onItemLongPress() {
    if (!enableEdit) return;

    isEditing.value = true;
    if (chat.isSpecialChat) {
      Toast.showToast(
        localized(hideOrDeleteSavedMessageIsNotAllowed,
            params: [getSpecialChatName(chat.typ)]),
        isStickBottom: false,
      );
    } else {
      isSelected.value = !isSelected.value;
      chatListEvent.event(
        ChatListEvent.instance,
        ChatListEvent.eventChatEditSelect,
        data: chat,
      );
    }
  }

  // 隐藏聊天室
  Future<void> hideChat(BuildContext context, Chat? chat) async {
    showCustomBottomAlertDialog(
      context,
      imgWidget: CustomAvatar.chat(chat!, size: 60),
      content: Text(
        (chat.isGroup ? localized(chatHideGroup) : localized(chatHideSingle)),
        style: jxTextStyle.textStyle15(
          color: Colors.black,
        ),
      ),
      confirmText: (chat.isGroup
          ? localized(chatHideGroupConfirm)
          : localized(chatHideChat)),
      onConfirmListener: () {
        imBottomToast(
          context,
          title: localized(hide1Chat, params: ['1']),
          icon: ImBottomNotifType.timer,
          duration: 5,
          withCancel: true,
          timerFunction: () {
            objectMgr.chatMgr.setChatHide(chat);
            Get.back();
          },
          undoFunction: () => BotToast.removeAll(BotToast.textKey),
          isStickBottom: false,
        );
      },
    );
  }

  // 删除聊天室
  Future<void> onDeleteChat(BuildContext context, Chat? chat) async {
    BotToast.removeAll(BotToast.textKey);
    showCustomBottomAlertDialog(
      context,
      imgWidget: CustomAvatar.chat(chat!, size: 60),
      content: Text(
        (chat.isGroup
            ? localized(chatDeleteGroup)
            : localized(chatDeleteSingle)),
        style: jxTextStyle.textStyle15(
          color: Colors.black,
        ),
      ),
      confirmText: (chat.isGroup
          ? localized(deleteGroupChat)
          : localized(deleteChatHistory)),
      onConfirmListener: () {
        imBottomToast(
          context,
          title: localized(deleteParamChat, params: ['1']),
          icon: ImBottomNotifType.timer,
          duration: 5,
          withCancel: true,
          timerFunction: () {
            objectMgr.chatMgr.onChatDelete(chat);
            bool isInChat = objectMgr.chatMgr.isInCurrentChat(chat.chat_id);
            if (isInChat) {
              Get.back();
            }
          },
          undoFunction: () => BotToast.removeAll(BotToast.textKey),
          isStickBottom: false,
        );
      },
    );
  }

  void onClearChat(BuildContext context, Chat data) async {
    Widget imageWidget = const SecretaryMessageIcon(size: 60);
    if (chat.isSaveMsg) {
      imageWidget = const SavedMessageIcon(size: 60);
    } else if (chat.isSystem) {
      imageWidget = const SystemMessageIcon(size: 60);
    }

    /// 解决:返回聊天室列表,chatMessageMap可能会空,导致无法彻底clear chat history
    bool isChatMessageEmpty = false;
    var chatMessages = objectMgr.chatMgr.chatMessageMap[chat.chat_id];
    if (chatMessages == null || chatMessages.isEmpty) {
      isChatMessageEmpty = true;
    }

    showCustomBottomAlertDialog(
      context,
      imgWidget: imageWidget,
      content: Text.rich(
        textAlign: TextAlign.center,
        TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: localized(secondaryMenuClearMessageTipStart),
            ),
            TextSpan(
              text: getSpecialChatName(data.typ),
              style: jxTextStyle.textStyleBold13(
                color: Colors.black,
                fontWeight: MFontWeight.bold6.value,
              ),
            ),
            TextSpan(
              text: localized(secondaryMenuClearMessageTipEnd),
            ),
          ],
        ),
        style: jxTextStyle.textStyleBold13(
          color: Colors.black,
          fontWeight: MFontWeight.bold4.value,
        ),
      ),
      confirmText: localized(secondaryMenuClearRecordOnlyForMe),
      onConfirmListener: () async {
        imBottomToast(
          isStickBottom: false,
          Get.context!,
          title: localized(deleteMyChatRecord),
          icon: ImBottomNotifType.timer,
          duration: 5,
          withCancel: true,
          timerFunction: () async {
            await objectMgr.chatMgr.clearMessage(data, isStickBottom: false);
            if (isChatMessageEmpty) {
              await objectMgr.localDB.clearMessages(data.chat_id);
            }
          },
          undoFunction: () {
            BotToast.removeAll(BotToast.textKey);
          },
        );
      },
    );
  }

  // 工具函数

  void checkIsNewChat({int? startIdx}) {
    if (chat.isSaveMsg || chat.isSecretary) {
      isNewChat.value = false;
    } else {
      isNewChat.value = isWithin24Hours(chat.create_time * 1000) &&
          chat.read_chat_msg_idx <= (startIdx ?? chat.start_idx);
    }
  }

  bool isWithin24Hours(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final twentyFourHoursAgo =
        now - (24 * 60 * 60 * 1000); // 24 hours in milliseconds

    return timestamp >= twentyFourHoursAgo;
  }
}
