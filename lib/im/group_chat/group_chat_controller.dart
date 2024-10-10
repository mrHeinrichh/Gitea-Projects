import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/data/db_chat.dart';
import 'package:jxim_client/home/chat/controllers/chat_list_controller.dart';
import 'package:jxim_client/home/home_controller.dart';
import 'package:jxim_client/im/agora_helper.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/chat_info/group/group_chat_info_controller.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/group_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/color.dart';
import 'package:jxim_client/utils/keyboard_util.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/net/update_block_bean.dart';
import 'package:jxim_client/utils/user_utils.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:video_player/video_player.dart';

class GroupChatController extends BaseChatController {
  /// VARIABLES
  final group = Rxn<Group>();
  final groupMembers = <Map<String, dynamic>>[].obs;

  bool isOwner = false;
  bool isAdmin = false;

  //是否靜音
  RxBool isMute = RxBool(false);
  final downOffset = 0.0.obs;

  //是否進入語音聊天室
  RxBool isJoinAudioRoom = RxBool(false);
  List<Color> memberNameColor = constMemberColor.toList();
  VideoPlayerController? videoController;
  final isVideoRecording = false.obs;
  final isDesktop = objectMgr.loginMgr.isDesktop;

  final selectedUser = Rxn<User>();

  GroupChatController();

  GroupChatController.desktop(Chat chat, List<Message>? messages) {
    this.chat = chat;
    if (messages != null && messages.isNotEmpty) {
      super.searchMsg = messages[0];
    }
  }

  /// METHODS
  @override
  void onInit() {
    downOffset.value = objectMgr.callMgr.topFloatingOffsetY;

    if (objectMgr.loginMgr.isMobile) {
      final arguments = Get.arguments as Map<String, dynamic>;
      if (arguments['chat'] == null) {
        BotToast.showText(text: '聊天室不存在');
        Get.back();
      }
      chat = arguments['chat'] as Chat;
      fromNotificationTap = arguments['fromNotification'] ?? false;
    } else if (objectMgr.loginMgr.isDesktop) {
      if (Get.isRegistered<ChatListController>()) {
      } else {
        BotToast.showText(text: '聊天室不存在');
        Get.back();
      }
    }

    if (!chat.isDisband && !chat.isKick) {
      //如果群組解散或是自己退群都不須打語音的api
      sharedDataManager.setGid(chat.id);
    }
    isMute.value = chat.isMute;
    objectMgr.encryptionMgr.checkForFirstTimeToast(chat);

    getGroupInfo();
    chatIsDeleted.value = !chat.isValid;

    objectMgr.sharedRemoteDB
        .on("$blockOptDelete:${DBChat.tableName}", _onChatKicked);
    objectMgr.chatMgr.on(ChatMgr.eventChatEncryptionUpdate, _onChangeEncryptionUpdate);
    objectMgr.chatMgr.on(ChatMgr.eventChatKicked, _onChatKicked);
    objectMgr.chatMgr.on(ChatMgr.eventChatJoined, _onChatJoined);
    objectMgr.chatMgr.on(ChatMgr.eventChatDisband, _onChatKicked);


    objectMgr.myGroupMgr
        .on(MyGroupMgr.eventGroupInfoUpdated, _onGroupInfoUpdated);

    objectMgr.chatMgr.on(ChatMgr.eventChatMuteChanged, _onMuteChanged);
    objectMgr.callMgr.on(CallMgr.eventTopFloating, _onTopFloatingUpdate);

    agoraHelper.isInGroupChatView = true;

    super.onInit();
  }

  @override
  void onReady() {
    WidgetsBinding.instance.addObserver(KeyBoardObserver.instance);
    super.onReady();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(KeyBoardObserver.instance);
    objectMgr.myGroupMgr
        .off(MyGroupMgr.eventGroupInfoUpdated, _onGroupInfoUpdated);
    objectMgr.sharedRemoteDB
        .off("$blockOptDelete:${DBChat.tableName}", _onChatKicked);
    objectMgr.chatMgr.off(ChatMgr.eventChatKicked, _onChatKicked);
    objectMgr.chatMgr.off(ChatMgr.eventChatJoined, _onChatJoined);
    objectMgr.chatMgr.off(ChatMgr.eventChatDisband, _onChatKicked);
    objectMgr.chatMgr.off(ChatMgr.eventChatMuteChanged, _onMuteChanged);
    objectMgr.chatMgr.off(CallMgr.eventTopFloating, _onTopFloatingUpdate);
    objectMgr.chatMgr.off(ChatMgr.eventChatEncryptionUpdate, _onChangeEncryptionUpdate);
    objectMgr.stickerMgr.updateRemoteRecentStickers();

    //重新設置語音sdk的配置
    agoraHelper.resetAudioSdkConfig();
    agoraHelper.isInGroupChatView = false;
    super.onClose();
  }

  void _onTopFloatingUpdate(Object sender, Object type, Object? data) {
    if (data is double) {
      downOffset.value = data;
      update();
    }
  }

  /// =========================== 监听事件回调 ===================================

  void _onChangeEncryptionUpdate(sender, type, data) {
    if (data != null && chat.chat_id == data.chat_id) {
      update();
      if (chat.isEncrypted && sender != objectMgr.encryptionMgr) {
        objectMgr.encryptionMgr.checkForFirstTimeToast(chat);
      }
    }
  }

  void _onChatKicked(sender, type, data) {
    if (data != null && chat.id == data.id) {
      chatIsDeleted.value = true;
    }
    update();
  }

  void _onChatJoined(sender, type, data) {
    if (data != null && chat.id == data.id) {
      chatIsDeleted.value = false;
      onChatReload(sender, type, data);
    }
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

  void _onGroupInfoUpdated(Object sender, Object event, Object? data) {
    if (data == null) return;

    if (data is Group) {
      if (data.id != group.value!.id) return;

      /// member的数量发生变化
      if (objectMgr.myGroupMgr.isGroupValid(data.id)) {
        if (data.members.length != groupMembers.length) {
          groupMembers.assignAll(data.members.cast<Map<String, dynamic>>());
          sharedDataManager.saveGroupInfo(group.toJson());
        }

        List<int> adminList = [];
        if (group.value!.admins.isNotEmpty) {
          adminList = group.value!.admins.map<int>((e) => e as int).toList();
        }
        permission.value = group.value!.permission;
        isScreenshotEnabled = GroupPermissionMap.groupPermissionScreenshot
            .isAllow(permission.value);
        if (objectMgr.userMgr.isMe(group.value!.owner)) {
          isOwner = true;
          isAdmin = false;
          getMemberPermission(false);
        } else if (adminList.isNotEmpty &&
            adminList.contains(objectMgr.userMgr.mainUser.uid)) {
          isOwner = false;
          isAdmin = true;
          getMemberPermission(false);
        } else {
          isOwner = false;
          isAdmin = false;
          getMemberPermission(true);
        }

        _checkExpireTime();
      } else {
        isScreenshotEnabled = false;
        groupMembers.clear();
      }
    }
  }

  /// ========================== 监听事件回调结束 =================================a
  void getGroupInfo() {
    group.value = objectMgr.myGroupMgr.getGroupById(chat.id);
    if (group.value != null) {
      _checkExpireTime();
      groupMembers.assignAll(group.value!.members.cast<Map<String, dynamic>>());
      loadRemoteGroup();
    } else {
      loadDBGroup();
    }

    // configColors();
  }

  loadDBGroup() async {
    group.value = await objectMgr.myGroupMgr.loadDBGroupById(chat.id);
    if (group.value != null) {
      groupMembers.assignAll(group.value!.members.cast<Map<String, dynamic>>());
    }
    loadRemoteGroup();
  }

  loadRemoteGroup() async {
    // 远程获取
    group.value =
        await objectMgr.myGroupMgr.getGroupByRemote(chat.id, notify: true);
    if (group.value != null) {
      chatIsDeleted.value = !objectMgr.myGroupMgr.isGroupValid(chat.chat_id);
      permission.value = group.value!.permission;
      groupMembers.assignAll(group.value!.members.cast<Map<String, dynamic>>());
      isScreenshotEnabled = GroupPermissionMap.groupPermissionScreenshot
          .isAllow(group.value!.permission);
      sharedDataManager.saveGroupInfo(group.toJson());
    }

    if (groupMembers.isNotEmpty) {
      List<int> adminList = [];
      if (group.value != null) {
        if (group.value!.admins.isNotEmpty) {
          adminList = group.value!.admins.map<int>((e) => e as int).toList();
        }

        if (objectMgr.userMgr.isMe(group.value!.owner)) {
          isOwner = true;
          isAdmin = false;
          getMemberPermission(false);
        } else if (adminList.isNotEmpty &&
            adminList.contains(objectMgr.userMgr.mainUser.uid)) {
          isOwner = false;
          isAdmin = true;
          getMemberPermission(false);
        } else {
          isOwner = false;
          isAdmin = false;
          getMemberPermission(true);
        }
      }
    }
  }

  _checkExpireTime() {
    if (group.value!.isTmpGroup) {
      showEditExpireShortcutArrow.value = isOwner;

      if (isLessThan24hrsUTC(group.value!.expireTime)) {
        isGroupExpireSoon.value = true;
        startExpireCountDownTimer(group.value!.expireTime);
      }
    }
  }

  // configColors() {
  //   if (groupMembers.length > 20) {
  //     double round = groupMembers.length / 20;
  //     for (int i = 0; i < round.ceil(); i++) {
  //       memberNameColor.addAll(constMemberColor);
  //     }
  //   }
  //   memberNameColor.shuffle();
  // }

  void showVideoScreen(bool isShow) {
    isVideoRecording(isShow);
  }

  void onAudioRoomIsJoined() {
    isJoinAudioRoom.value = agoraHelper.isJoinAudioRoom;
  }

  void onTapSearchDesktop() async {
    Chat? chat = await objectMgr.chatMgr
        .getGroupChatById(group.value!.uid, remote: true);
    if (chat != null) {
      if (Get.isRegistered<GroupChatController>(tag: chat.id.toString())) {
        Get.find<CustomInputController>(tag: chat.id.toString())
            .inputFocusNode
            .requestFocus();
        isSearching(true);
      } else {
        if (Get.find<HomeController>().pageIndex.value == 0) {
          Routes.toChat(chat: chat);
        }
      }
    }
  }

  @override
  onChatReload(sender, type, data) async {
    loadRemoteGroup();
    super.onChatReload(sender, type, data);
  }

  void clearSearchState() {
    isListModeSearch.value = false;
    isTextTypeSearch.value = true;
    searchedIndexList.clear();
  }

  void onSearchChanged(String value) {
    String param = '${localized(chatFrom)}:';
    if (param == searchParam.value) {
      //pdebug("kkkkkk ====== >   这个时候，应该回到聊天模式");
      // this.isTextTypeSearch.value = true;
      searchFocusNode.unfocus();
      clearSearching();
      clearSearchState();
    } else {
      switchChatSearchType(
        isTextModeSearch: false,
        isSingleChat: false,
        searchParam: value,
        chat: chat,
      );
    }
  }

  String getHeaderText() {
    switch (objectMgr.appInitState.value) {
      case AppInitState.no_network:
      case AppInitState.no_connect:
      case AppInitState.connecting:
        return objectMgr.appInitState.value.toName;
      default:
        return UserUtils.groupMembersLengthInfo(groupMembers.length);
    }
  }
}
