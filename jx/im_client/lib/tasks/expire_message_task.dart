import 'dart:async';

import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/tasks/schedule_task.dart';

class ExpireMessageTask extends ScheduleTask {
  ExpireMessageTask({
    Duration delay = const Duration(milliseconds: 1000),
  }) : super(delay);

  static int expireTime = 35;
  static final Map<int, List<Message>> _incomingExpireMessages = {};
  static int updateTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  static bool isRun = false;

  Timer? _desktopTimer;

  @override
  execute() async {
    if (objectMgr.loginMgr.isDesktop && !isRun) {
      isRun = true;
      _desktopTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        if (!objectMgr.loginMgr.isLogin) {
          _desktopTimer?.cancel();
          _incomingExpireMessages.clear();
        } else {
          run();
        }
      });
    } else {
      run();
    }
  }

  run() async {
    int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (nowTime - updateTime > expireTime - 5) {
      objectMgr.chatMgr.loadChatExpireMessages(expireTime);
      updateTime = nowTime;
    }
    _incomingExpireMessages.forEach((key, value) {
      checkExpiredMessage(key, value);
    });
  }

  static addIncomingExpireMessages(Message msg) {
    int nowTime = (DateTime.now().millisecondsSinceEpoch - 500) ~/ 1000;
    if (msg.expire_time <= nowTime + expireTime) {
      if (_incomingExpireMessages[msg.chat_id] == null) {
        _incomingExpireMessages[msg.chat_id] = [];
      }
      if (_incomingExpireMessages[msg.chat_id]!
              .any((element) => element.id == msg.id) ==
          false) {
        _incomingExpireMessages[msg.chat_id]!.add(msg);
      }
    }
  }

  Future<void> checkExpiredMessage(int chatId, List<Message> list) async {
    List<Message> tempList = List.from(list);
    for (final message in tempList) {
      if (message.isExpired) {
        _incomingExpireMessages[chatId]!.remove(message);

        Chat? chat = objectMgr.chatMgr.getChatById(chatId);
        if (chat != null) {
          if (message.chat_idx > chat.read_chat_msg_idx) {
            if (chat.unread_count > 0) {
              chat.unread_count--;
              if (chat.isCountUnread &&
                  objectMgr.chatMgr.totalUnreadCount.value > 0) {
                objectMgr.chatMgr.totalUnreadCount.value--;
              }
            }
          }
        }
        if (objectMgr.chatMgr.lastChatMessageMap[chatId] != null) {
          if (objectMgr.chatMgr.lastChatMessageMap[chatId]!.id == message.id) {
            objectMgr.chatMgr.updateLatestMessage(message);
          }
        }
        objectMgr.chatMgr.event(
          objectMgr.chatMgr,
          ChatMgr.eventAutoDeleteMsg,
          data: message,
        );
      }
    }
  }
}
