import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/chat_input.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/im_toast/im_bottom_toast.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/custom_confirmation_popup.dart';

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
    if(lastMessage.value != null){
      lastMsgSendState.value = lastMessage.value!.sendState;
    }

    isMuted.value = chat.isMute;

    if (!chat.isDisband) {
      checkIsNewChat();
      unreadCount.value = chat.unread_count;
    }

    autoDeleteInterval.value = chat.autoDeleteInterval;

    // 聊天列表状态更新监听
    chatListEvent.on(
        ChatListEvent.eventMultiSelectStateChange, _onEditStateChange);
    chatListEvent.on(
        ChatListEvent.eventChatEnableEditStateChange, _onEnableEditStateChange);

    // 新消息监听
    objectMgr.chatMgr.on(ChatMgr.eventMessageComing, _onNewMessage);
    objectMgr.chatMgr.on(ChatMgr.eventMessageSend, _onNewMessage);
    objectMgr.chatMgr.on(ChatMgr.eventEmojiChange, _onNewMessage);
    objectMgr.chatMgr.on(ChatMgr.eventAllLastMessageLoaded, _onNewMessage);
    objectMgr.chatMgr.on(ChatMgr.eventChatLastMessageChanged, _onNewMessage);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, _onNewMessage);
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

    ever<Map<int, bool>>(objectMgr.userMgr.friendOnline,
        (Map<int, bool> online) {
      if (Get.currentRoute != '/home') return;

      isOnline.value = online[chat.friend_id] ?? false;
    });
    if (lastMessage.value != null) {
      updateUser(lastMessage.value!.send_id, lastMessage.value!);
    }
  }

  @override
  void onClose() {
    chatListEvent.off(
        ChatListEvent.eventMultiSelectStateChange, _onEditStateChange);
    chatListEvent.off(
        ChatListEvent.eventChatEnableEditStateChange, _onEnableEditStateChange);

    objectMgr.chatMgr.off(ChatMgr.eventMessageComing, _onNewMessage);
    objectMgr.chatMgr.off(ChatMgr.eventMessageSend, _onNewMessage);
    objectMgr.chatMgr.off(ChatMgr.eventEmojiChange, _onNewMessage);
    objectMgr.chatMgr.off(ChatMgr.eventAllLastMessageLoaded, _onNewMessage);
    objectMgr.chatMgr.off(ChatMgr.eventChatLastMessageChanged, _onNewMessage);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, _onNewMessage);
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
    super.onClose();
  }

  void updateUser(uid, message) {
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

  void _onNewMessage(_, __, Object? data) {
    if (data is Message && data.chat_id != chat.id) return;
    if (data is Map<String, dynamic> && data['id'] != chat.id) return;
    if (chat.isDisband) return;

    lastMessage.value = objectMgr.chatMgr.getLatestMessage(chat.id);
    if (lastMessage.value != null) {
      updateUser(lastMessage.value!.send_id, lastMessage.value!);
      if (lastMessage.value!.sendState != MESSAGE_SEND_SUCCESS) {
        lastMsgSendState.value = lastMessage.value!.sendState;
        lastMessage.value!.on(Message.eventSendState, _onMsgSendStateChange);
      }else if(lastMessage.value!.edit_time != 0){
        update();
      }
    }
    _onUnreadUpdate(_, __, data ?? chat.toJson());
  }

  void _onChatInput(_, __, Object? data) {
    if (data is! ChatInput || data.chat_id != chat.id) return;
    if (chat.isDisband) return;

    isTyping.value = data.state == 1;
  }

  void _onChatRejoined(_, __, Object? data) {
    if (data is! Chat || data.id != chat.id) return;

    checkIsNewChat(startIdx: data.start_idx);
  }

  void _onUnreadUpdate(_, __, data) {
    if (data == null) return;

    int chatId = -1;
    if (data is Message) {
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
    if (data is Message && data.sendState != lastMsgSendState.value) {
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

  // 聊天室点击事件
  void onItemClick() {
    if (!enableEdit) return;

    if (isEditing.value) {
      if (chat.typ == chatTypeSaved) {
        Toast.showToast(
          localized(hideOrDeleteSavedMessageIsNotAllowed),
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
    if (chat.typ == chatTypeSaved) {
      Toast.showToast(
        localized(hideOrDeleteSavedMessageIsNotAllowed),
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
  void hideChat(BuildContext context, Chat? chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          title: localized(chatHideChat),
          subTitle: localized(chatRoomWillNoLongerAppear),
          confirmButtonColor: JXColors.red,
          cancelButtonColor: accentColor,
          confirmButtonText: localized(buttonConfirm),
          cancelButtonText: localized(buttonCancel),
          confirmCallback: () {
            ImBottomToast(
              context,
              title: localized(
                hide1Chat,
                params: ['1'],
              ),
              icon: ImBottomNotifType.timer,
              duration: 5,
              withCancel: true,
              timerFunction: () {
                objectMgr.chatMgr.setChatHide(chat!);
                Get.back();
              },
              undoFunction: () {
                BotToast.removeAll(BotToast.textKey);
              },
            );
          },
          cancelCallback: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  // 删除聊天室
  void onDeleteChat(BuildContext context, Chat? chat) async {
    BotToast.removeAll(BotToast.textKey);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomConfirmationPopup(
          title: localized(deleteChatHistory),
          subTitle: localized(
            chatInfoDoYouWantToDelete,
            params: [
              '${(chat?.typ == chatTypeSmallSecretary) ? localized(chatSecretary) : chat?.name}'
            ],
          ),
          confirmButtonColor: JXColors.red,
          cancelButtonColor: accentColor,
          confirmButtonText: localized(buttonConfirm),
          cancelButtonText: localized(buttonCancel),
          confirmCallback: () {
            ImBottomToast(
              context,
              title: localized(deleteParamChat, params: ['1']),
              icon: ImBottomNotifType.timer,
              duration: 5,
              withCancel: true,
              timerFunction: () {
                objectMgr.chatMgr.onChatDelete(chat!);
                Get.back();
              },
              undoFunction: () {
                BotToast.removeAll(BotToast.textKey);
              },
            );
          },
          cancelCallback: Navigator.of(context).pop,
        );
      },
    );
  }

  void onClearChat(Chat data) async {
    await objectMgr.chatMgr.clearMessage(data, isStickBottom: false);
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
