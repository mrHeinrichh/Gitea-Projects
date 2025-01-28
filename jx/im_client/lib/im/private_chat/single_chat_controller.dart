import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/data/db_user.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/online_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/format_time.dart';
import 'package:jxim_client/utils/keyboard_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:video_player/video_player.dart';

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
  final RxBool isEncrypted = false.obs;
  final downOffset = 0.0.obs;

  SingleChatController();

  SingleChatController.desktop(Chat chat, List<Message>? messages) {
    this.chat = chat;
    if (messages != null && messages.isNotEmpty) {
      super.searchMsg = messages[0];
    }
  }

  /// METHODS
  @override
  void onInit() async {
    downOffset.value = objectMgr.callMgr.topFloatingOffsetY;
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
    isEncrypted.value = chat.isEncrypted;

    if (chat.isSingle) {
      loadUser();
    }

    ///监听本地用户数据库更新
    objectMgr.sharedRemoteDB
        .on("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventChatMuteChanged, _onMuteChanged);
    objectMgr.onlineMgr.on(OnlineMgr.eventLastSeenStatus, _onLastSeenChanged);
    objectMgr.sharedRemoteDB
        .on("$blockOptUpdate:${DBChat.tableName}", _onChatUpdate);
    objectMgr.chatMgr
        .on(ChatMgr.eventChatEncryptionUpdate, _onChangeEncryptionUpdate);
    objectMgr.callMgr.on(CallMgr.eventTopFloating, _onTopFloatingUpdate);

    super.onInit();
  }

  loadUser() async {
    user.value = objectMgr.userMgr.getUserById(chat.friend_id);

    /// 检查用户是否在线
    getLastOnlineStatus();

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
    getLastOnlineStatus();

    if (user.value != null) {
      if (user.value!.deletedAt > 0) {
        chatIsDeleted.value = true;
      } else {
        chatIsDeleted.value = false;
      }
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
    objectMgr.sharedRemoteDB
        .off("$blockOptReplace:${DBUser.tableName}", _onUserUpdate);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBUser.tableName}", _onUserUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventChatMuteChanged, _onMuteChanged);
    objectMgr.onlineMgr.off(OnlineMgr.eventLastSeenStatus, _onLastSeenChanged);
    objectMgr.sharedRemoteDB
        .off("$blockOptUpdate:${DBChat.tableName}", _onChatUpdate);
    objectMgr.chatMgr.off(CallMgr.eventTopFloating, _onTopFloatingUpdate);
    objectMgr.chatMgr
        .off(ChatMgr.eventChatEncryptionUpdate, _onChangeEncryptionUpdate);

    super.onClose();
  }

  void _onTopFloatingUpdate(Object sender, Object type, Object? data) {
    if (data is double) {
      downOffset.value = data;
      update();
    }
  }

  void _onChangeEncryptionUpdate(sender, type, data) {
    if (data is Chat && chat.chat_id == data.chat_id) {
      isEncrypted.value = chat.isEncrypted;
    }
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
    getLastOnlineStatus();
  }

  ///更新数据库通知
  Future<void> _onUserUpdate(Object sender, Object type, Object? data) async {
    if (data is User && data.id == user.value?.uid) {
      user.value?.relationship = data.relationship;
      if (user.value!.deletedAt > 0) {
        chatIsDeleted.value = true;
      } else {
        chatIsDeleted.value = false;
      }
      user.refresh();
    }
  }

  clearHistory() async {
    await objectMgr.chatMgr.clearMessage(chat);
    Toast.showToast(
      localized(chatInfoClearHistorySuccessful),
    );
  }

  void getLastOnlineStatus() {
    if (objectMgr.onlineMgr.friendOnlineTime[user.value?.uid] == null) return;
    lastOnline.value =
        objectMgr.onlineMgr.friendOnlineString[chat.friend_id] ?? '';

    if (lastOnline.value.isEmpty && user.value != null) {
      lastOnline.value = FormatTime.formatTimeFun(user.value!.lastOnline);
    }
  }

  void onTapSearchDesktop() async {
    Chat? chat = await objectMgr.chatMgr
        .getChatByFriendId(user.value!.uid, remote: true);

    if (chat == null) return;
    if (Get.isRegistered<SingleChatController>(tag: chat.id.toString())) {
      showSearchBar(true);
      searchFocusNode.requestFocus();
      isSearching(true);
    } else {
      if (Get.find<HomeController>().pageIndex.value == 0) {
        Routes.toChat(chat: chat);
      } else {
        final id = Get.find<HomeController>().pageIndex.value == 0 ? 1 : 2;
        Get.back(id: objectMgr.loginMgr.isDesktop ? id : null);
        Get.find<HomeController>().tabController?.index = 0;
        Get.find<HomeController>().pageIndex.value = 0;
        Future.delayed(const Duration(milliseconds: 300), () {
          Routes.toChat(chat: chat);
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
