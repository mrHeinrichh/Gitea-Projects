import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/api/group_invite_link.dart';
import 'package:jxim_client/im/chat_info/tab_option/member/add_member/join_invitation_bottom_sheet.dart';
import 'package:jxim_client/im/model/group/group.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/routes.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:jxim_client/utils/localization/app_localizations.dart';
import 'package:jxim_client/utils/share_link_util.dart';
import 'package:jxim_client/utils/theme/color/color_code.dart';
import 'package:jxim_client/utils/toast.dart';
import 'package:jxim_client/views/component/friend_request_bottom_sheet.dart';
import 'package:openinstall_flutter_plugin/openinstall_flutter_plugin.dart';

final openInstallMgr = OpenInstallMgr();

class OpenInstallMgr {
  OpenInstallMgr._internal();

  factory OpenInstallMgr() => _instance;

  static final OpenInstallMgr _instance = OpenInstallMgr._internal();
  late OpeninstallFlutterPlugin _openinstallFlutterPlugin;
  late Map<String, Object> wakeupData;
  late Map<String, Object> installData;

  void init() {
    _openinstallFlutterPlugin = OpeninstallFlutterPlugin();
    // _openinstallFlutterPlugin.setDebug(false);
    _openinstallFlutterPlugin.setDoMain(serversUriMgr.openInstallUrl);
  }

  void handleWakeupFriendAndGroupLink() {
    _openinstallFlutterPlugin.init(
      wakeupFriendAndGroupLinkHandler,
      alwaysCallback: true,
    );
  }

  void handleInstallFriendAndGroupLink() {
    _openinstallFlutterPlugin.install(installFriendAndGroupLinkHandler);
  }

  void handleInstallInviterInfo() {
    _openinstallFlutterPlugin.install(installInviterInfoHandler);
  }

  Future<void> wakeupFriendAndGroupLinkHandler(Map<String, Object> data) async {
    pdebug("wakeupHandler : $data");
    wakeupData = data;
    final bindData = data['bindData'];
    late dynamic encryptedTextBase64;
    try {
      final dataMap = jsonDecode(data['bindData'].toString());
      encryptedTextBase64 = dataMap['data'];
    } catch (e) {
      encryptedTextBase64 = bindData;
    }
    final json = ShareLinkUtil.aesBase64Decode(encryptedTextBase64);
    final Map<String, dynamic> params = jsonDecode(json);
    if (params['action'] == 0) {
      // 加好友
      handleFriendAction(params);
    } else if (params['action'] == 1) {
      // 加群组
      final host = Uri.parse(Config().officialUrl).host;
      final inviteLink = '$host/me/${Uri.encodeComponent(encryptedTextBase64)}';
      handleGroupAction(inviteLink, params);
    }
  }

  Future<void> installFriendAndGroupLinkHandler(
    Map<String, Object> data,
  ) async {
    pdebug("installHandler : $data");
    installData = data;
    final bindData = data['bindData'];
    late dynamic encryptedTextBase64;
    try {
      final dataMap = jsonDecode(data['bindData'].toString());
      encryptedTextBase64 = dataMap['data'];
    } catch (e) {
      encryptedTextBase64 = bindData;
    }
    final json = ShareLinkUtil.aesBase64Decode(encryptedTextBase64);
    final Map<String, dynamic> params = jsonDecode(json);
    if (params['action'] == 0) {
      // 加好友
      handleFriendAction(params);
    } else if (params['action'] == 1) {
      // 加群组
      final host = Uri.parse(Config().officialUrl).host;
      final inviteLink = '$host/me/${Uri.encodeComponent(encryptedTextBase64)}';
      handleGroupAction(inviteLink, params);
    }
  }

  void handleFriendAction(Map<String, dynamic> params) async {
    final uid = params['uid'];
    final user = await objectMgr.userMgr.loadUserById2(uid);
    assert(user != null, 'User cannot be null');
    final relationship = user?.relationship;
    if (relationship == Relationship.friend) {
      // 已是好友，则直接进入好友聊天
      final chat = await objectMgr.chatMgr
          .getChatByFriendId(uid, remote: serversUriMgr.isKiWiConnected);
      assert(chat != null, 'Chat cannot be null');
      if (objectMgr.loginMgr.isDesktop) {
        Routes.toChat(chat: chat!);
      } else {
        Routes.toChat(chat: chat!);
      }
    } else if (relationship == Relationship.self) {
      // 是自己，则进入好友信息页
      Get.toNamed(
        RouteName.chatInfo,
        arguments: {
          'uid': uid,
        },
        id: objectMgr.loginMgr.isDesktop ? 1 : null,
      );
    } else {
      // 不是好友，显示弹窗
      showModalBottomSheet(
        context: Get.context!,
        isDismissible: true,
        isScrollControlled: true,
        barrierColor: colorOverlay40,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return FriendRequestBottomSheet(user: user!);
        },
      );
    }
  }

  void handleGroupAction(String inviteLink, Map<String, dynamic> params) async {
    final uid = params['uid'];
    final gid = params['gid'];
    bool isJoined = await objectMgr.myGroupMgr
        .isGroupMember(gid!, objectMgr.userMgr.mainUser.id);
    if (!isJoined) {
      final user = await objectMgr.userMgr.loadUserById2(uid);
      assert(user != null, 'handleGroupAction: User cannot be null');
      final relationship = user?.relationship;
      bool isFriend = relationship == Relationship.friend;
      bool isSelf = relationship == Relationship.self;
      final groupInfo = await getGroupInfoByLink(inviteLink);
      if (groupInfo == null) {
        Toast.showToast(localized(invitaitonLinkHasExpired));
        return;
      }
      final group = Group();
      group.uid = gid;
      group.name = groupInfo.groupName ?? '';
      group.icon = groupInfo.groupIcon ?? '';
      final isConfirmed = await showModalBottomSheet<bool>(
        context: Get.context!,
        isScrollControlled: true,
        barrierColor: colorOverlay40,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return JoinInvitationBottomSheet(
            group: group,
            userName: user!.nickname,
            isFriend: isFriend || isSelf,
          );
        },
      );
      if (isConfirmed == true) {
        await joinGroupByLink(gid, inviteLink);
      } else {
        return;
      }
    }
    final chat = await objectMgr.chatMgr.getChatByGroupId(gid);
    if (chat == null) {
      Toast.showToast(localized(chatRoomNotReadyTryLater));
      return;
    }
    Routes.toChat(chat: chat);
  }

  Future<void> installInviterInfoHandler(Map<String, Object> data) async {
    if (notBlank(data['bindData'])) {
      final inviterData =
          jsonDecode(data['bindData'].toString()) as Map<String, dynamic>;
      objectMgr.loginMgr.inviterSecret = inviterData["secret"];
    }
    pdebug("installHandler=========> install result: $data");
  }
}
