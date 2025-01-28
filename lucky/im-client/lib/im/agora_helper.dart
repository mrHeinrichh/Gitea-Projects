import 'package:agora/agora_plugin.dart';
import 'package:flutter/material.dart';
import 'package:im_common/im_common.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/lang_util.dart';
import 'package:provider/provider.dart' as provider;

import '../utils/localization/app_localizations.dart';
import '../utils/net/request.dart';
import '../utils/net/response_data.dart';
import '../utils/theme/text_styles.dart';
import '../views/component/custom_alert_dialog.dart';

/// 取得聊天資訊面板元件
Widget getChatControllerWidget(BuildContext context) {
  return provider.MultiProvider(
    providers: [
      provider.ChangeNotifierProvider.value(
          value: audioManager.chatAudioViewModel),
      provider.ChangeNotifierProvider.value(value: liveMemberListPageModel),
    ],
    child: const AgoraControl(),
  );
}

AgoraHelper agoraHelper = AgoraHelper();

class AgoraHelper {
  imInit() async {
    sharedDataManager.onGameDataInitFinish = () async {
      _getChatRoomAudioUrl();
    };
  }

  bool get isOwnerAndInAudioRoom {
    if (audioManager.isOwner && audioManager.isJoinedAudioRoom) {
      return true;
    }
    return false;
  }

  bool get isJoinAudioRoom {
    if (audioManager.isJoinedAudioRoom) {
      return true;
    }
    return false;
  }

  /// 取得群組名稱
  String getGroupName() {
    return audioManager.currentChatGroupInfo.groupName;
  }

  /// 重新設置語音sdk的配置
  resetAudioSdkConfig() {
    audioManager.resetSdkConfig();
  }

  /// 全部解散
  void _disposeAll() {
    /// 退出群聊，清理解散语音引擎
    audioManager.agoraDispose();
  }

  bool _isInGroupChatView = false;

  bool get isInGroupChatView => _isInGroupChatView;

  set isInGroupChatView(bool value) {
    _isInGroupChatView = value;
    audioManager.isGroupChat = value;
  }

  /// 是否切換聊天室(例如點擊推播通知跳轉其他聊天室)
  bool _isSwitchChatRoom = false;

  bool get isSwitchChatRoom => _isSwitchChatRoom;

  set isSwitchChatRoom(bool value) {
    _isSwitchChatRoom = value;
    audioManager.isSwitchChatRoom = value;
  }

  Future<void> _getChatRoomAudioUrl() async {
    pdebug("群組id: ${sharedDataManager.groupId}");
    ResponseData res = await postChatRoomEntry({
      "gid": sharedDataManager.groupId,
    });
    if (res.code == 0) {
      CommonConstants.agoraSocketUrl = res.data[AgoraConstants.joinTalkUrl];
      audioManager.initSocket(CommonConstants.agoraSocketUrl);
      audioManager.appId = res.data[AgoraConstants.talkAppId];
      audioManager.certificate = res.data[AgoraConstants.talkToken];
    } else {
      showToast(res.message);
    }
  }

  gameManagerGetCheckCloseDialog(context,
      {Function? action, String groupName = ""}) {
    getCheckCloseDialog(context, action: action, groupName: groupName);
  }

  //重置語音條
  resetAgoraControl() {
    audioManager.chatAudioViewModel.setExitAudioRoom(false);
  }

  //呼叫取得語音群聊資訊ws
  callChatroomInfo() {
    audioManager.callChatroomInfo();
  }
}

/// 获取聊天室入口
postChatRoomEntry(Map<String, dynamic> data) async {
  String str = sharedDataManager.token;
  String token = Uri.encodeQueryComponent(str);
  final  res = await Request.doPost(
      "${AgoraConstants.getChatRoomEntry}?token=$token",
      data: data);
  return res;
}

//房主確認關閉聊天室彈窗
getCheckCloseDialog(context, {Function? action, String groupName = ""}) {
  audioManager.isDesktop
      ? showDialog(
          context: context,
          builder: (_) {
            return DesktopPopUp(
                title: commonLocalized(agoraLeaveVideoCall),
                content:
                    '${commonLocalized(agoraAreYouSureLeaveGroupChatJoinNew1)} $groupName'
                    // '${commonLocalized(agoraAreYouSureLeaveGroupChatJoinNew2)}"新群名"${commonLocalized(agoraAreYouSureLeaveGroupChatJoinNew3)}'
                    ' ${commonLocalized(agoraVideoCall)}?',
                confirmBtnFunc: () {
                  audioManager.closeAudioRoom(action: action);
                  Navigator.pop(context);
                  // if (action != null) {
                  //   action();
                  // }
                });
          })
      : showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: commonLocalized(agoraLeaveVideoCall),
              content: Text(
                commonLocalized(agoraGoBackWillLeaveVoiceCall),
                style: jxTextStyle.textDialogContent(),
                textAlign: TextAlign.center,
              ),
              confirmText: commonLocalized(agoraLeave),
              cancelText: localized(buttonCancel),
              confirmCallback: () =>
                  audioManager.closeAudioRoom(action: action),
            );
          },
        );
}
