import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/object/chat/chat.dart';

class TranslateVisualController extends GetxController {
  Chat? chat;
  bool incomingChatSettings = true;
  final currentVisualType = 0.obs;

  TranslateVisualController();

  TranslateVisualController.desktop(this.chat, this.incomingChatSettings);

  @override
  void onInit(){
    super.onInit();
    if(!objectMgr.loginMgr.isDesktop){
      chat = Get.arguments[0];
      incomingChatSettings = Get.arguments[1];
    }
    if (incomingChatSettings) {
      currentVisualType.value = chat!.visualTypeIncoming;
    } else {
      currentVisualType.value = chat!.visualTypeOutgoing;
    }
  }

  onTapItem(int val) => currentVisualType.value = val;

  onTapDoneButton() {
    if (incomingChatSettings) {
      chat!.visualTypeIncoming = currentVisualType.value;
    } else {
      chat!.visualTypeOutgoing = currentVisualType.value;
    }
    objectMgr.chatMgr.saveTranslationToChat(chat!);
    objectMgr.loginMgr.isDesktop
        ? Get.back(id: 1) : Get.back();
  }
}
