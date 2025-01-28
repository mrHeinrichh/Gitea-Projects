import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/utils/keyboard_util.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:video_player/video_player.dart';
import 'package:jxim_client/object/chat/message.dart';

import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';

class SingleChatController extends BaseChatController {
  /// 单聊 - 对方的用户信息
  final user = Rxn<User>();
  final lastOnline = "".obs;

  VideoPlayerController? videoController;
  final isVideoRecording = false.obs;
  final CustomPopupMenuController popUpMenuController =
      Get.find<CustomPopupMenuController>();
  final isDesktop = objectMgr.loginMgr.isDesktop;
  final isMobile = objectMgr.loginMgr.isMobile;

  //是否靜音
  RxBool isMute = RxBool(false);

  SingleChatController();

  SingleChatController.desktop(Chat chat, List<Message>? messages) {
    this.chat = chat;
    if (messages != null && messages.length > 0) {
      super.searchMsg = messages[0];
    }
  }

  /// METHODS
  @override
  void onInit() async {
    if (isMobile) {
      final arguments = Get.arguments as Map<String, dynamic>;
      if (arguments['chat'] == null) {
        Get.back();
      }
      chat = arguments['chat'] as Chat;
      fromNotificationTap = arguments['fromNotification'] ?? false;
      isScreenshotEnabled = chat.screenshotEnabled;
    }

    isMute.value = chat.isMute;

    if (chat.isSingle) {
      loadUser();
    }

    ///监听本地用户数据库更新
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventChatMuteChanged, _onMuteChanged);
    objectMgr.chatMgr.on(ChatMgr.eventLastSeenStatus, _onLastSeenChanged);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBChat.tableName}", _onChatUpdate);
    super.onInit();
  }

  loadUser() async {
    user.value = await objectMgr.userMgr.loadUserById(chat.friend_id);

    /// 是朋友才请求远端
    if (user.value?.relationship == Relationship.friend ||
        user.value?.relationship == Relationship.sentRequest ||
        user.value?.relationship == Relationship.receivedRequest) {
      User? newUser = await objectMgr.userMgr.getRemoteUser(chat.friend_id);
      if (newUser != null && newUser != user.value) {
        user.value = newUser;
      }
    }

    /// 检查用户是否在线
    if (user.value != null) {
      lastOnline.value = getLastOnlineStatus(user.value);
      objectMgr.userMgr.friendOnline[user.value!.uid] =
          FormatTime.isOnline(user.value!.lastOnline);
    }

    if (user.value?.relationship != Relationship.friend) {
      chatIsDeleted.value = true;
    }
  }

  @override
  void onReady() {
    WidgetsBinding.instance.addObserver(KeyBoardObserver.instance);
    super.onReady();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(KeyBoardObserver.instance);
    objectMgr.stickerMgr.updateRemoteRecentStickers();
    super.onClose();
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventChatMuteChanged, _onMuteChanged);
    objectMgr.chatMgr.off(ChatMgr.eventLastSeenStatus, _onLastSeenChanged);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBChat.tableName}", _onChatUpdate);
  }

  _onChatUpdate(Object sender, Object type, Object? data) {
    if (data is Chat && chat.chat_id == data.chat_id) {
      isScreenshotEnabled = data.screenshotEnabled;
    }
  }

  void showVideoScreen(bool isShow) {
    isVideoRecording(isShow);
  }

  void _onMuteChanged(Object sender, Object type, Object? data) {
    if (data is Chat && chat.id == data.id) {
      if (checkIsMute(data.mute)) {
        isMute.value = true;
      } else {
        isMute.value = false;
      }
    }
  }

  void _onLastSeenChanged(Object sender, Object type, Object? data) {
    if (data is List<User>) {
      for (final item in data.toList()) {
        if (item.uid == user.value?.uid) {
          lastOnline.value = getLastOnlineStatus(item);
        }
      }
    }
  }

  ///更新数据库通知
  Future<void> _onUserUpdate(Object sender, Object type, Object? data) async {
    if (data is User && data.id == user.value?.uid) {
      user.value?.relationship = data.relationship;
      if (user.value?.relationship != Relationship.friend) {
        chatIsDeleted.value = true;
      } else {
        chatIsDeleted.value = false;
      }
      user.refresh();
    }
  }

  clearHistory() async {
    var res = await objectMgr.chatMgr.clearMessage(chat);
    if (res.success()) {
      Toast.showToast(localized(chatInfoClearHistorySuccessful),
          isStickBottom: false);
    } else {
      Toast.showToast(localized(chatInfoPleaseTryAgainLater));
    }
  }

  String getLastOnlineStatus(User? user) {
    if (user != null) {
      bool isOnline = objectMgr.userMgr.friendOnline.value[user.uid] ?? false;
      if (isOnline) {
        return localized(chatOnline);
      } else if (user.lastOnline > 0) {
        return FormatTime.formatTimeFun(user.lastOnline);
      }
    }
    return "";
  }

  void onTapSearchDesktop() async {
    Chat? chat = await objectMgr.chatMgr
        .getChatByFriendId(user.value!.uid, remote: true);

    if (chat == null) return;
    if (Get.isRegistered<SingleChatController>(tag: chat.id.toString())) {
      Get.find<CustomInputController>(tag: chat.id.toString())
          .inputFocusNode
          .unfocus();
      isSearching(true);
    } else {
      if (Get.find<HomeController>().pageIndex.value == 0) {
        Routes.toChatDesktop(chat: chat);
      } else {
        final id = Get.find<HomeController>().pageIndex.value == 0 ? 1 : 2;
        Get.back(id: objectMgr.loginMgr.isDesktop ? id : null);
        Get.find<HomeController>().tabController?.index = 0;
        Get.find<HomeController>().pageIndex.value = 0;
        Future.delayed(const Duration(milliseconds: 300), () {
          Routes.toChatDesktop(chat: chat);
        });
      }
    }
  }

  @override
  onChatReload(sender, type, data) {
    objectMgr.userMgr.getRemoteUser(chat.friend_id, notify: true);
    super.onChatReload(sender, type, data);
  }
}
