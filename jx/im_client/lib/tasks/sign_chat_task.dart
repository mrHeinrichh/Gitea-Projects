import 'package:collection/collection.dart';
import 'package:jxim_client/api/encryption.dart';
import 'package:jxim_client/end_to_end_encryption/model/encryption_model.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/user.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/utils/encryption/rsa_encryption.dart';

class SignChatTask extends ScheduleTask {
  SignChatTask({
    Duration delay = const Duration(milliseconds: 5000),
  }) : super(delay);

  static final Map<int, int> signChatRound = {};
  static final List<Message> _signSelfChatMessages = [];
  static final List<Message> _signChatMessages = [];
  static int count = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  @override
  execute() async {
    if (!notBlank(objectMgr.encryptionMgr.encryptionPrivateKey)) {
      return;
    }

    if (_signChatMessages.isEmpty) {
      return;
    }
    bool startSign = false;
    bool isClean = true;
    if (objectMgr.userMgr.mainUser.uid % 10 == count % 10) {
      startSign = true;
    }
    List<Message> messagesToRemove = [];
    List<ChatSession> sessions = [];
    for (var msg in _signChatMessages) {
      MessageReqSignChat signChatMsg =
          msg.decodeContent(cl: MessageReqSignChat.creator);
      bool isFriend = false;
      if (!startSign) {
        User? user = objectMgr.userMgr.getUserById(signChatMsg.uid);
        final relationship = user?.relationship;
        isFriend = relationship == Relationship.friend;
      }

      if (isFriend || startSign == true) {
        bool signSuccess = await signChatMessage(sessions, msg);
        if (signSuccess) {
          messagesToRemove.add(msg);
        } else {
          isClean = false;
        }
      }
    }
    if (sessions.isNotEmpty) {
      bool success = await updateChatCiphers(sessions);
      if (!success) {
        isClean = false;
        for (int i = 0; i < sessions.length; i++) {
          messagesToRemove.removeWhere(
              (element) => element.message_id == sessions[i].msgId);
        }
      } else {
        sessions.clear();
      }
    }
    for (var msg in messagesToRemove) {
      _signChatMessages.remove(msg);
    }
    count++;
    if (startSign == true && isClean) {
      _signChatMessages.clear();
    }
  }

  Future<bool> signChatMessage(List<ChatSession> sessions, Message msg) async {
    MessageReqSignChat messageReqSignChat =
        msg.decodeContent(cl: MessageReqSignChat.creator);
    Chat? chat = objectMgr.chatMgr.getChatById(msg.chat_id);

    if (chat == null) {
      return false;
    }

    if (!chat.isChatKeyValid || !chat.isActiveChatKeyValid) {
      //若会话密钥有效才存入签名任务队列，否则都会产生多余任务及脏数据
      return false;
    }
    try {
      int round = messageReqSignChat.round;
      if (messageReqSignChat.reset || messageReqSignChat.newSession == false) {
        round = round + 1;
      }
      String newKey = objectMgr.encryptionMgr.getCalculatedKey(chat, round);
      if (!notBlank(newKey)) {
        objectMgr.chatMgr.localDelMessage(msg);
        return true;
      }
      String content =
          RSAEncryption.encrypt(newKey, messageReqSignChat.publicKey);
      List<ChatKey> updatedKeys = [];
      updatedKeys.add(
          ChatKey(uid: messageReqSignChat.uid, session: content, round: round));
      ChatSession session = ChatSession(
          chatKeys: updatedKeys,
          chatId: msg.chat_id,
          round: round,
          chatIdx: msg.chat_idx,
          msgId: msg.message_id);
      sessions.add(session);
    } catch (e) {
      //
    }

    return true;
  }

  static addSignChatMessage(Chat chat, Message msg) {
    MessageReqSignChat messageReqSignChat =
        msg.decodeContent(cl: MessageReqSignChat.creator);
    if (objectMgr.userMgr.isMe(messageReqSignChat.uid)) {
      if (chat.isChatKeyValid) {
        objectMgr.chatMgr.localDelMessage(msg);
        return;
      }
      Message? message = _signSelfChatMessages
          .firstWhereOrNull((element) => element.message_id == msg.message_id);
      if (message == null) {
        _signSelfChatMessages.add(msg);
        objectMgr.encryptionMgr.addSignRequest(
            {chat.chat_id: messageReqSignChat.round},
            sendApi: false);
        int round = messageReqSignChat.round;
        if (messageReqSignChat.reset ||
            messageReqSignChat.newSession == false) {
          round = round + 1;
        }
        if (signChatRound[chat.chat_id] == null ||
            signChatRound[chat.chat_id]! < round) {
          signChatRound[chat.chat_id] = round;
          objectMgr.chatMgr.event(objectMgr.chatMgr, ChatMgr.eventDecryptChat,
              data: chat.chat_id);
        }
      }
    } else {
      Message? message = _signChatMessages
          .firstWhereOrNull((element) => element.message_id == msg.message_id);
      if (message == null) {
        _signChatMessages.add(msg);
      }
    }
  }

  static delSignChatMessage(Chat chat, int message_id) {
    Message? message = _signChatMessages
        .firstWhereOrNull((element) => element.message_id == message_id);
    if (message != null) {
      _signChatMessages.remove(message);
    }
    message = _signSelfChatMessages
        .firstWhereOrNull((element) => element.message_id == message_id);
    if (message != null) {
      _signSelfChatMessages.remove(message);
      signChatRound.remove(chat.chat_id);
      objectMgr.encryptionMgr.removeSignRequest(chat);
      objectMgr.chatMgr.localDelMessage(message);
    }
  }
}
