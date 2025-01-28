import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'dart:async'; 

class ExpireMessageTask extends ScheduleTask {
  ExpireMessageTask({int delay = 1*1000, bool isPeriodic = true})
      : super(delay, isPeriodic);

  static int expireTime = 15 * 60;
  static final Map<int, List<Message>> _incomingExpireMessages = {};
  static int updateTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  static bool isRun = false;

  @override
  execute() async {
    if(objectMgr.loginMgr.isDesktop &&!isRun){
      isRun = true;
      Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        run();
      });
    }else{
      run();
    }
  }

  run() async {
    int now_time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if(now_time - updateTime > expireTime - 60){
      objectMgr.chatMgr.loadChatExpireMessages(expireTime);
      updateTime = now_time;
    }
    _incomingExpireMessages.forEach((key, value){
      checkExpiredMessage(key, value);
    });
  }

  static addIncomingExpireMessages(Message msg) {
    int now_time = (DateTime.now().millisecondsSinceEpoch - 500) ~/ 1000;
    if(msg.expire_time <= now_time + expireTime) {
      if(_incomingExpireMessages[msg.chat_id] == null){
        _incomingExpireMessages[msg.chat_id] = [];
      }
      if(_incomingExpireMessages[msg.chat_id]!.any((element) => element.id == msg.id) == false){
        _incomingExpireMessages[msg.chat_id]!.add(msg);
      }
    }
  }

  Future<void> checkExpiredMessage(int chat_id, List<Message> list) async {
    List<Message> tempList = List.from(list);
    for (final message in tempList) {
      if (message.isExpired) {
        _incomingExpireMessages[chat_id]!.remove(message);

        Chat? chat = objectMgr.chatMgr.getChatById(chat_id);
        if(chat != null) {
          if(message.chat_idx > chat.read_chat_msg_idx){
            if(chat.unread_count > 0){
              chat.unread_count--;
              if(chat.isCountUnread && objectMgr.chatMgr.totalUnreadCount.value > 0){
                objectMgr.chatMgr.totalUnreadCount.value--;
              }
            }
          }
        }
        if(objectMgr.chatMgr.lastChatMessageMap[chat_id] != null){
          if(objectMgr.chatMgr.lastChatMessageMap[chat_id]!.id == message.id){
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
