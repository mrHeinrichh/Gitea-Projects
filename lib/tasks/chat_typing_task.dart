import 'package:get/get.dart';
import 'package:jxim_client/managers/chat_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat_input.dart';
import 'package:jxim_client/tasks/schedule_task.dart';

class ChatTypingTask extends ScheduleTask {
  ChatTypingTask() : super(const Duration(milliseconds: 200));

  // key : 聊天室Id
  // value [key] : 用户Id
  // value [value] : 用户输入时的时间
  static RxMap<int, RxList<ChatInput>> whoIsTyping =
      <int, RxList<ChatInput>>{}.obs;

  @override
  Future<void> execute() async {
    // 处理 whoIsTyping
    if (whoIsTyping.isNotEmpty) {
      List<ChatInput> rmInputs = [];
      whoIsTyping.forEach((chatId, typingData) {
        for (var chatInput in typingData) {
          if (chatInput.currentTimestamp + 5 <
              DateTime.now().millisecondsSinceEpoch ~/ 1000) {
            rmInputs.add(chatInput);
          }
        }
      });

      for (final chatInput in rmInputs) {
        if (chatInput.state.isSendingMedia &&
            (chatInput.currentTimestamp + 30 >
                DateTime.now().millisecondsSinceEpoch ~/ 1000)) continue;

        removeTypingData(chatInput);
        chatInput.state = ChatInputState.noTyping;
        objectMgr.chatMgr
            .event(this, ChatMgr.eventChatIsTyping, data: chatInput);
      }
    }
  }

  static void addTypingData(ChatInput chatInput) {
    if (whoIsTyping[chatInput.chatId] != null) {
      List<ChatInput> chatInputs = whoIsTyping[chatInput.chatId] ?? [];
      final index = chatInputs.indexWhere((e) => e.sendId == chatInput.sendId);
      if (index == -1) {
        chatInputs.add(chatInput);
      } else {
        chatInputs[index] = chatInput;
      }
    } else {
      whoIsTyping[chatInput.chatId] = [chatInput].obs;
    }

    sortInputs(whoIsTyping[chatInput.chatId]!);
  }

  static void removeTypingData(ChatInput chatInput) {
    whoIsTyping[chatInput.chatId]?.removeWhere(
      (element) =>
          element.sendId == chatInput.sendId &&
          element.chatId == chatInput.chatId,
    );
  }

  static List<ChatInput> sortInputs(List<ChatInput> inputs) {
    inputs.sort((a, b) {
      if (a.state.isSendingMedia) {
        return 1;
      } else if (b.state == ChatInputState.noTyping) {
        return -1;
      } else {
        return 0;
      }
    });
    return inputs.reversed.toList();
  }
}
