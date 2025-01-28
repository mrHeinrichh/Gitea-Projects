import 'package:get/get.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/object/chat/chat_input.dart';
import 'package:jxim_client/tasks/schedule_task.dart';

class ChatTypingTask extends ScheduleTask {
  ChatTypingTask() : super(1, true);

  // key : 聊天室Id
  // value [key] : 用户Id
  // value [value] : 用户输入时的时间
  static RxMap<int, RxList<ChatInput>> whoIsTyping = <int, RxList<ChatInput>>{}.obs;

  @override
  void execute() {
    // 处理 whoIsTyping
    if (whoIsTyping.isNotEmpty) {
      List<ChatInput> rmInputs = [];
      whoIsTyping.forEach((chatId, typingData) {
        typingData.forEach((chatInput) {
          if (chatInput.currentTimestamp + 5 < DateTime.now().millisecondsSinceEpoch ~/ 1000) {
            rmInputs.add(chatInput);
          }
        });
      });

      for(final chatInput in rmInputs){
        removeTypingData(chatInput);
        chatInput.state = 2;
        objectMgr.chatMgr.event(this, ChatMgr.eventChatIsTyping, data: chatInput);
      }
    }
  }

  static void addTypingData(ChatInput chatInput) {
    if (whoIsTyping[chatInput.chat_id] != null) {
      List<ChatInput> chatInputs = whoIsTyping[chatInput.chat_id] ?? [];
      final index = chatInputs.indexWhere((e) => e.send_id == chatInput.send_id);
      if(index == -1){
        chatInputs.add(chatInput);
      }else{
        chatInputs[index] = chatInput;
      }
    } else {
      whoIsTyping[chatInput.chat_id] = [chatInput].obs;
    }
  }

  static void removeTypingData(ChatInput chatInput) {
    whoIsTyping[chatInput.chat_id]?.removeWhere((element) =>
        element.send_id == chatInput.send_id &&
        element.chat_id == chatInput.chat_id);
  }
}
