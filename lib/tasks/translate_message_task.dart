import 'package:get/get.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/message.dart';
import 'package:jxim_client/object/chat/translation_model.dart';
import 'package:jxim_client/tasks/schedule_task.dart';

class TranslateMessageTask extends ScheduleTask {
  TranslateMessageTask({
    Duration delay = const Duration(milliseconds: 1000),
  }) : super(delay);

  final translateMessageList = [];

  @override
  execute() async {
    if (translateMessageList.isNotEmpty) {
      List removeProcessed = [];
      List copyOfList = List.from(translateMessageList);

      for (var element in copyOfList) {
        Message msg = element['message'];
        String locale = element['locale'];
        int visualType = element['visualType'];
        if (msg.typ == messageTypeVoice) {
          if (Get.isRegistered<CustomInputController>(
            tag: msg.chat_id.toString(),
          )) {
            await Get.find<CustomInputController>()
                .chatController
                .transcribe(msg);
          }
        } else {
          TranslationModel? model = msg.getTranslationModel();

          if (model == null || !notBlank(model.translation[locale])) {
            await objectMgr.chatMgr.getMessageTranslation(
              msg.messageContent,
              locale: locale,
              message: msg,
              visualType: visualType,
            );
          }
        }

        removeProcessed.add(element);
      }

      /// after processed
      for (final element in removeProcessed) {
        translateMessageList.remove(element);
      }
      removeProcessed.clear();
    }
  }

  addTranslateTask(Message message, String locale, int visualType) {
    final data = {
      'message': message,
      'locale': locale,
      'visualType': visualType,
    };

    translateMessageList.add(data);
  }

  clear() {
    translateMessageList.clear();
  }
}
