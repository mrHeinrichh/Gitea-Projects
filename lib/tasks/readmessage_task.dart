import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/tasks/schedule_task.dart';

class ReadMessageTask extends ScheduleTask {
  ReadMessageTask({
    Duration delay = const Duration(milliseconds: 1000),
  }) : super(delay);

  final Map<int, int> readMessageMap = {};

  @override
  execute() async {
    if (readMessageMap.isNotEmpty) {
      List<Chat> removedChats = [];
      readMessageMap.forEach((chatId, maxChatIdx) {
        Chat? chat = objectMgr.chatMgr.getChatById(chatId);
        if (chat != null) {
          if (maxChatIdx > chat.read_chat_msg_idx) {
            chat.readMessage(maxChatIdx);
            removedChats.add(chat);
          }
        }
      });

      for (final chat in removedChats) {
        readMessageMap.remove(chat.id);
      }

      removedChats.clear();
    }
  }

  addReadMessage(Message message) {
    if (readMessageMap.containsKey(message.chat_id)) {
      if (readMessageMap[message.chat_id]! < message.chat_idx) {
        readMessageMap[message.chat_id] = message.chat_idx;
      }
    } else {
      readMessageMap[message.chat_id] = message.chat_idx;
    }
  }

  clearChatRead(int chatId) {
    readMessageMap.remove(chatId);
  }

  clear() {
    readMessageMap.clear();
  }
}
