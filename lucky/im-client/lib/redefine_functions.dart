import 'package:im/im_plugin.dart';
import 'package:im_common/im_common.dart';
import 'package:get/get.dart';

import 'im/custom_content/chat_content_controller.dart';
import 'im/group_chat/group_chat_controller.dart';


class RedefineFunctions {
  static void initStateChatContentView(ChatContentController controller) {
    gameManager.onRefreshCurrentChatList = () {
      controller.chatController.previousMessageList.value =
          List.from(controller.chatController.previousMessageList);
    };
    gameManager.onGameEnterUpdateTopUI = () {
      controller.isNeedUpdateTopUI.value = true;
    };
  }
  static void initGroupChatView(GroupChatController controller,String tag) {
    //初始化切換原生鍵盤的方法
    gameManager.onChangeSwitchKeyboard = () {
      // controller.isChangedSlide = true;
      // controller.switchKeyboard(inputTextController);
    };
    //取得當前路由到遊戲
    gameManager.currentRouteName = Get.currentRoute;
    //設定當前群組消息過濾
    // gameManager.setCurrentFilterByGroup(int.parse(tag));
    //TODO:設定當前群組消息過濾紀錄(之後要移除)
    // gameManager.setCurrentFilterLogByGroup(int.parse(tag));
    //設定當前群組的本地緩存資料
    sharedDataManager.setCurrentLocalGroup(int.parse(tag));

    final fromCollection = Get.arguments['fromCollection'];
    final appId = Get.arguments['appId'];
    final  gameId = Get.arguments['gameId'];
    final  gameName = Get.arguments['gameName'];
    gameManager.osFromCollection = fromCollection;
    gameManager.osAppId = appId;
    gameManager.osGameId = gameId;
    gameManager.osGameName = gameName;
  }
}
