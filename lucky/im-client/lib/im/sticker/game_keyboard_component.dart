
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:im/im_plugin.dart';
import 'package:jxim_client/im/base/base_chat_controller.dart';
import 'package:jxim_client/im/chat_bottom/chat_bottom_widget.dart';
import 'package:jxim_client/im/custom_input/custom_input_controller.dart';
import 'package:jxim_client/im/group_chat/group_chat_controller.dart';
import 'package:jxim_client/main.dart';
import 'package:jxim_client/object/chat/chat.dart';

class GameKeyboardComponent extends StatefulWidget {
  final Chat chat;
  final bool isFocus;
  final bool isShowGameKeyboard;   //是否是顯示遊戲鍵盤
  final bool isShowShortTalk;   //是否是顯示快捷短語
  final bool isShowSticker;    //是否是顯示貼圖
  final dynamic tag;

  const GameKeyboardComponent({
    super.key,
    required this.chat,
    required this.isFocus,
    required this.tag,
    this.isShowGameKeyboard = false,
    this.isShowShortTalk = false,
    this.isShowSticker = false,
  });

  @override
  State<GameKeyboardComponent> createState() => _GameKeyboardComponentState();
}

class _GameKeyboardComponentState extends State<GameKeyboardComponent>
    with SingleTickerProviderStateMixin {
  CustomInputController? controller;

  bool isSwitchingBetweenStickerAndKeyboard = false;
  int animateTime = 233;

  @override
  void initState() {
    super.initState();
    controller =
        Get.find<CustomInputController>(tag: widget.chat.id.toString());
    GameManager.shared.onShowBetPanel = (KeyboardInteractionType type) async {
      await Future.delayed(Duration.zero); //避免還在頁面初始化就刷新
      if (type != KeyboardInteractionType.gameKeyboard) {
        if (Get.isRegistered<GroupChatController>(tag: widget.tag)) {
          Get.find<GroupChatController>(tag: widget.tag).isShowGameKeyboard.value = false;
        }
        controller?.isCurrentShowGamePanel.value = false;
      }
      groupBottomWidgetProvider.isShowBetPanel =
      (type == KeyboardInteractionType.gameKeyboard);
    };
  }

  @override
  void didUpdateWidget(GameKeyboardComponent oldWidget) {
    super.didUpdateWidget(oldWidget);

    animateTime = 233;
    if (widget.isShowShortTalk != oldWidget.isShowShortTalk ||
        widget.isShowSticker != oldWidget.isShowSticker) {
      animateTime = 0;
    }
    controller?.checkLastGameKeyBoardState(widget.isShowGameKeyboard);
    if (widget.isShowGameKeyboard != oldWidget.isShowGameKeyboard ||
        widget.isFocus != oldWidget.isFocus) {
      if (widget.isFocus &&
          !oldWidget.isFocus &&
          oldWidget.isShowGameKeyboard &&
          !widget.isShowGameKeyboard) {
        isSwitchingBetweenStickerAndKeyboard = true;
        controller?.stickerDebounce.call(() {
          isSwitchingBetweenStickerAndKeyboard = false;
        });
      } else {
        isSwitchingBetweenStickerAndKeyboard = false;
        /// 点击空白区域，键盘收起，去掉内容框中的投注项，跟投的不能清除掉
        /// 弹起和收起都会走这里
        if(!widget.isFocus && controller!.isLastShowGamePanel){
          controller?.clearText();
        }
        controller?.isLastShowGamePanel=widget.isShowGameKeyboard;
      }

      if (mounted) setState(() {});
    }

    ever(keyboardHeight, (callback) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInsetHeight = MediaQuery.of(context).viewInsets.bottom;

    double bottomHeight = 272.0.h;
    if (widget.isFocus && bottomInsetHeight < keyboardHeight.value) {
      if (isSwitchingBetweenStickerAndKeyboard) {
        bottomHeight = keyboardHeight.value;
      } else {
        bottomHeight = bottomInsetHeight;
      }
    } else if (bottomInsetHeight > keyboardHeight.value) {
      bottomHeight = bottomInsetHeight;
    } else {
     bool isShowSticker = widget.isShowSticker;
      bool isShowShortTalk = widget.isShowSticker;
     if(isShowSticker|| isShowShortTalk){
       bottomHeight = keyboardHeight.value;
     }else{
       bottomHeight =272.w;
     }
    }
    if(objectMgr.loginMgr.isDesktop)return const SizedBox();

    return GetBuilder<CustomInputController>(
        id: 'game_keyboard_tab',
        init: controller,
        builder: (_) {
          return ClipRRect(
            child: AnimatedAlign(
              alignment: Alignment.bottomCenter,
              duration: Duration(
                milliseconds:
                widget.isShowGameKeyboard || widget.isFocus ? animateTime : 180,
              ),
              curve: Curves.easeOut,
              heightFactor: widget.isShowGameKeyboard || widget.isFocus ? 1.0 : 0.0,
              child: Stack(
                children: <Widget>[
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    height: widget.isShowGameKeyboard //&& bottomHeight < 200
                        ? null
                        : bottomHeight,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(243, 243, 243, 1),
                    ),
                    child: !widget.isShowGameKeyboard
                        ? null
                        : SafeArea(
                      top: false,
                      child: ChatBottomWidget(tag: widget.tag,),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}