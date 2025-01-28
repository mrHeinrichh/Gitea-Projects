import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/im_plugin.dart';
import 'package:im_common/im_common.dart';

import '../../main.dart';
import '../../managers/chat_mgr.dart';
import '../../network/servers_uri_mgr.dart';
import '../../object/chat/chat.dart';
import '../../object/chat/message.dart';
import '../../object/user.dart';
import '../../utils/plugin_manager.dart';
import '../../views_desktop/component/chat_option_menu.dart';
import '../agora_helper.dart';
import '../base/base_chat_controller.dart';
import '../model/group/group.dart';

class GameGroupChatController extends BaseChatController {
  final group = Rxn<Group>();
  //是否靜音
  RxBool isMute = RxBool(false);

  //是否進入語音聊天室
  RxBool isJoinAudioRoom = RxBool(false);
  //是否顯示投注鍵盤
  RxBool isShowGameKeyboard = RxBool(false);

  @override
  void onInit() {
    super.onInit();
    if (!chat.isDisband && !chat.isKick) {
      //如果群組解散或是自己退群都不須打語音的api
      sharedDataManager.setGid(chat.id);
    }
    sharedDataManager.imageBaseUrl = serversUriMgr.download2Uri?.origin ?? '';
    isMute.value = chat.isMute;
    objectMgr.chatMgr.on(ChatMgr.eventChatMuteChanged, _onMuteChanged);
    agoraHelper.isInGroupChatView = true;
    GameManager.shared.onSendBetMsg = (String msg, BetMsgType type) async {
      if (type == BetMsgType.normal) {
        await objectMgr.chatMgr
            .send(sharedDataManager.groupId, messageTypeFollowBet, msg);
      }
      return Future(() => true);
    };

    GameManager.shared.onGetUserName = (int uid) async {
      User? user = await objectMgr.userMgr.loadUserById(uid);
      return user?.nickname ?? "--";
    };
    gameManager.onGameMessageSendFunc = (int msgId, String msgContent) {
      Message lastMsg = Message.creator();
      lastMsg.create_time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (nextMessageList.isNotEmpty) {
        lastMsg = nextMessageList.last;
        for (int i = nextMessageList.length - 1; i >= 0; i--) {
          Message msgTmp = nextMessageList[i];
          bool isMine = objectMgr.userMgr.isMe(msgTmp.send_id);
          if (gameMessageIds.contains(msgTmp.typ) && !isMine) {
            lastMsg = msgTmp;
            break;
          }
        }
      } else {
        if (previousMessageList.isNotEmpty) {
          lastMsg = previousMessageList.first;
          for (int i = 0; i <= previousMessageList.length - 1; i++) {
            Message msgTmp = previousMessageList[i];
            bool isMine = objectMgr.userMgr.isMe(msgTmp.send_id);
            if (gameMessageIds.contains(msgTmp.typ) && !isMine) {
              lastMsg = msgTmp;
              break;
            }
          }
        }
      }
      Message msg = getGameMessage(lastMsg, msgId, msgContent);
      addMoreNewMessageFromLock(msg);
    };
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

  void onAudioRoomIsJoined() {
    isJoinAudioRoom.value = agoraHelper.isJoinAudioRoom;
  }

  loadRemoteGroup() async {
    // 远程获取
    group.value =
        await objectMgr.myGroupMgr.getGroupByRemote(chat.id, notify: true);
    if (group.value != null) {
      sharedDataManager.saveGroupInfo(group.toJson());
      PluginManager.shared.onSetGroupOwnerAdmin(sharedDataManager.isOwnerAdmin);
    }
  }

  onCancelFocus() {
    super.onCancelFocus();
    gameManager.panelController(
      entrance: ImConstants.gameBetsOptionList,
      control: false,
    );
  }

  @override
  void handleMessage20005(Message message, bool isMine) {
    super.handleMessage20005(message, isMine);
    if (message.typ == 20005) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          messageListController.animateTo(
              messageListController.position.minScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.linear);
        });
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        messageListController.animateTo(
            messageListController.position.minScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.linear);
      });
    }

    if (!isMine) {
      chat.readMessage(message.chat_idx);
    }

    setDownButtonVisible(false);
    unreadCount.value = 0;
  }

  Message getGameMessage(Message message, int messageId, String content) {
    Message gameMessage = Message.creator();
    gameMessage.id = message.id;
    gameMessage.typ = messageId;
    gameMessage.send_id = 0;
    gameMessage.content = content;
    if (message.chat_idx >= 0) {
      gameMessage.chat_idx = message.chat_idx - 1000000;
    } else {
      gameMessage.chat_idx = message.chat_idx + 1;
    }
    if (message.chat_id >= 0) {
      gameMessage.chat_id = message.chat_id - 1000000;
    } else {
      gameMessage.chat_id = message.chat_id + 1;
    }

    int time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    gameMessage.create_time = message.create_time;
    gameMessage.send_time = time;
    return gameMessage;
  }

  @override
  void addGameMessage(Message newMessage) {
    super.addGameMessage(newMessage);
    bool isMine = objectMgr.userMgr.isMe(newMessage.send_id);
    if (gameMessageIds.contains(newMessage.typ) && !isMine) {
      List<Message> array = [];
      if (gameMessageGroup.isNotEmpty) {
        gameMessageGroup.add(newMessage);
        array.addAll(gameMessageGroup);
        gameMessageList.last = array;
      } else {
        gameMessageGroup.add(newMessage);
        array.addAll(gameMessageGroup);
        gameMessageList.add(array);
      }

      normalMessageGroup.clear();
    } else {
      gameMessageGroup.clear();

      List<Message> array = [];
      if (normalMessageGroup.isNotEmpty) {
        normalMessageGroup.add(newMessage);
        array.addAll(normalMessageGroup);
        normalMessageList.last = array;
      } else {
        normalMessageGroup.add(newMessage);
        array.addAll(normalMessageGroup);
        normalMessageList.add(array);
      }
    }
    print('object');
  }

  @override
  void onClose() {
    GameManager.shared.onSendBetMsg = (String msg, BetMsgType type) {};
    GameManager.shared.onGetUserName = (int uid) {};
    //關閉遊戲鍵盤
    GameManager.shared.onShowBetPanel(KeyboardInteractionType.none);
    objectMgr.chatMgr.off(ChatMgr.eventChatMuteChanged, _onMuteChanged);
    //重新設置語音sdk的配置
    agoraHelper.resetAudioSdkConfig();
    agoraHelper.isInGroupChatView = false;
    super.onClose();
  }
}
