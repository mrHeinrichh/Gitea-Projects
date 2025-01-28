import 'package:get/get.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/services/audio_services/volume_player_service.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/im/private_chat/single_chat_controller.dart';
import 'package:jxim_client/managers/chat_mgr.dart';

final audiosToPlay = AudiosToPlay();

class AudiosToPlay {
  AudiosToPlay() {
    objectMgr.chatMgr.on(ChatMgr.eventMessageListComing, onMessageComing);
    objectMgr.chatMgr.on(ChatMgr.eventDeleteMessage, onChatMessageDelete);
  }

  dispose() {
    objectMgr.chatMgr.off(ChatMgr.eventMessageListComing, onMessageComing);
    objectMgr.chatMgr.off(ChatMgr.eventDeleteMessage, onChatMessageDelete);
  }

  Message? findNextAudio(Message currentMessage) {
    Chat? chat = objectMgr.chatMgr.getChatById(currentMessage.chat_id);
    if (chat == null) {
      return null;
    }
    final String tag = chat.chat_id.toString();
    Message? nextMessage;
    List<Message> audioList = [];
    try {
      if (chat.typ == chatTypeGroup) {
        GroupChatController chatController =
            Get.find<GroupChatController>(tag: tag);
        audioList = chatController.combinedMessageList
            .where((msg) =>
                msg.typ == messageTypeVoice &&
                msg.message_id > currentMessage.message_id)
            .toList();
      } else {
        SingleChatController chatController =
            Get.find<SingleChatController>(tag: tag);
        audioList = chatController.combinedMessageList
            .where((msg) =>
                msg.typ == messageTypeVoice &&
                msg.message_id > currentMessage.message_id)
            .toList();
      }
    } catch (e) {
      //聊天室关闭的情况下 chatController 全被释放，从之前存的数组里取
      audioList.addAll(audioListStored);
    }

    // 按 message_id 从小到大排序 （他们的大小顺序在重新进入聊天室的时候会变反）
    audioList.sort((a, b) => a.message_id.compareTo(b.message_id));

    nextMessage = audioList.firstWhereOrNull((msg) =>
        msg.typ == messageTypeVoice &&
        msg.message_id > currentMessage.message_id);

    if (nextMessage == null) {
      audioListStored.clear();
    }
    return nextMessage;
  }

  //如果chatController关闭，获取它的消息列表继续维护 来保证能自动播放下一条语音消息
  checkChatControllerOnClose(BaseChatController chatController) {
    final msg = VolumePlayerService.sharedInstance.currentMessage;
    if (msg == null) {
      return;
    }
    final int currentChatId = msg.chat_id;
    final int currentMessageId = msg.message_id;
    if (currentChatId == chatController.chat.id) {
      final audioList = chatController.combinedMessageList
          .where((msg) =>
              msg.typ == messageTypeVoice && msg.message_id > currentMessageId)
          .toList();
      audioListStored = audioList;
    }
  }

  List<Message> audioListStored = [];

  void onMessageComing(Object sender, Object type, Object? data) {
    if (data is! List<Message>) {
      return;
    }
    if (data.first.chat_id !=
            VolumePlayerService.sharedInstance.currentMessage?.chat_id ||
        data.isEmpty) {
      return;
    }
    //todo 新增语音消息的逻辑待补充 目前没有好的方案
  }

  onChatMessageDelete(sender, type, data) {
    if (data['id'] !=
        VolumePlayerService.sharedInstance.currentMessage?.chat_id) {
      return;
    }
    if (data['isClear']) {
      audioListStored.clear();
    } else {
      if (data['message'] != null) {
        for (var item in data['message']) {
          int id = 0;
          int messageId = 0;
          if (item is Message) {
            id = item.id;
          } else {
            messageId = item;
          }

          final msgDeleted = audioListStored.firstWhereOrNull((msg) {
            if (id != 0) {
              return msg.id == id;
            } else {
              return msg.message_id == messageId;
            }
          });
          if (msgDeleted != null) {
            audioListStored.remove(msgDeleted);
          }
        }
      }
    }
  }
}
