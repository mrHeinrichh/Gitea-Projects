import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/tasks/schedule_task.dart';

class ReadMessageTask extends ScheduleTask {
  ReadMessageTask({
    Duration delay = const Duration(milliseconds: 1000),
  }) : super(delay);

  final Map<int, int> readMessageMap = {};

  @override
  execute() async {
    if (readMessageMap.isNotEmpty) {
      List<int> removedChats = [];
      readMessageMap.forEach((chatId, maxChatIdx) async {
        await objectMgr.chatMgr.updateDBChatReadChatMsgIdx(chatId, maxChatIdx);
        await objectMgr.chatMgr.sendReadMessageIdx(chatId, maxChatIdx);
        removedChats.add(chatId);
      });

      for (final chatId in removedChats) {
        readMessageMap.remove(chatId);
      }
      removedChats.clear();
    }
  }

  addReadMessage(int chat_id, int read_chat_idx) {
    if (readMessageMap.containsKey(chat_id)) {
      if (readMessageMap[chat_id]! < read_chat_idx) {
        readMessageMap[chat_id] = read_chat_idx;
      }
    } else {
      readMessageMap[chat_id] = read_chat_idx;
    }
  }

  clearChatRead(int chatId) {
    readMessageMap.remove(chatId);
  }

  clear() {
    readMessageMap.clear();
  }
}
