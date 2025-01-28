import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:im/im_plugin.dart';
import 'package:im_common/im_common.dart';
import 'package:im_mini_app_plugin/im_mini_app_plugin.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import '../../home/home_controller.dart';
import '../../main.dart';
import '../../managers/utils.dart';
import '../../object/chat/reply_model.dart';
import '../../object/sticker.dart';
import '../../object/user.dart';
import '../../utils/plugin_manager.dart';
import '../model/group/group.dart';
import '../services/custom_text_editing_controller.dart';
import '../services/media/models/asset_preview_detail.dart';
import 'custom_input_controller.dart';

abstract class GameCustomInputController extends GetxController
    with GetTickerProviderStateMixin {

  /// 用来处理有且只有游戏键盘关闭时，清除游戏输入框内容
  bool isLastShowGamePanel = false;

  /// 输入控制器
  late CustomTextEditingController inputController;

  RxBool isVoiceMode = RxBool(false);

  /// 群聊类型 1.单聊 2.群聊 4.小秘书
  int type = -1;

  /// 发送状态
  RxBool sendState = RxBool(false);

  ///聊天室id
  late int chatId;

  ReplyModel? replyData;

  ///鍵盤切換的動畫控制
  late AnimationController inputAnimateController;
  late Animation<Offset> offset;

  /// 是否為群主或管理員
  bool isGroupOwnerAdmin = false;

  /// 是否為股東
  bool isShareholder = false;

  /// 是否顯示遊戲鍵盤icon
  RxBool isShowGameKeyboard = RxBool(false);

  /// 當前是否正在顯示遊戲面板
  RxBool isCurrentShowGamePanel = RxBool(false);

  /// 是否正在關閉遊戲面板狀態
  RxBool isCloseGamePanelState = RxBool(false);

  /// 是否顯示更多操作
  RxBool isShowMoreAction = RxBool(false);

  /// 是否顯示快捷短語
  RxBool isShowShortTalk = RxBool(false);

  /// 是否為一般用戶(非群主、非股東、非管理員)
  RxBool isNormalUser = RxBool(true);

  /// 一般用戶(非群主、非股東、非管理員)是否可以打字
  RxBool isNormalUserCanInput = RxBool(false);

  /// 點擊哪一個遊戲鍵盤
  RxInt clickMenuKeyboard = RxInt(-1);

  @override
  Future<void> onInit() async {
    super.onInit();
    inputAnimateController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    offset = Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, 1.0))
        .animate(inputAnimateController);
    inputAnimateController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        //動畫結束後切換鍵盤
        isShowMoreAction.value = !isShowMoreAction.value;
        inputAnimateController.reverse();
      }
    });
  }

  Future<void> onSend(
    String? text, {
    bool isSendSticker = false,
    Sticker? sticker,
    BuildContext? context,
    bool isSendContact = false,
    User? user,
    List<AssetPreviewDetail> assets = const [],
    bool isOriginalImageSend = false,
    bool sendAsFile = false,
  }) async {
    String copiedText = text ?? inputController.text;
    bool isBet = false;
    if (notBlank(copiedText)) {
      isBet = gameManager.checkIsBetAndBet(copiedText);
      if (type == 2) {
        if (!isBet) {
          if (!isShowShortTalk.value) {
            sendState.value = false;
            sendText(copiedText, reply: replyData);
          } else {
            sendState.value = false;
            clearText();
            //清空投注項
            gameManager.clearAllBetsEvent();
          }
        } else {
          if (gameManager.checkCanBet()) {
            sendState.value = false;
            clearText();
          }
        }
      } else {
        sendState.value = false;
        sendText(copiedText, reply: replyData);
      }

      objectMgr.chatMgr.replyMessageMap.remove(chatId);
      update();
    }
    if (!isBet) {
      sendState.value = false;
      clearText();
      //清空投注項
      gameManager.clearAllBetsEvent();
    }
  }

  void sendText(
    String text, {
    ReplyModel? reply,
  });

  void clearText();

  void checkLastGameKeyBoardState(bool isShowGameKeyboard) {
    if(isShowGameKeyboard){
      isLastShowGamePanel =true;
    }
  }
}

extension gameInputControllerExension on CustomInputController {
  void openGameKeyboard(bool isOpen) {
    chatController.showAttachmentView.value = false;
    gameManager.panelController(
        entrance: ImConstants.gameBetsOptionList, control: isOpen);
    isCloseGamePanelState.value = isOpen;
    isCurrentShowGamePanel.value = isOpen;
    if (isOpen) {
      /// 移除输入法焦点
      if (inputFocusNode.hasFocus) {
        inputState = 1;
      } else {
        inputState = 2;
      }
      inputFocusNode.unfocus();
    }
    update(['game_keyboard_tab'].toList());
    update();
    chatController.update();
  }

  Future<void> onOpenShortTalk(
      DefaultAssetPickerProvider? assetPickerProvider) async {
    /// 已经打开快捷短語窗口 并且 键盘没有出现
    if (isShowShortTalk.value) {
      inputState = 1;
      isShowShortTalk.value = false;
      assetPickerProvider?.selectedAssets = [];
      inputFocusNode.requestFocus();

      inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: inputController.text.length));
    } else {
      isShowShortTalk.value = true;

      /// 移除输入法焦点
      if (inputFocusNode.hasFocus) {
        inputState = 1;
      } else {
        inputState = 2;
      }
      inputFocusNode.unfocus();
    }
    isVoiceMode.value = false;
    update(['short_talk_tab'].toList());
    update();
    chatController.update();
  }

  void initState() {
    checkIsGameGroup();
    //用以控制是否要顯示遊戲鍵盤的icon
    gameManager.onChangeGameKeyboardIcon = (bool isShow) async {
      await Future.delayed(Duration.zero); //避免還在頁面初始化就刷新
      isShowGameKeyboard.value = isShow;
      if (isShow && gameManager.osFromCollection) {
        gameManager.onOpenGameKeyboard(isShowKeyboard: isShow);
        Get.find<HomeController>().onPageChange(0);
      }
    };
    //用以控制是否為群主或管理員
    PluginManager.shared.onSetGroupOwnerAdmin = (bool isAdmin) async {
      await Future.delayed(Duration.zero); //避免還在頁面初始化就刷新
      isGroupOwnerAdmin = isAdmin;
      if (!isShareholder) {
        isNormalUser.value = !isAdmin;
      }
    };
    //用以控制是否為股東
    imMiniAppManager.onSetGroupShareholder = (bool isShareholder) async {
      await Future.delayed(Duration.zero); //避免還在頁面初始化就刷新
      isShareholder = isShareholder;
      if (!isGroupOwnerAdmin) {
        isNormalUser.value = !isShareholder;
      }
    };
    //送出訊息
    gameManager.onSendChatText = (String? text) async {
      if (text != null && text != "") {
        onSend(text);
      }
    };
    //將訊息寫入輸入框
    gameManager.onSetChatText = (String? text) async {
      if (text != null) {
        inputController.text = text;
        await Future.delayed(const Duration(milliseconds: 100));
        scrollController.jumpTo(
          scrollController.position.maxScrollExtent,
        );
      }
    };
    gameManager.getCurrentInputText = () {
      return inputController.text;
    };
    //關閉表情面板
    gameManager.closeEmojiPanel = () {
      if (chatController.showFaceView.value) {
        onOpenFace();
        inputFocusNode.unfocus();
      }
    };
    //關閉快捷短語面板
    gameManager.closeShortcutPanel = () {
      if (isShowShortTalk.value) {
        onOpenShortTalk(assetPickerProvider);
        inputFocusNode.unfocus();
      }
    };
  }

  //檢查本地資料表是否為遊戲群
  checkIsGameGroup() async {
    GroupLocalBean? groupLocalBean = sharedDataManager.groupLocalData;
    if (groupLocalBean != null && groupLocalBean.defaultGameId != "") {
      await Future.delayed(Duration.zero); //避免還在頁面初始化就刷新
      if (type == 2) {
        isShowGameKeyboard.value = true;
      } else {
        isShowGameKeyboard.value = false;
      }
      final permission = chatController.permission;
      bool isGameGroupSendMsg = GameGroupPermissionMap.groupPermissionSendMsg
          .isAllow(permission.value);
      // debugPrint("TAG_TIF, permission: $permission, isGameGroupSendMsg: $isGameGroupSendMsg");
      if (isGameGroupSendMsg) {
        chatController.inputType.value = 8;
      }
    }
    if (groupLocalBean != null &&
        ((groupLocalBean.isAdmin ?? false) ||
            (groupLocalBean.isOwner ?? false) ||
            (groupLocalBean.isShareholder ?? false))) {
      //倘若是管理員或是群主或是股東
      isGroupOwnerAdmin = (groupLocalBean.isAdmin ?? false) ||
          (groupLocalBean.isOwner ?? false);
      isShareholder = groupLocalBean.isShareholder ?? false;
      await Future.delayed(Duration.zero); //避免還在頁面初始化就刷新
      isNormalUser.value = false;
    }
  }

  showMoreClick() {
    if (isShowShortTalk.value) {
      //如果有開啟快捷短語就關閉快捷短語
      onOpenShortTalk(assetPickerProvider);
      inputFocusNode.unfocus();
    }
    if (chatController.showFaceView.value) {
      //如果有開啟貼圖就關閉貼圖
      onOpenFace();
      inputFocusNode.unfocus();
    }
    if (isCurrentShowGamePanel.value) {
      //如果當前開啟遊戲鍵盤就先關閉遊戲鍵盤
      openGameKeyboard(false);
    }
    if (inputFocusNode.hasFocus) {
      //如果當前有彈起原生鍵盤就先關閉原生鍵盤
      inputFocusNode.unfocus();
    }
    //動畫開始
    inputAnimateController.forward();
    clickMenuKeyboard.value = -1;
    chatController.showAttachmentView.value = false;
  }
}
